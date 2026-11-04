-- =============================================================================
-- Oathbound · row-level security
--
-- RLS is enabled on EVERY table in `public`. Principles (overview §6):
--   * Owners read their own rows; owners write only quests, subtasks,
--     completions (insert-only), profile settings, notification settings and
--     push tokens.
--   * characters, ledger_entries, day_stats, evaluations, achievements,
--     feed_events, challenge_contributions, snapshots and chronicles are
--     written only by SECURITY DEFINER functions or the service role.
--   * Guild data is readable by members; public guild metadata by any
--     signed-in user.
--   * Content from users the viewer has blocked is invisible to the viewer
--     (FR-7). Blocking is invisible to the blocked party.
--   * anon has no table access at all.
--
-- Note for future migrations: Supabase's default privileges grant new
-- tables to anon/authenticated again. Every new table must enable RLS and
-- repeat the relevant revokes below.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Helper predicates (SECURITY DEFINER so they can read membership/blocks
-- without recursing into the policies that call them).
-- ---------------------------------------------------------------------------

create or replace function public.is_guild_member(p_guild_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.guild_members m
    where m.guild_id = p_guild_id and m.user_id = (select auth.uid())
  );
$$;

create or replace function public.guild_role_of(p_guild_id uuid)
returns public.guild_role
language sql
stable
security definer
set search_path = ''
as $$
  select m.role from public.guild_members m
  where m.guild_id = p_guild_id and m.user_id = (select auth.uid());
$$;

create or replace function public.is_guild_officer(p_guild_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(public.guild_role_of(p_guild_id) in ('guild_master', 'officer'), false);
$$;

-- True when the current user has blocked p_user_id.
create or replace function public.is_blocked_by_me(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_user_id is not null and exists (
    select 1 from public.blocks b
    where b.blocker_id = (select auth.uid()) and b.blocked_id = p_user_id
  );
$$;

revoke execute on function public.is_guild_member(uuid) from public, anon;
revoke execute on function public.guild_role_of(uuid) from public, anon;
revoke execute on function public.is_guild_officer(uuid) from public, anon;
revoke execute on function public.is_blocked_by_me(uuid) from public, anon;
grant execute on function public.is_guild_member(uuid) to authenticated, service_role;
grant execute on function public.guild_role_of(uuid) to authenticated, service_role;
grant execute on function public.is_guild_officer(uuid) to authenticated, service_role;
grant execute on function public.is_blocked_by_me(uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Enable RLS everywhere
-- ---------------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.characters enable row level security;
alter table public.quests enable row level security;
alter table public.subtasks enable row level security;
alter table public.completions enable row level security;
alter table public.evaluations enable row level security;
alter table public.ledger_entries enable row level security;
alter table public.achievements enable row level security;
alter table public.day_stats enable row level security;
alter table public.snapshots enable row level security;
alter table public.chronicles enable row level security;
alter table public.ai_usage enable row level security;
alter table public.guilds enable row level security;
alter table public.guild_members enable row level security;
alter table public.guild_invites enable row level security;
alter table public.feed_events enable row level security;
alter table public.reactions enable row level security;
alter table public.comments enable row level security;
alter table public.challenges enable row level security;
alter table public.challenge_contributions enable row level security;
alter table public.blocks enable row level security;
alter table public.reports enable row level security;
alter table public.notification_prefs enable row level security;
alter table public.push_tokens enable row level security;
alter table public.notification_deliveries enable row level security;

-- Fail the migration if any public table was missed.
do $$
declare
  v_missing text;
begin
  select string_agg(c.relname, ', ') into v_missing
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity;
  if v_missing is not null then
    raise exception 'RLS is not enabled on: %', v_missing;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Table privileges (defence in depth on top of RLS)
-- ---------------------------------------------------------------------------

revoke all on all tables in schema public from anon;
revoke all on sequence public.sync_change_seq from anon, authenticated;

-- Server-written tables: read-only for clients.
revoke insert, update, delete, truncate on
  public.characters, public.evaluations, public.ledger_entries, public.achievements,
  public.day_stats, public.snapshots, public.chronicles,
  public.feed_events, public.reactions, public.comments, public.challenges,
  public.challenge_contributions, public.blocks, public.reports, public.guild_invites
from authenticated;

-- Never visible to clients.
revoke all on public.ai_usage, public.notification_deliveries from authenticated;

-- Owner-written tables: no hard deletes (tombstones / RPCs instead).
revoke delete, truncate on
  public.profiles, public.quests, public.subtasks, public.completions,
  public.guilds, public.guild_members, public.notification_prefs
from authenticated;
revoke truncate on public.push_tokens from authenticated;

-- Completions are insert-only for clients (undo goes through undo_completion).
revoke update on public.completions from authenticated;
revoke insert on public.profiles, public.guilds, public.guild_members from authenticated;

-- Column-level update grants: server-maintained columns stay read-only.
revoke update on public.profiles from authenticated;
grant update (
  handle, display_name, locale, ai_locale, region, calendar, time_zone,
  week_start, weekly_target, motivation, ai_evaluation_enabled, ai_chronicles_enabled
) on public.profiles to authenticated;

revoke update on public.quests from authenticated;
grant update (
  parent_id, tier, title, notes, category, priority, status, due_at, estimated_minutes,
  recurrence, intention, share_level, reminder_at, deleted_at, hlc, field_hlc
) on public.quests to authenticated;

revoke update on public.subtasks from authenticated;
grant update (title, done, position, deleted_at, hlc, field_hlc) on public.subtasks to authenticated;

revoke update on public.guilds from authenticated;
grant update (
  name, description, emblem, language_tag, rules, slow_mode_seconds, default_share_level
) on public.guilds to authenticated;

-- Co-members see who is in the guild and their role, not each other's
-- sharing / mute preferences (read your own with public.my_guilds()).
revoke select, update on public.guild_members from authenticated;
grant select (guild_id, user_id, role, joined_at) on public.guild_members to authenticated;
grant update (share_level, contribute_private, muted) on public.guild_members to authenticated;

revoke update on public.notification_prefs from authenticated;
grant update (categories, quiet_hours_start, quiet_hours_end, daily_cap)
  on public.notification_prefs to authenticated;

revoke update on public.push_tokens from authenticated;
grant update (last_seen_at, platform) on public.push_tokens to authenticated;

-- Private helpers are reachable only from definer functions and triggers.
revoke execute on all functions in schema private from public;
alter default privileges in schema private revoke execute on functions from public;

-- ---------------------------------------------------------------------------
-- Personal data: owner policies
-- ---------------------------------------------------------------------------

create policy profiles_select_own on public.profiles
  for select to authenticated using (id = (select auth.uid()));
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy characters_select_own on public.characters
  for select to authenticated using (owner_id = (select auth.uid()));

create policy quests_select_own on public.quests
  for select to authenticated using (owner_id = (select auth.uid()));
create policy quests_insert_own on public.quests
  for insert to authenticated with check (owner_id = (select auth.uid()));
create policy quests_update_own on public.quests
  for update to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));

create policy subtasks_select_own on public.subtasks
  for select to authenticated using (owner_id = (select auth.uid()));
create policy subtasks_insert_own on public.subtasks
  for insert to authenticated with check (owner_id = (select auth.uid()));
create policy subtasks_update_own on public.subtasks
  for update to authenticated
  using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));

create policy completions_select_own on public.completions
  for select to authenticated using (owner_id = (select auth.uid()));
create policy completions_insert_own on public.completions
  for insert to authenticated with check (owner_id = (select auth.uid()));

create policy evaluations_select_own on public.evaluations
  for select to authenticated using (owner_id = (select auth.uid()));

create policy ledger_entries_select_own on public.ledger_entries
  for select to authenticated using (owner_id = (select auth.uid()));

create policy achievements_select_own on public.achievements
  for select to authenticated using (owner_id = (select auth.uid()));

create policy day_stats_select_own on public.day_stats
  for select to authenticated using (owner_id = (select auth.uid()));

create policy snapshots_select_own on public.snapshots
  for select to authenticated using (owner_id = (select auth.uid()));

create policy chronicles_select_own on public.chronicles
  for select to authenticated using (owner_id = (select auth.uid()));

-- ai_usage, notification_deliveries: no policies (service role only).

-- ---------------------------------------------------------------------------
-- Guilds
-- ---------------------------------------------------------------------------

create policy guilds_select_member_or_public on public.guilds
  for select to authenticated
  using (visibility = 'public' or public.is_guild_member(id));
create policy guilds_update_officers on public.guilds
  for update to authenticated
  using (public.is_guild_officer(id)) with check (public.is_guild_officer(id));

create policy guild_members_select_members on public.guild_members
  for select to authenticated using (public.is_guild_member(guild_id));
create policy guild_members_update_own_prefs on public.guild_members
  for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy guild_invites_select_officers on public.guild_invites
  for select to authenticated using (public.is_guild_officer(guild_id));

-- Feed: members only; hidden (moderated) events and events by users the
-- viewer blocked are filtered out. Payloads are already privacy-projected.
create policy feed_events_select_members on public.feed_events
  for select to authenticated
  using (
    public.is_guild_member(guild_id)
    and hidden_at is null
    and not public.is_blocked_by_me(actor_id)
  );

-- The EXISTS subquery is itself subject to the feed_events policy, so a
-- reaction is visible only when its event is.
create policy reactions_select_visible on public.reactions
  for select to authenticated
  using (
    not public.is_blocked_by_me(user_id)
    and exists (select 1 from public.feed_events e where e.id = reactions.event_id)
  );

create policy comments_select_visible on public.comments
  for select to authenticated
  using (
    deleted_at is null
    and hidden_at is null
    and public.is_guild_member(guild_id)
    and not public.is_blocked_by_me(author_id)
    and exists (select 1 from public.feed_events e where e.id = comments.event_id)
  );

create policy challenges_select_members on public.challenges
  for select to authenticated using (public.is_guild_member(guild_id));

create policy challenge_contributions_select_members on public.challenge_contributions
  for select to authenticated
  using (exists (select 1 from public.challenges c where c.id = challenge_contributions.challenge_id));

-- ---------------------------------------------------------------------------
-- Safety and notifications
-- ---------------------------------------------------------------------------

-- Only the blocker can see a block; the blocked party cannot detect it.
create policy blocks_select_own on public.blocks
  for select to authenticated using (blocker_id = (select auth.uid()));

create policy reports_select_own on public.reports
  for select to authenticated using (reporter_id = (select auth.uid()));

create policy notification_prefs_select_own on public.notification_prefs
  for select to authenticated using (user_id = (select auth.uid()));
create policy notification_prefs_insert_own on public.notification_prefs
  for insert to authenticated with check (user_id = (select auth.uid()));
create policy notification_prefs_update_own on public.notification_prefs
  for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy push_tokens_select_own on public.push_tokens
  for select to authenticated using (user_id = (select auth.uid()));
create policy push_tokens_insert_own on public.push_tokens
  for insert to authenticated with check (user_id = (select auth.uid()));
create policy push_tokens_update_own on public.push_tokens
  for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy push_tokens_delete_own on public.push_tokens
  for delete to authenticated using (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- Realtime: change signals for the client's pull loop (ADR-003). Realtime
-- applies these RLS policies; clients only ever react by calling sync_pull.
-- ---------------------------------------------------------------------------

do $$
declare
  v_table text;
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    raise notice 'supabase_realtime publication not found; skipping realtime setup';
    return;
  end if;
  foreach v_table in array array[
    'quests', 'subtasks', 'completions', 'ledger_entries', 'characters', 'day_stats',
    'achievements', 'chronicles', 'feed_events', 'reactions', 'comments', 'challenges'
  ] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = v_table
    ) then
      execute format('alter publication supabase_realtime add table public.%I', v_table);
    end if;
  end loop;
end;
$$;
