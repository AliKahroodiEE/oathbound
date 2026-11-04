-- =============================================================================
-- Wyrd · core schema
--
-- Personal data: profiles, characters, quests, subtasks, completions,
-- evaluations, the append-only XP ledger, achievements, per-day rollups,
-- snapshots and chronicles. See docs/architecture/overview.md §3.
--
-- Conventions
--   * Every user-owned row references auth.users(id) ON DELETE CASCADE.
--   * Timestamps are timestamptz (UTC); `local_day` is a date in the user's
--     IANA time zone (profiles.time_zone), computed server-side.
--   * Tables pulled by clients carry `change_id` (monotonic, from
--     public.sync_change_seq) and `updated_at`, both maintained by the
--     `private.touch_sync_columns` trigger. Soft deletes use `deleted_at`.
--   * Quests and subtasks carry `hlc` (latest client hybrid logical clock)
--     and `field_hlc` (per-field HLC) for field-level last-writer-wins.
--   * RLS is enabled in a later migration (…_rls.sql); nothing here is
--     reachable by clients until then.
-- =============================================================================

-- Internal helpers live in a schema PostgREST does not expose.
create schema if not exists private;
revoke all on schema private from public;

-- ---------------------------------------------------------------------------
-- Enumerations (stable vocabularies shared with the engine)
-- ---------------------------------------------------------------------------

create type public.attribute as enum (
  'strength', 'intelligence', 'discipline', 'creativity', 'vitality', 'social'
);

create type public.quest_tier as enum ('daily', 'contract', 'objective');

create type public.quest_category as enum (
  'study', 'work', 'fitness', 'health', 'creative', 'social',
  'chores', 'admin', 'mindfulness', 'reading', 'other'
);

-- Sharing levels (requirements §4.6), most to least revealing.
create type public.share_level as enum ('full', 'title_only', 'completion_only', 'private');

-- ---------------------------------------------------------------------------
-- Sync bookkeeping
-- ---------------------------------------------------------------------------

-- One global sequence; per-owner ordering is made commit-consistent by the
-- advisory lock taken in private.touch_sync_columns (see below).
create sequence public.sync_change_seq as bigint;

-- BEFORE INSERT OR UPDATE trigger for pulled tables. TG_ARGV[0] names the
-- owner column.
--
-- Why the advisory lock: change_id values are allocated when a row is
-- written, but become visible at commit. Without serialisation, transaction
-- A could take change_id 10, transaction B 11, B commits, a client pulls and
-- advances its cursor to 11, then A commits and row 10 is never pulled.
-- Holding a transaction-scoped lock per owner from the first write until
-- commit makes one owner's change_ids commit in allocation order, so a
-- cursor never skips a row. Different owners never contend.
create or replace function private.touch_sync_columns()
returns trigger
language plpgsql
security definer  -- clients need no privileges on the sequence
set search_path = ''
as $$
declare
  v_owner text := to_jsonb(new) ->> tg_argv[0];
begin
  if v_owner is not null then
    perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('sync:' || v_owner, 0));
  end if;
  new.change_id := pg_catalog.nextval('public.sync_change_seq');
  new.updated_at := pg_catalog.now();
  return new;
end;
$$;

-- updated_at only (shared tables that are not cursor-pulled).
create or replace function private.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := pg_catalog.now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Generic JSON helpers
-- ---------------------------------------------------------------------------

-- Adds two {key: number} maps key-wise. With p_drop_zero, keys whose sum is
-- 0 are removed (used for similarity counts after an undo).
create or replace function private.jsonb_add_counts(
  p_a jsonb,
  p_b jsonb,
  p_drop_zero boolean default true
)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select coalesce(pg_catalog.jsonb_object_agg(k, pg_catalog.to_jsonb(v) order by k), '{}'::jsonb)
  from (
    select s.k, sum(s.v)::bigint as v
    from (
      select a.key as k, a.value::numeric as v from pg_catalog.jsonb_each_text(coalesce(p_a, '{}'::jsonb)) a
      union all
      select b.key, b.value::numeric from pg_catalog.jsonb_each_text(coalesce(p_b, '{}'::jsonb)) b
    ) s
    group by s.k
  ) t
  where not p_drop_zero or t.v <> 0;
$$;

-- Multiplies every value of a {key: number} map by p_factor (e.g. -1).
create or replace function private.jsonb_scale_counts(p_map jsonb, p_factor integer)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select coalesce(
    pg_catalog.jsonb_object_agg(e.key, pg_catalog.to_jsonb(e.value::numeric * p_factor) order by e.key),
    '{}'::jsonb
  )
  from pg_catalog.jsonb_each_text(coalesce(p_map, '{}'::jsonb)) e;
$$;

-- All six attributes at zero, so caches always carry every key.
create or replace function private.zero_attributes()
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select '{"strength":0,"intelligence":0,"discipline":0,"creativity":0,"vitality":0,"social":0}'::jsonb;
$$;

-- True when p_tz names a time zone the server knows.
create or replace function private.is_valid_time_zone(p_tz text)
returns boolean
language plpgsql
stable
set search_path = ''
as $$
begin
  perform pg_catalog.timezone(p_tz, pg_catalog.now());
  return true;
exception
  when others then
    return false;
end;
$$;


-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  handle text,
  display_name text not null default '',
  locale text not null default 'en',
  -- Language for AI explanations/chronicles; null means "same as locale".
  ai_locale text,
  region text,
  calendar text not null default 'gregorian',
  time_zone text not null default 'UTC',
  -- ISO day of week (1 = Monday … 7 = Sunday); null = region default.
  week_start smallint,
  weekly_target smallint not null default 4,
  motivation jsonb not null default '{}'::jsonb,
  -- AI usage controls (requirements §4.10). Off = deterministic heuristic only.
  ai_evaluation_enabled boolean not null default true,
  ai_chronicles_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  change_id bigint not null default 0,
  constraint profiles_handle_format check (handle is null or handle ~ '^[a-z0-9_]{3,24}$'),
  constraint profiles_display_name_length check (char_length(display_name) <= 48),
  constraint profiles_locale_format check (locale ~ '^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$'),
  constraint profiles_ai_locale_format check (
    ai_locale is null or ai_locale ~ '^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$'
  ),
  constraint profiles_region_format check (region is null or region ~ '^[A-Z]{2}$|^[0-9]{3}$'),
  constraint profiles_calendar check (calendar in ('gregorian', 'jalali')),
  constraint profiles_week_start check (week_start between 1 and 7),
  constraint profiles_weekly_target check (weekly_target between 1 and 7),
  constraint profiles_motivation_object check (jsonb_typeof(motivation) = 'object')
);

create unique index profiles_handle_key on public.profiles (handle) where handle is not null;
create index profiles_change_idx on public.profiles (id, change_id);

create or replace function private.profiles_validate()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.is_valid_time_zone(new.time_zone) then
    raise exception 'unknown time zone: %', new.time_zone using errcode = '22023';
  end if;
  return new;
end;
$$;

create trigger profiles_validate
  before insert or update of time_zone on public.profiles
  for each row execute function private.profiles_validate();

create trigger profiles_sync
  before insert or update on public.profiles
  for each row execute function private.touch_sync_columns('id');

-- Today's date in a user's time zone (UTC if unknown).
create or replace function private.user_today(p_user_id uuid)
returns date
language sql
stable
security definer
set search_path = ''
as $$
  select (pg_catalog.now() at time zone coalesce(
    (select p.time_zone from public.profiles p where p.id = p_user_id), 'UTC'))::date;
$$;

-- ---------------------------------------------------------------------------
-- characters (cache; rebuildable from ledger_entries)
-- ---------------------------------------------------------------------------

create table public.characters (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references auth.users (id) on delete cascade,
  name text not null default '',
  portrait text,
  equipped_title text,
  class_id text,
  attr_xp jsonb not null
    default '{"strength":0,"intelligence":0,"discipline":0,"creativity":0,"vitality":0,"social":0}'::jsonb,
  total_xp bigint not null default 0,
  level integer not null default 1,
  condition smallint not null default 100,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  change_id bigint not null default 0,
  constraint characters_name_length check (char_length(name) <= 40),
  constraint characters_portrait_length check (portrait is null or char_length(portrait) <= 200),
  constraint characters_class check (class_id is null or class_id in (
    'scholar', 'warden', 'artisan', 'vanguard', 'envoy', 'druid',
    'explorer', 'strategist', 'arcanist'
  )),
  constraint characters_attr_xp_object check (jsonb_typeof(attr_xp) = 'object'),
  constraint characters_total_xp check (total_xp >= 0),
  constraint characters_level check (level >= 1),
  constraint characters_condition check (condition between 25 and 100)
);

create index characters_change_idx on public.characters (owner_id, change_id);

create trigger characters_sync
  before insert or update on public.characters
  for each row execute function private.touch_sync_columns('owner_id');

-- Create the profile and character as soon as an account exists.
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_locale text := v_meta ->> 'locale';
  v_tz text := v_meta ->> 'time_zone';
begin
  if v_locale is null or v_locale !~ '^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$' then
    v_locale := 'en';
  end if;
  if v_tz is null or not private.is_valid_time_zone(v_tz) then
    v_tz := 'UTC';
  end if;
  insert into public.profiles (id, display_name, locale, time_zone)
  values (new.id, left(coalesce(v_meta ->> 'display_name', ''), 48), v_locale, v_tz)
  on conflict (id) do nothing;
  insert into public.characters (owner_id, name)
  values (new.id, left(coalesce(v_meta ->> 'character_name', ''), 40))
  on conflict (owner_id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- ---------------------------------------------------------------------------
-- quests (daily quests, contracts, objectives)
-- ---------------------------------------------------------------------------

create table public.quests (
  id uuid primary key,                       -- client-generated
  owner_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  parent_id uuid references public.quests (id) on delete cascade,
  tier public.quest_tier not null default 'daily',
  title text not null,
  notes text,
  category public.quest_category,            -- null: let the evaluator decide
  priority smallint not null default 0,
  status text not null default 'active',
  due_at timestamptz,
  estimated_minutes integer,
  recurrence jsonb,
  intention text,                            -- implementation intention ("when/where")
  share_level public.share_level,            -- null: member's per-guild default
  reminder_at timestamptz,
  created_at timestamptz not null default now(),   -- client creation time (clamped)
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  hlc text not null default '',
  field_hlc jsonb not null default '{}'::jsonb,
  change_id bigint not null default 0,
  constraint quests_title_length check (char_length(title) between 1 and 200),
  constraint quests_notes_length check (notes is null or char_length(notes) <= 4000),
  constraint quests_priority check (priority between 0 and 3),
  constraint quests_status check (status in ('active', 'completed', 'paused', 'archived')),
  constraint quests_estimated_minutes check (estimated_minutes between 1 and 1440),
  constraint quests_recurrence_object check (recurrence is null or jsonb_typeof(recurrence) = 'object'),
  constraint quests_intention_length check (intention is null or char_length(intention) <= 280),
  constraint quests_not_own_parent check (parent_id is null or parent_id <> id),
  constraint quests_field_hlc_object check (jsonb_typeof(field_hlc) = 'object')
);

create index quests_change_idx on public.quests (owner_id, change_id);
create index quests_parent_idx on public.quests (parent_id) where parent_id is not null;
create index quests_owner_active_idx on public.quests (owner_id, status) where deleted_at is null;

-- Ownership invariants that RLS alone cannot express.
create or replace function private.quests_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and new.owner_id is distinct from old.owner_id then
    raise exception 'quest owner cannot change' using errcode = '42501';
  end if;
  if new.created_at > pg_catalog.now() then
    new.created_at := pg_catalog.now();
  end if;
  if new.parent_id is not null and (tg_op = 'INSERT' or new.parent_id is distinct from old.parent_id) then
    if not exists (
      select 1 from public.quests p where p.id = new.parent_id and p.owner_id = new.owner_id
    ) then
      raise exception 'parent quest % not found', new.parent_id using errcode = '23503';
    end if;
  end if;
  return new;
end;
$$;

create trigger quests_guard
  before insert or update on public.quests
  for each row execute function private.quests_guard();

create trigger quests_sync
  before insert or update on public.quests
  for each row execute function private.touch_sync_columns('owner_id');

-- ---------------------------------------------------------------------------
-- subtasks
-- ---------------------------------------------------------------------------

create table public.subtasks (
  id uuid primary key,                       -- client-generated
  quest_id uuid not null references public.quests (id) on delete cascade,
  owner_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  title text not null,
  done boolean not null default false,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  hlc text not null default '',
  field_hlc jsonb not null default '{}'::jsonb,
  change_id bigint not null default 0,
  constraint subtasks_title_length check (char_length(title) between 1 and 200),
  constraint subtasks_field_hlc_object check (jsonb_typeof(field_hlc) = 'object')
);

create index subtasks_change_idx on public.subtasks (owner_id, change_id);
create index subtasks_quest_idx on public.subtasks (quest_id);

create or replace function private.subtasks_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and new.owner_id is distinct from old.owner_id then
    raise exception 'subtask owner cannot change' using errcode = '42501';
  end if;
  if new.created_at > pg_catalog.now() then
    new.created_at := pg_catalog.now();
  end if;
  if tg_op = 'INSERT' or new.quest_id is distinct from old.quest_id then
    if not exists (
      select 1 from public.quests q where q.id = new.quest_id and q.owner_id = new.owner_id
    ) then
      raise exception 'quest % not found', new.quest_id using errcode = '23503';
    end if;
  end if;
  return new;
end;
$$;

create trigger subtasks_guard
  before insert or update on public.subtasks
  for each row execute function private.subtasks_guard();

create trigger subtasks_sync
  before insert or update on public.subtasks
  for each row execute function private.touch_sync_columns('owner_id');

-- ---------------------------------------------------------------------------
-- completions (append-only facts; client UUID is the idempotency key)
-- ---------------------------------------------------------------------------

create table public.completions (
  id uuid primary key,                       -- client-generated
  quest_id uuid not null references public.quests (id) on delete cascade,
  owner_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  occurrence_day date,                       -- recurring occurrence window key (FR-5)
  completed_at timestamptz not null,
  declared_minutes integer,
  tracked_minutes integer,
  local_day date not null,                   -- recomputed server-side from profiles.time_zone
  state text not null default 'active',      -- active | undone
  undone_at timestamptz,
  -- Server-side evaluation outcome (written only by apply_progression / undo).
  evaluation_status text not null default 'pending',
  evaluated_at timestamptz,
  result jsonb,                              -- authoritative RewardResult JSON
  category public.quest_category,
  similarity_key text,
  effective_minutes integer,
  trivial boolean,
  total_xp integer,
  hlc text not null default '',
  created_at timestamptz not null default now(),   -- server receipt time
  updated_at timestamptz not null default now(),
  change_id bigint not null default 0,
  constraint completions_declared_minutes check (declared_minutes between 0 and 1440),
  constraint completions_tracked_minutes check (tracked_minutes between 0 and 1440),
  constraint completions_state check (state in ('active', 'undone')),
  constraint completions_evaluation_status check (evaluation_status in ('pending', 'evaluated'))
);

-- FR-5: one active completion per recurring occurrence.
create unique index completions_one_per_occurrence
  on public.completions (quest_id, occurrence_day)
  where occurrence_day is not null and state = 'active';
create index completions_change_idx on public.completions (owner_id, change_id);
create index completions_owner_day_idx on public.completions (owner_id, local_day);
create index completions_owner_completed_idx on public.completions (owner_id, completed_at desc);
create index completions_quest_idx on public.completions (quest_id);
create index completions_pending_idx on public.completions (owner_id)
  where evaluation_status = 'pending' and state = 'active';

-- Normalises client input on insert and freezes the facts afterwards.
create or replace function private.completions_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tz text;
begin
  if tg_op = 'INSERT' then
    if not exists (
      select 1 from public.quests q where q.id = new.quest_id and q.owner_id = new.owner_id
    ) then
      raise exception 'quest % not found', new.quest_id using errcode = '23503';
    end if;
    -- Clock skew: never in the future. Very old completions are rejected so
    -- that backdating cannot be used to spread XP across past days.
    if new.completed_at > pg_catalog.now() then
      new.completed_at := pg_catalog.now();
    end if;
    if new.completed_at < pg_catalog.now() - interval '30 days' then
      raise exception 'completion is older than 30 days' using errcode = '22023';
    end if;
    select p.time_zone into v_tz from public.profiles p where p.id = new.owner_id;
    new.local_day := (new.completed_at at time zone coalesce(v_tz, 'UTC'))::date;
    new.state := 'active';
    new.undone_at := null;
    new.evaluation_status := 'pending';
    new.evaluated_at := null;
    new.result := null;
    new.category := null;
    new.similarity_key := null;
    new.effective_minutes := null;
    new.trivial := null;
    new.total_xp := null;
    new.created_at := pg_catalog.now();
  elsif (new.quest_id, new.owner_id, new.occurrence_day, new.completed_at,
         new.declared_minutes, new.tracked_minutes, new.local_day, new.created_at)
        is distinct from
        (old.quest_id, old.owner_id, old.occurrence_day, old.completed_at,
         old.declared_minutes, old.tracked_minutes, old.local_day, old.created_at) then
    raise exception 'completion facts are immutable' using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger completions_guard
  before insert or update on public.completions
  for each row execute function private.completions_guard();

create trigger completions_sync
  before insert or update on public.completions
  for each row execute function private.touch_sync_columns('owner_id');

-- ---------------------------------------------------------------------------
-- evaluations (AI or heuristic proposals; also the 7-day proposal cache)
-- ---------------------------------------------------------------------------

create table public.evaluations (
  id uuid primary key default gen_random_uuid(),
  completion_id uuid references public.completions (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  source text not null,
  model text,
  proposal jsonb not null,
  -- SHA-256 of the normalised evaluator inputs (cache key, rules §8.2).
  input_hash text,
  latency_ms integer,
  -- Why the heuristic was used instead of AI (null for AI proposals).
  fallback_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  change_id bigint not null default 0,
  constraint evaluations_source check (source in ('ai', 'heuristic')),
  constraint evaluations_proposal_object check (jsonb_typeof(proposal) = 'object'),
  constraint evaluations_input_hash_format check (input_hash is null or input_hash ~ '^[0-9a-f]{64}$')
);

create index evaluations_completion_idx on public.evaluations (completion_id);
create index evaluations_change_idx on public.evaluations (owner_id, change_id);
create index evaluations_cache_idx on public.evaluations (owner_id, input_hash, created_at desc)
  where source = 'ai' and input_hash is not null;

create trigger evaluations_sync
  before insert or update on public.evaluations
  for each row execute function private.touch_sync_columns('owner_id');

-- ---------------------------------------------------------------------------
-- ledger_entries (append-only attribute grants and reversals; FR-2, FR-4)
-- ---------------------------------------------------------------------------

create table public.ledger_entries (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  completion_id uuid references public.completions (id) on delete cascade,
  attribute public.attribute not null,
  amount integer not null,                   -- credited after caps (negative for reversals)
  raw_amount integer not null,               -- before caps (feeds per-day cap accounting)
  kind text not null default 'grant',
  -- provisional: offline client result; superseded: replaced by the server
  -- result for the same completion (rules §11). Only confirmed rows count.
  status text not null default 'confirmed',
  rule_version text not null,
  adjustments jsonb not null default '[]'::jsonb,
  source text,
  model text,
  similarity_key text,
  reverses_id uuid references public.ledger_entries (id) on delete cascade,
  local_day date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  change_id bigint not null default 0,
  constraint ledger_kind check (kind in ('grant', 'reversal', 'correction', 'migration')),
  constraint ledger_status check (status in ('confirmed', 'provisional', 'superseded')),
  constraint ledger_source check (source is null or source in ('ai', 'heuristic', 'system')),
  constraint ledger_adjustments_array check (jsonb_typeof(adjustments) = 'array'),
  constraint ledger_grant_shape check (
    kind <> 'grant' or (amount >= 0 and raw_amount >= 0 and completion_id is not null)
  ),
  constraint ledger_reversal_shape check (
    kind <> 'reversal' or (amount <= 0 and raw_amount <= 0 and reverses_id is not null)
  ),
  constraint ledger_provisional_grants_only check (status = 'confirmed' or kind = 'grant')
);

-- Idempotency backstops for apply_progression and undo.
create unique index ledger_one_confirmed_grant
  on public.ledger_entries (completion_id, attribute)
  where kind = 'grant' and status = 'confirmed';
create unique index ledger_one_reversal
  on public.ledger_entries (reverses_id)
  where kind = 'reversal';
create index ledger_change_idx on public.ledger_entries (owner_id, change_id);
create index ledger_owner_day_idx on public.ledger_entries (owner_id, local_day);
create index ledger_completion_idx on public.ledger_entries (completion_id);

-- The ledger is append-only: only the provisional → superseded transition
-- is allowed after insert.
create or replace function private.ledger_guard()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (new.id, new.owner_id, new.completion_id, new.attribute, new.amount, new.raw_amount,
      new.kind, new.rule_version, new.adjustments, new.source, new.model,
      new.similarity_key, new.reverses_id, new.local_day, new.created_at)
     is distinct from
     (old.id, old.owner_id, old.completion_id, old.attribute, old.amount, old.raw_amount,
      old.kind, old.rule_version, old.adjustments, old.source, old.model,
      old.similarity_key, old.reverses_id, old.local_day, old.created_at) then
    raise exception 'ledger entries are append-only' using errcode = '42501';
  end if;
  if new.status is distinct from old.status
     and not (old.status = 'provisional' and new.status = 'superseded') then
    raise exception 'invalid ledger status transition % -> %', old.status, new.status
      using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger ledger_guard
  before update on public.ledger_entries
  for each row execute function private.ledger_guard();

create trigger ledger_sync
  before insert or update on public.ledger_entries
  for each row execute function private.touch_sync_columns('owner_id');

-- ---------------------------------------------------------------------------
-- achievements
-- ---------------------------------------------------------------------------

create table public.achievements (
  owner_id uuid not null references auth.users (id) on delete cascade,
  achievement_id text not null,
  title_id text,
  completion_id uuid references public.completions (id) on delete set null,
  unlocked_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  change_id bigint not null default 0,
  primary key (owner_id, achievement_id),
  constraint achievements_id_format check (achievement_id ~ '^[a-z0-9_]{2,48}$'),
  constraint achievements_title_format check (title_id is null or title_id ~ '^[a-z0-9_]{2,48}$')
);

create index achievements_change_idx on public.achievements (owner_id, change_id);

create trigger achievements_sync
  before insert or update on public.achievements
  for each row execute function private.touch_sync_columns('owner_id');

-- ---------------------------------------------------------------------------
-- day_stats (per-day rollup: engine day state, analytics, condition)
-- ---------------------------------------------------------------------------

create table public.day_stats (
  owner_id uuid not null references auth.users (id) on delete cascade,
  local_day date not null,
  minutes integer not null default 0,        -- credited (effective) minutes
  xp jsonb not null default '{}'::jsonb,     -- credited XP per attribute
  raw_xp jsonb not null default '{}'::jsonb, -- pre-cap XP per attribute (engine input)
  similarity_counts jsonb not null default '{}'::jsonb,
  completions integer not null default 0,
  nontrivial_completions integer not null default 0,  -- > 0 marks an active day (§7.1)
  trivial_count integer not null default 0,
  total_xp integer not null default 0,
  rest_day boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  change_id bigint not null default 0,
  primary key (owner_id, local_day),
  constraint day_stats_minutes check (minutes >= 0),
  constraint day_stats_counts check (completions >= 0 and nontrivial_completions >= 0 and trivial_count >= 0),
  constraint day_stats_maps check (
    jsonb_typeof(xp) = 'object' and jsonb_typeof(raw_xp) = 'object'
    and jsonb_typeof(similarity_counts) = 'object'
  )
);

create index day_stats_change_idx on public.day_stats (owner_id, change_id);

create trigger day_stats_sync
  before insert or update on public.day_stats
  for each row execute function private.touch_sync_columns('owner_id');

-- ---------------------------------------------------------------------------
-- snapshots (monthly character snapshots)
-- ---------------------------------------------------------------------------

create table public.snapshots (
  owner_id uuid not null references auth.users (id) on delete cascade,
  taken_on date not null,
  data jsonb not null,
  created_at timestamptz not null default now(),
  primary key (owner_id, taken_on),
  constraint snapshots_data_object check (jsonb_typeof(data) = 'object')
);

-- ---------------------------------------------------------------------------
-- chronicles (AI or templated narratives grounded in stored facts)
-- ---------------------------------------------------------------------------

create table public.chronicles (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  period text not null,
  period_start date not null,
  period_end date not null,                  -- exclusive
  locale text not null default 'en',
  status text not null default 'pending',
  body text,
  facts jsonb,
  model text,
  source text,
  attempts smallint not null default 0,
  error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  change_id bigint not null default 0,
  unique (owner_id, period, period_start),
  constraint chronicles_period check (period in ('week', 'month', 'year')),
  constraint chronicles_range check (period_end > period_start),
  constraint chronicles_status check (status in ('pending', 'ready', 'failed')),
  constraint chronicles_source check (source is null or source in ('ai', 'template')),
  constraint chronicles_ready_has_body check (status <> 'ready' or body is not null)
);

create index chronicles_change_idx on public.chronicles (owner_id, change_id);
create index chronicles_pending_idx on public.chronicles (created_at) where status = 'pending';

create trigger chronicles_sync
  before insert or update on public.chronicles
  for each row execute function private.touch_sync_columns('owner_id');

-- ---------------------------------------------------------------------------
-- ai_usage (per-user daily AI call counters; evaluate-completion ≤ 120/day)
-- ---------------------------------------------------------------------------

create table public.ai_usage (
  owner_id uuid not null references auth.users (id) on delete cascade,
  usage_day date not null,                   -- UTC day
  route text not null,
  calls integer not null default 0,
  primary key (owner_id, usage_day, route),
  constraint ai_usage_route check (route in ('evaluation', 'chronicle'))
);
