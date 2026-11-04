-- =============================================================================
-- Oathbound · progression RPCs (overview §4, progression-rules §5–§11)
--
-- The TypeScript engine in the evaluate-completion Edge Function computes
-- the authoritative RewardResult; apply_progression persists it in ONE
-- transaction: ledger rows, day_stats, character cache, achievements,
-- challenge contributions and privacy-projected feed events.
--
-- Service-role only:  apply_progression, get_day_state, consume_ai_quota,
--                     count_similar_completions, chronicle_facts
-- Owner RPCs:         undo_completion, set_rest_day, update_character
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Curves (progression rules §6). Same numbers as curves.ts / curves.dart;
-- numeric arithmetic so round() is half-away-from-zero like Dart.
-- ---------------------------------------------------------------------------

create or replace function public.xp_to_advance_level(n integer)
returns integer
language sql
immutable
parallel safe
set search_path = ''
as $$
  select round(100 * power(n::numeric, 1.5))::integer;
$$;

create or replace function public.xp_to_advance_rank(n integer)
returns integer
language sql
immutable
parallel safe
set search_path = ''
as $$
  select round(40 * power(n::numeric, 1.4))::integer;
$$;

create or replace function public.level_for_xp(xp bigint)
returns integer
language plpgsql
immutable
parallel safe
set search_path = ''
as $$
declare
  v_step integer := 1;
  v_remaining bigint := greatest(coalesce(xp, 0), 0);
begin
  while v_remaining >= public.xp_to_advance_level(v_step) loop
    v_remaining := v_remaining - public.xp_to_advance_level(v_step);
    v_step := v_step + 1;
  end loop;
  return v_step;
end;
$$;

create or replace function public.rank_for_xp(xp bigint)
returns integer
language plpgsql
immutable
parallel safe
set search_path = ''
as $$
declare
  v_step integer := 1;
  v_remaining bigint := greatest(coalesce(xp, 0), 0);
begin
  while v_remaining >= public.xp_to_advance_rank(v_step) loop
    v_remaining := v_remaining - public.xp_to_advance_rank(v_step);
    v_step := v_step + 1;
  end loop;
  return v_step;
end;
$$;

grant execute on function public.xp_to_advance_level(integer) to anon, authenticated, service_role;
grant execute on function public.xp_to_advance_rank(integer) to anon, authenticated, service_role;
grant execute on function public.level_for_xp(bigint) to anon, authenticated, service_role;
grant execute on function public.rank_for_xp(bigint) to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Condition (rules §7.3) — twin of Consistency.condition in consistency.dart:
-- start at 100 on the first recorded day, apply each finished day's delta,
-- then today's strain. Missed quests never reduce condition.
-- ---------------------------------------------------------------------------

create or replace function private.compute_condition(p_owner uuid, p_today date)
returns smallint
language plpgsql
stable
set search_path = ''
as $$
declare
  v_start date;
  v_value integer := 100;
  v_minutes integer;
  v_day record;
begin
  select min(s.local_day) into v_start from public.day_stats s where s.owner_id = p_owner;
  if v_start is null then
    return 100;
  end if;
  for v_day in
    select d::date as day, s.owner_id is not null as has_record,
           coalesce(s.minutes, 0) as minutes,
           coalesce((s.xp ->> 'vitality')::integer, 0) as vitality_xp,
           coalesce(s.rest_day, false) as rest_day
    from generate_series(v_start, p_today - 1, interval '1 day') d
    left join public.day_stats s on s.owner_id = p_owner and s.local_day = d::date
    order by d
  loop
    v_value := greatest(25, least(100, v_value + case
      when v_day.minutes > 600 then -least(30, (v_day.minutes - 600) / 10)
      else 15 end));
    if v_day.has_record and v_day.vitality_xp >= 20 then
      v_value := greatest(25, least(100, v_value + 10));
    end if;
    if v_day.has_record and v_day.rest_day then
      v_value := greatest(25, least(100, v_value + 25));
    end if;
  end loop;
  select s.minutes into v_minutes from public.day_stats s
  where s.owner_id = p_owner and s.local_day = p_today;
  if coalesce(v_minutes, 0) > 600 then
    v_value := greatest(25, least(100, v_value - least(30, (v_minutes - 600) / 10)));
  end if;
  return v_value::smallint;
end;
$$;

-- Rebuilds the character cache from the confirmed ledger (grants and
-- reversals). The cache is always reproducible from the ledger.
create or replace function private.rebuild_character_cache(p_owner uuid)
returns public.characters
language plpgsql
set search_path = ''
as $$
declare
  v_xp jsonb;
  v_total bigint;
  v_character public.characters;
begin
  select coalesce(jsonb_object_agg(t.attribute, t.amount), '{}'::jsonb), coalesce(sum(t.amount), 0)
    into v_xp, v_total
  from (
    select l.attribute::text as attribute, greatest(sum(l.amount), 0)::bigint as amount
    from public.ledger_entries l
    where l.owner_id = p_owner and l.status = 'confirmed'
    group by l.attribute
  ) t;

  insert into public.characters (owner_id) values (p_owner) on conflict (owner_id) do nothing;
  update public.characters c set
    attr_xp = private.zero_attributes() || v_xp,
    total_xp = v_total,
    level = public.level_for_xp(v_total),
    condition = private.compute_condition(p_owner, private.user_today(p_owner))
  where c.owner_id = p_owner
  returning * into v_character;
  return v_character;
end;
$$;

-- ---------------------------------------------------------------------------
-- Achievements (rules §9.1) derivable from server state. kept_weeks_* need
-- the week/pause model and are evaluated by the client consistency engine.
-- ---------------------------------------------------------------------------

create or replace function private.award_achievements(
  p_owner uuid, p_completion_id uuid, p_local_day date
)
returns text[]
language plpgsql
set search_path = ''
as $$
declare
  c_titles constant jsonb := '{
    "first_oath": "sworn", "deeds_100": "centurion", "first_objective": "pathfinder",
    "level_10": "seasoned", "the_return": "returned", "balanced": "whole",
    "rank_10_strength": "ironbound", "rank_10_intelligence": "adept_of_lore",
    "rank_10_discipline": "unbending", "rank_10_creativity": "dreamwright",
    "rank_10_vitality": "evergreen", "rank_10_social": "kindred"
  }';
  v_total bigint;
  v_contracts bigint;
  v_objectives bigint;
  v_minutes bigint;
  v_character public.characters;
  v_attribute text;
  v_rank integer;
  v_min_rank integer := 1000;
  v_previous_active date;
  v_candidates text[] := '{}';
  v_unlocked text[];
begin
  select count(*),
         count(*) filter (where q.tier = 'contract'),
         count(*) filter (where q.tier = 'objective')
    into v_total, v_contracts, v_objectives
  from public.completions c
  join public.quests q on q.id = c.quest_id
  where c.owner_id = p_owner and c.state = 'active';

  select coalesce(sum(s.minutes), 0) into v_minutes from public.day_stats s where s.owner_id = p_owner;
  select * into v_character from public.characters c where c.owner_id = p_owner;

  if v_total >= 1 then v_candidates := array_append(v_candidates, 'first_oath'); end if;
  if v_total >= 10 then v_candidates := array_append(v_candidates, 'deeds_10'); end if;
  if v_total >= 100 then v_candidates := array_append(v_candidates, 'deeds_100'); end if;
  if v_total >= 1000 then v_candidates := array_append(v_candidates, 'deeds_1000'); end if;
  if v_contracts >= 1 then v_candidates := array_append(v_candidates, 'first_contract'); end if;
  if v_objectives >= 1 then v_candidates := array_append(v_candidates, 'first_objective'); end if;
  if v_character.level >= 5 then v_candidates := array_append(v_candidates, 'level_5'); end if;
  if v_character.level >= 10 then v_candidates := array_append(v_candidates, 'level_10'); end if;
  if v_character.level >= 25 then v_candidates := array_append(v_candidates, 'level_25'); end if;

  foreach v_attribute in array array['strength', 'intelligence', 'discipline', 'creativity', 'vitality', 'social'] loop
    v_rank := public.rank_for_xp(coalesce((v_character.attr_xp ->> v_attribute)::bigint, 0));
    v_min_rank := least(v_min_rank, v_rank);
    if v_rank >= 10 then
      v_candidates := array_append(v_candidates, ('rank_10_' || v_attribute));
    end if;
  end loop;
  if v_min_rank >= 3 then v_candidates := array_append(v_candidates, 'balanced'); end if;
  if v_minutes >= 6000 then v_candidates := array_append(v_candidates, 'hours_100'); end if;

  -- The Return: a completion after ≥ 7 inactive days (rules §7.4).
  select max(s.local_day) into v_previous_active
  from public.day_stats s
  where s.owner_id = p_owner and s.local_day < p_local_day and s.nontrivial_completions > 0;
  if v_previous_active is not null and p_local_day - v_previous_active - 1 >= 7 then
    v_candidates := array_append(v_candidates, 'the_return');
  end if;

  with inserted as (
    insert into public.achievements (owner_id, achievement_id, title_id, completion_id)
    select p_owner, a, c_titles ->> a, p_completion_id
    from unnest(v_candidates) a
    on conflict (owner_id, achievement_id) do nothing
    returning achievement_id
  )
  select coalesce(array_agg(achievement_id order by achievement_id), '{}') into v_unlocked from inserted;
  return v_unlocked;
end;
$$;

-- ---------------------------------------------------------------------------
-- Privacy projection (overview §3): only the fields the sharing level permits.
-- ---------------------------------------------------------------------------

create or replace function private.project_completion_payload(
  p_level public.share_level,
  p_title text,
  p_tier public.quest_tier,
  p_category public.quest_category,
  p_total_xp integer,
  p_attribute_xp jsonb
)
returns jsonb
language sql
immutable
set search_path = ''
as $$
  select case p_level
    when 'full' then jsonb_build_object(
      'share_level', 'full', 'title', p_title, 'total_xp', p_total_xp, 'attributes', p_attribute_xp)
    when 'title_only' then jsonb_build_object('share_level', 'title_only', 'title', p_title)
    when 'completion_only' then jsonb_build_object(
      'share_level', 'completion_only', 'tier', p_tier, 'category', p_category)
    else null
  end;
$$;

-- Records a contribution and posts 25/50/75/100 % milestones (rules §10).
create or replace function private.add_challenge_progress(
  p_challenge_id uuid, p_user_id uuid, p_completion_id uuid, p_amount integer, p_anonymous boolean
)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_challenge public.challenges;
  v_percent numeric;
  v_milestone smallint;
begin
  insert into public.challenge_contributions (challenge_id, user_id, completion_id, amount, kind, anonymous)
  values (p_challenge_id, case when p_anonymous then null else p_user_id end, p_completion_id,
          p_amount, 'contribution', p_anonymous)
  on conflict (challenge_id, completion_id, kind) do nothing;
  if not found then
    return;
  end if;

  update public.challenges ch set progress = ch.progress + p_amount
  where ch.id = p_challenge_id
  returning * into v_challenge;

  v_percent := v_challenge.progress * 100.0 / v_challenge.target;
  v_milestone := case
    when v_percent >= 100 then 100 when v_percent >= 75 then 75
    when v_percent >= 50 then 50 when v_percent >= 25 then 25 else 0 end;
  if v_milestone > v_challenge.milestones_reached then
    update public.challenges ch set milestones_reached = v_milestone where ch.id = p_challenge_id;
    insert into public.feed_events (guild_id, actor_id, kind, payload, challenge_id)
    values (
      v_challenge.guild_id, null, 'challenge_milestone',
      jsonb_build_object(
        'challenge_id', v_challenge.id, 'title', v_challenge.title, 'milestone', v_milestone,
        'progress', v_challenge.progress, 'target', v_challenge.target, 'metric', v_challenge.metric
      ),
      v_challenge.id
    );
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- apply_progression
-- ---------------------------------------------------------------------------

-- Persists an engine result for one completion. Idempotent: if the
-- completion was already evaluated (confirmed ledger rows exist or the
-- evaluation flag is set) nothing changes and the stored result is returned.
--
-- meta (optional): { latency_ms, input_hash, fallback_reason,
--                    day_change_id }  — when day_change_id is present, the
-- call is rejected with status 'stale_day_state' if day_stats changed since
-- the caller read it, so concurrent evaluations never double-spend a cap.
create or replace function public.apply_progression(
  completion_id uuid,
  result jsonb,
  proposal jsonb,
  source text,
  model text,
  meta jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_completion_id uuid := apply_progression.completion_id;
  v_result jsonb := apply_progression.result;
  v_proposal jsonb := coalesce(apply_progression.proposal, '{}'::jsonb);
  v_source text := apply_progression.source;
  v_model text := apply_progression.model;
  v_meta jsonb := coalesce(apply_progression.meta, '{}'::jsonb);
  v_completion public.completions;
  v_quest public.quests;
  v_character public.characters;
  v_grant jsonb;
  v_attribute public.attribute;
  v_amount integer;
  v_raw integer;
  v_total integer := 0;
  v_xp_delta jsonb := '{}'::jsonb;
  v_raw_delta jsonb := '{}'::jsonb;
  v_minutes integer;
  v_trivial boolean;
  v_key text;
  v_rule_version text;
  v_adjustments jsonb;
  v_category public.quest_category;
  v_day_change bigint;
  v_ledger jsonb := '[]'::jsonb;
  v_row public.ledger_entries;
  v_unlocked text[];
  v_membership record;
  v_challenge public.challenges;
  v_contribution integer;
  v_feed_events integer := 0;
begin
  -- Validate the engine output (defence in depth; the engine already caps).
  if v_source is null or v_source not in ('ai', 'heuristic') then
    raise exception 'source must be ai or heuristic' using errcode = '22023';
  end if;
  if v_result is null or jsonb_typeof(v_result) <> 'object'
     or jsonb_typeof(v_result -> 'grants') <> 'array'
     or jsonb_array_length(v_result -> 'grants') > 6 then
    raise exception 'result.grants must be an array of at most 6 grants' using errcode = '22023';
  end if;
  v_minutes := (v_result ->> 'effectiveMinutes')::integer;
  v_trivial := (v_result ->> 'trivial')::boolean;
  v_key := v_result ->> 'similarityKey';
  v_rule_version := v_result ->> 'ruleVersion';
  v_adjustments := coalesce(v_result -> 'adjustments', '[]'::jsonb);
  if v_minutes is null or v_minutes not between 0 and 480
     or v_trivial is null
     or v_key is null or char_length(v_key) not between 1 and 48
     or v_rule_version is null
     or jsonb_typeof(v_adjustments) <> 'array' then
    raise exception 'malformed result' using errcode = '22023';
  end if;
  if (v_proposal ->> 'category') in (
    'study', 'work', 'fitness', 'health', 'creative', 'social',
    'chores', 'admin', 'mindfulness', 'reading', 'other') then
    v_category := (v_proposal ->> 'category')::public.quest_category;
  end if;

  -- Serialise per owner (same key as the sync trigger, so one user's
  -- day_stats reads and writes never interleave), then per completion.
  -- Lock order owner → completion everywhere (sync_push, undo) avoids
  -- deadlocks; owner_id is immutable, so reading it unlocked is safe.
  select * into v_completion from public.completions c where c.id = v_completion_id;
  if not found then
    raise exception 'completion % not found', v_completion_id using errcode = 'P0002';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('sync:' || v_completion.owner_id::text, 0));
  perform pg_advisory_xact_lock(hashtextextended('progression:' || v_completion_id::text, 0));
  select * into v_completion from public.completions c where c.id = v_completion_id for update;

  if v_completion.state <> 'active' then
    return jsonb_build_object('status', 'undone', 'completion_id', v_completion_id);
  end if;

  if v_completion.evaluation_status = 'evaluated' or exists (
    select 1 from public.ledger_entries l
    where l.completion_id = v_completion_id and l.kind = 'grant' and l.status = 'confirmed'
  ) then
    return jsonb_build_object(
      'status', 'already_applied',
      'completion_id', v_completion_id,
      'result', v_completion.result,
      'ledger', coalesce((
        select jsonb_agg(to_jsonb(l) order by l.created_at) from public.ledger_entries l
        where l.completion_id = v_completion_id and l.status = 'confirmed'
      ), '[]'::jsonb)
    );
  end if;

  if v_meta ? 'day_change_id' then
    select s.change_id into v_day_change from public.day_stats s
    where s.owner_id = v_completion.owner_id and s.local_day = v_completion.local_day;
    if v_day_change is distinct from (v_meta ->> 'day_change_id')::bigint then
      return jsonb_build_object('status', 'stale_day_state', 'completion_id', v_completion_id);
    end if;
  end if;

  select * into v_quest from public.quests q where q.id = v_completion.quest_id;

  -- 1. Offline results for this completion are superseded (rules §11).
  update public.ledger_entries l set status = 'superseded'
  where l.completion_id = v_completion_id and l.status = 'provisional';

  -- 2. Ledger rows (FR-2: every attribute change is backed by an entry).
  for v_grant in select value from jsonb_array_elements(v_result -> 'grants') loop
    v_attribute := (v_grant ->> 'attribute')::public.attribute;
    v_amount := (v_grant ->> 'amount')::integer;
    v_raw := (v_grant ->> 'rawAmount')::integer;
    if v_amount is null or v_raw is null or v_amount < 1 or v_amount > 400
       or v_raw < v_amount or v_raw > 1000 or v_raw_delta ? v_attribute::text then
      raise exception 'invalid grant %', v_grant using errcode = '22023';
    end if;
    insert into public.ledger_entries (
      owner_id, completion_id, attribute, amount, raw_amount, kind, status,
      rule_version, adjustments, source, model, similarity_key, local_day
    )
    values (
      v_completion.owner_id, v_completion_id, v_attribute, v_amount, v_raw, 'grant', 'confirmed',
      v_rule_version, v_adjustments, v_source, v_model, v_key, v_completion.local_day
    )
    returning * into v_row;
    v_ledger := v_ledger || to_jsonb(v_row);
    v_total := v_total + v_amount;
    v_xp_delta := v_xp_delta || jsonb_build_object(v_attribute::text, v_amount);
    v_raw_delta := v_raw_delta || jsonb_build_object(v_attribute::text, v_raw);
  end loop;

  -- 3. The evaluator proposal, for audit and the 7-day cache.
  insert into public.evaluations (
    completion_id, owner_id, source, model, proposal, input_hash, latency_ms, fallback_reason
  )
  values (
    v_completion_id, v_completion.owner_id, v_source, v_model, v_proposal,
    v_meta ->> 'input_hash', (v_meta ->> 'latency_ms')::integer, left(v_meta ->> 'fallback_reason', 200)
  );

  -- 4. Day rollup = RewardResult.applyTo(dayState) on the server.
  insert into public.day_stats as s (
    owner_id, local_day, minutes, xp, raw_xp, similarity_counts,
    completions, nontrivial_completions, trivial_count, total_xp
  )
  values (
    v_completion.owner_id, v_completion.local_day, v_minutes, v_xp_delta, v_raw_delta,
    jsonb_build_object(v_key, 1), 1,
    case when v_trivial then 0 else 1 end, case when v_trivial then 1 else 0 end, v_total
  )
  on conflict (owner_id, local_day) do update set
    minutes = s.minutes + excluded.minutes,
    xp = private.jsonb_add_counts(s.xp, excluded.xp),
    raw_xp = private.jsonb_add_counts(s.raw_xp, excluded.raw_xp),
    similarity_counts = private.jsonb_add_counts(s.similarity_counts, excluded.similarity_counts),
    completions = s.completions + 1,
    nontrivial_completions = s.nontrivial_completions + excluded.nontrivial_completions,
    trivial_count = s.trivial_count + excluded.trivial_count,
    total_xp = s.total_xp + excluded.total_xp;

  -- 5. Completion outcome.
  update public.completions c set
    evaluation_status = 'evaluated',
    evaluated_at = now(),
    result = v_result,
    category = coalesce(v_category, v_quest.category, 'other'),
    similarity_key = v_key,
    effective_minutes = v_minutes,
    trivial = v_trivial,
    total_xp = v_total
  where c.id = v_completion_id;

  -- 6. Character cache (level from the 100·n^1.5 curve).
  insert into public.characters (owner_id) values (v_completion.owner_id) on conflict (owner_id) do nothing;
  update public.characters c set
    attr_xp = private.zero_attributes() || private.jsonb_add_counts(c.attr_xp, v_xp_delta, false),
    total_xp = c.total_xp + v_total,
    level = public.level_for_xp(c.total_xp + v_total),
    condition = private.compute_condition(v_completion.owner_id, private.user_today(v_completion.owner_id))
  where c.owner_id = v_completion.owner_id
  returning * into v_character;

  -- 7. Achievements (recognition only, never XP).
  v_unlocked := private.award_achievements(v_completion.owner_id, v_completion_id, v_completion.local_day);

  -- 8. Guilds: challenge contributions and one projected feed event per guild.
  for v_membership in
    select m.guild_id, m.contribute_private,
           coalesce(v_quest.share_level, m.share_level, g.default_share_level) as share_level
    from public.guild_members m
    join public.guilds g on g.id = m.guild_id
    where m.user_id = v_completion.owner_id
  loop
    -- Private completions count only for members who opted in (anonymously).
    if v_membership.share_level <> 'private' or v_membership.contribute_private then
      for v_challenge in
        select * from public.challenges ch
        where ch.guild_id = v_membership.guild_id
          and ch.status = 'active'
          and v_completion.completed_at >= ch.starts_at
          and v_completion.completed_at < ch.ends_at
      loop
        v_contribution := case v_challenge.metric
          when 'minutes_in_category' then
            case when coalesce(v_category, v_quest.category) = v_challenge.metric_category then v_minutes else 0 end
          when 'completions' then case when v_trivial then 0 else 1 end
          when 'xp_in_attribute' then coalesce((v_xp_delta ->> v_challenge.metric_attribute::text)::integer, 0)
          else 0
        end;
        if v_contribution > 0 then
          perform private.add_challenge_progress(
            v_challenge.id, v_completion.owner_id, v_completion_id, v_contribution,
            v_membership.share_level = 'private'
          );
        end if;
      end loop;
    end if;

    -- Trivial deeds stay out of the feed so it does not overwhelm.
    if v_membership.share_level <> 'private' and not v_trivial then
      insert into public.feed_events (guild_id, actor_id, kind, payload, completion_id)
      values (
        v_membership.guild_id, v_completion.owner_id, 'completion',
        private.project_completion_payload(
          v_membership.share_level, v_quest.title, v_quest.tier,
          coalesce(v_category, v_quest.category, 'other'), v_total, v_xp_delta
        ),
        v_completion_id
      )
      on conflict (guild_id, completion_id) where kind = 'completion' do nothing;
      if found then
        v_feed_events := v_feed_events + 1;
      end if;
    end if;
  end loop;

  return jsonb_build_object(
    'status', 'applied',
    'completion_id', v_completion_id,
    'result', v_result,
    'ledger', v_ledger,
    'character', jsonb_build_object(
      'attr_xp', v_character.attr_xp, 'total_xp', v_character.total_xp,
      'level', v_character.level, 'condition', v_character.condition
    ),
    'achievements', to_jsonb(v_unlocked),
    'feed_events', v_feed_events
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Undo (rules §11, FR-4): append reversing entries, roll caches back.
-- ---------------------------------------------------------------------------

create or replace function private.undo_completion_internal(
  p_completion_id uuid,
  p_actor uuid,
  p_requested_at timestamptz default now()
)
returns jsonb
language plpgsql
set search_path = ''
as $$
declare
  v_completion public.completions;
  v_entry public.ledger_entries;
  v_reversal public.ledger_entries;
  v_reversals jsonb := '[]'::jsonb;
  v_xp_delta jsonb := '{}'::jsonb;
  v_raw_delta jsonb := '{}'::jsonb;
  v_contribution public.challenge_contributions;
  v_character public.characters;
begin
  select * into v_completion from public.completions c where c.id = p_completion_id;
  if not found or (p_actor is not null and v_completion.owner_id <> p_actor) then
    raise exception 'completion % not found', p_completion_id using errcode = 'P0002';
  end if;
  -- Same lock order as apply_progression: owner, then completion.
  perform pg_advisory_xact_lock(hashtextextended('sync:' || v_completion.owner_id::text, 0));
  perform pg_advisory_xact_lock(hashtextextended('progression:' || p_completion_id::text, 0));
  select * into v_completion from public.completions c where c.id = p_completion_id for update;

  if v_completion.state = 'undone' then
    return jsonb_build_object('status', 'already_undone', 'completion_id', p_completion_id);
  end if;
  if p_actor is not null and coalesce(p_requested_at, now()) - v_completion.completed_at > interval '24 hours' then
    raise exception 'the undo window (24 hours) has passed'
      using errcode = 'P0001', hint = 'undo_window_expired';
  end if;

  update public.completions c set state = 'undone', undone_at = coalesce(p_requested_at, now())
  where c.id = p_completion_id;

  update public.ledger_entries l set status = 'superseded'
  where l.completion_id = p_completion_id and l.status = 'provisional';

  for v_entry in
    select * from public.ledger_entries l
    where l.completion_id = p_completion_id and l.kind = 'grant' and l.status = 'confirmed'
      and not exists (select 1 from public.ledger_entries r where r.reverses_id = l.id)
  loop
    insert into public.ledger_entries (
      owner_id, completion_id, attribute, amount, raw_amount, kind, status,
      rule_version, adjustments, source, model, similarity_key, reverses_id, local_day
    )
    values (
      v_entry.owner_id, p_completion_id, v_entry.attribute, -v_entry.amount, -v_entry.raw_amount,
      'reversal', 'confirmed', v_entry.rule_version, '[]'::jsonb, 'system', null,
      v_entry.similarity_key, v_entry.id, v_entry.local_day
    )
    returning * into v_reversal;
    v_reversals := v_reversals || to_jsonb(v_reversal);
    v_xp_delta := v_xp_delta || jsonb_build_object(v_entry.attribute::text, -v_entry.amount);
    v_raw_delta := v_raw_delta || jsonb_build_object(v_entry.attribute::text, -v_entry.raw_amount);
  end loop;

  if v_completion.evaluation_status = 'evaluated' then
    -- Today's raw totals drop accordingly (rules §11).
    update public.day_stats s set
      minutes = greatest(0, s.minutes - coalesce(v_completion.effective_minutes, 0)),
      xp = private.jsonb_add_counts(s.xp, v_xp_delta),
      raw_xp = private.jsonb_add_counts(s.raw_xp, v_raw_delta),
      similarity_counts = private.jsonb_add_counts(
        s.similarity_counts, jsonb_build_object(v_completion.similarity_key, -1)),
      completions = greatest(0, s.completions - 1),
      nontrivial_completions = greatest(0, s.nontrivial_completions
        - case when coalesce(v_completion.trivial, false) then 0 else 1 end),
      trivial_count = greatest(0, s.trivial_count
        - case when coalesce(v_completion.trivial, false) then 1 else 0 end),
      total_xp = s.total_xp - coalesce(v_completion.total_xp, 0)
    where s.owner_id = v_completion.owner_id and s.local_day = v_completion.local_day;

    -- Challenge progress is reversed; milestones already reached stay recorded.
    for v_contribution in
      select * from public.challenge_contributions cc
      where cc.completion_id = p_completion_id and cc.kind = 'contribution'
    loop
      insert into public.challenge_contributions (
        challenge_id, user_id, completion_id, amount, kind, anonymous
      )
      values (
        v_contribution.challenge_id, v_contribution.user_id, p_completion_id,
        -v_contribution.amount, 'reversal', v_contribution.anonymous
      )
      on conflict (challenge_id, completion_id, kind) do nothing;
      if found then
        update public.challenges ch set progress = greatest(0, ch.progress - v_contribution.amount)
        where ch.id = v_contribution.challenge_id;
      end if;
    end loop;

    -- The deed leaves the guild feeds (reactions/comments cascade).
    delete from public.feed_events e where e.completion_id = p_completion_id and e.kind = 'completion';
  end if;

  v_character := private.rebuild_character_cache(v_completion.owner_id);

  return jsonb_build_object(
    'status', 'undone',
    'completion_id', p_completion_id,
    'reversals', v_reversals,
    'character', jsonb_build_object(
      'attr_xp', v_character.attr_xp, 'total_xp', v_character.total_xp,
      'level', v_character.level, 'condition', v_character.condition
    )
  );
end;
$$;

create or replace function public.undo_completion(completion_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  return private.undo_completion_internal(undo_completion.completion_id, auth.uid(), now());
end;
$$;

-- ---------------------------------------------------------------------------
-- Helpers for the evaluate-completion function (service role only)
-- ---------------------------------------------------------------------------

-- The engine's DayState for one user and local day, plus the change_id the
-- caller passes back to apply_progression for the optimistic check.
create or replace function public.get_day_state(user_id uuid, local_day date)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (
      select jsonb_build_object(
        'rawXp', s.raw_xp,
        'creditedMinutes', s.minutes,
        'similarityCounts', s.similarity_counts,
        'trivialCount', s.trivial_count,
        'changeId', s.change_id
      )
      from public.day_stats s
      where s.owner_id = get_day_state.user_id and s.local_day = get_day_state.local_day
    ),
    jsonb_build_object(
      'rawXp', '{}'::jsonb, 'creditedMinutes', 0, 'similarityCounts', '{}'::jsonb,
      'trivialCount', 0, 'changeId', null
    )
  );
$$;

-- Counts one AI call against the per-user daily limit (UTC day). Returns
-- false when the call would exceed the limit (the caller then uses the
-- heuristic evaluator).
create or replace function public.consume_ai_quota(user_id uuid, route text, daily_limit integer)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_calls integer;
begin
  insert into public.ai_usage as u (owner_id, usage_day, route, calls)
  values (consume_ai_quota.user_id, (now() at time zone 'utc')::date, consume_ai_quota.route, 1)
  on conflict (owner_id, usage_day, route) do update set calls = u.calls + 1
  returning u.calls into v_calls;
  return v_calls <= consume_ai_quota.daily_limit;
end;
$$;

-- Similar completions in the last 7 days (rules §8.2): same quest, or same
-- similarity key as already evaluated.
create or replace function public.count_similar_completions(
  user_id uuid, quest_id uuid, similarity_key text, exclude_completion_id uuid default null
)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)::integer
  from public.completions c
  where c.owner_id = count_similar_completions.user_id
    and c.state = 'active'
    and c.completed_at >= now() - interval '7 days'
    and c.id is distinct from count_similar_completions.exclude_completion_id
    and (c.quest_id = count_similar_completions.quest_id
         or c.similarity_key = count_similar_completions.similarity_key);
$$;

-- ---------------------------------------------------------------------------
-- Owner RPCs
-- ---------------------------------------------------------------------------

-- Declares (or clears) a rest day (rules §7.3: +25 condition).
create or replace function public.set_rest_day(local_day date, rest boolean default true)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := auth.uid();
  v_today date;
  v_condition smallint;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  v_today := private.user_today(v_uid);
  if set_rest_day.local_day not between v_today - 7 and v_today + 7 then
    raise exception 'rest days can be set within 7 days of today' using errcode = '22023';
  end if;
  insert into public.day_stats as s (owner_id, local_day, rest_day)
  values (v_uid, set_rest_day.local_day, coalesce(set_rest_day.rest, true))
  on conflict (owner_id, local_day) do update set rest_day = excluded.rest_day;

  v_condition := private.compute_condition(v_uid, v_today);
  update public.characters c set condition = v_condition where c.owner_id = v_uid;
  return jsonb_build_object('local_day', set_rest_day.local_day, 'rest_day', coalesce(set_rest_day.rest, true),
                            'condition', v_condition);
end;
$$;

-- Cosmetic character fields. The equipped title must have been unlocked.
create or replace function public.update_character(
  name text default null, portrait text default null, equipped_title text default null,
  clear_title boolean default false
)
returns public.characters
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_character public.characters;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  if update_character.equipped_title is not null and not exists (
    select 1 from public.achievements a
    where a.owner_id = v_uid and a.title_id = update_character.equipped_title
  ) then
    raise exception 'title % is not unlocked', update_character.equipped_title using errcode = '22023';
  end if;
  update public.characters c set
    name = coalesce(btrim(update_character.name), c.name),
    portrait = coalesce(update_character.portrait, c.portrait),
    equipped_title = case
      when update_character.clear_title then null
      else coalesce(update_character.equipped_title, c.equipped_title) end
  where c.owner_id = v_uid
  returning * into v_character;
  return v_character;
end;
$$;

-- ---------------------------------------------------------------------------
-- Chronicle facts (ADR-005 grounding): everything the narrative may mention.
-- Similarity keys (language-independent slugs) are used instead of quest
-- titles, so no user-authored text leaves the database for chronicles.
-- ---------------------------------------------------------------------------

create or replace function public.chronicle_facts(user_id uuid, period text, period_start date)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := chronicle_facts.user_id;
  v_start date := chronicle_facts.period_start;
  v_end date;
  v_prev_start date;
  v_current jsonb;
  v_previous jsonb;
  v_xp jsonb;
  v_prev_xp jsonb;
  v_deltas jsonb;
  v_top jsonb;
  v_best_day jsonb;
  v_longest jsonb;
  v_achievements jsonb;
  v_tiers jsonb;
  v_xp_before_start bigint;
  v_xp_before_end bigint;
begin
  case chronicle_facts.period
    when 'week' then v_end := v_start + 7; v_prev_start := v_start - 7;
    when 'month' then
      if extract(day from v_start) <> 1 then
        raise exception 'monthly chronicles start on the 1st' using errcode = '22023';
      end if;
      v_end := (v_start + interval '1 month')::date; v_prev_start := (v_start - interval '1 month')::date;
    when 'year' then
      if extract(doy from v_start) <> 1 then
        raise exception 'yearly chronicles start on 1 January' using errcode = '22023';
      end if;
      v_end := (v_start + interval '1 year')::date; v_prev_start := (v_start - interval '1 year')::date;
    else
      raise exception 'period must be week, month or year' using errcode = '22023';
  end case;

  -- Totals from the day rollups.
  select jsonb_build_object(
      'completions', coalesce(sum(s.completions), 0),
      'deeds', coalesce(sum(s.nontrivial_completions), 0),
      'minutes', coalesce(sum(s.minutes), 0),
      'hours', round(coalesce(sum(s.minutes), 0) / 60.0, 1),
      'xp', coalesce(sum(s.total_xp), 0),
      'activeDays', count(*) filter (where s.nontrivial_completions > 0),
      'restDays', count(*) filter (where s.rest_day)
    ) into v_current
  from public.day_stats s
  where s.owner_id = v_uid and s.local_day >= v_start and s.local_day < v_end;

  select jsonb_build_object(
      'completions', coalesce(sum(s.completions), 0),
      'deeds', coalesce(sum(s.nontrivial_completions), 0),
      'minutes', coalesce(sum(s.minutes), 0),
      'hours', round(coalesce(sum(s.minutes), 0) / 60.0, 1),
      'xp', coalesce(sum(s.total_xp), 0),
      'activeDays', count(*) filter (where s.nontrivial_completions > 0)
    ) into v_previous
  from public.day_stats s
  where s.owner_id = v_uid and s.local_day >= v_prev_start and s.local_day < v_start;

  -- Net credited XP per attribute (grants minus reversals), both periods.
  select private.zero_attributes() || coalesce(jsonb_object_agg(t.attribute, t.amount), '{}'::jsonb) into v_xp
  from (
    select l.attribute::text as attribute, sum(l.amount)::bigint as amount
    from public.ledger_entries l
    where l.owner_id = v_uid and l.status = 'confirmed' and l.local_day >= v_start and l.local_day < v_end
    group by l.attribute
  ) t;
  select private.zero_attributes() || coalesce(jsonb_object_agg(t.attribute, t.amount), '{}'::jsonb) into v_prev_xp
  from (
    select l.attribute::text as attribute, sum(l.amount)::bigint as amount
    from public.ledger_entries l
    where l.owner_id = v_uid and l.status = 'confirmed' and l.local_day >= v_prev_start and l.local_day < v_start
    group by l.attribute
  ) t;
  select jsonb_object_agg(k.key, (v_xp ->> k.key)::bigint - (v_prev_xp ->> k.key)::bigint) into v_deltas
  from jsonb_each(private.zero_attributes()) k;

  -- Top activities by credited minutes (similarity keys, not titles).
  select coalesce(jsonb_agg(t.activity order by t.minutes desc, t.key), '[]'::jsonb) into v_top
  from (
    select c.similarity_key as key, sum(c.effective_minutes) as minutes,
           jsonb_build_object(
             'key', c.similarity_key,
             'category', min(c.category::text),
             'completions', count(*),
             'minutes', sum(c.effective_minutes),
             'hours', round(sum(c.effective_minutes) / 60.0, 1),
             'xp', sum(c.total_xp)
           ) as activity
    from public.completions c
    where c.owner_id = v_uid and c.state = 'active' and c.evaluation_status = 'evaluated'
      and c.local_day >= v_start and c.local_day < v_end and not c.trivial
    group by c.similarity_key
    order by sum(c.effective_minutes) desc, c.similarity_key
    limit 5
  ) t;

  -- Records within the period.
  select jsonb_build_object('date', s.local_day, 'xp', s.total_xp, 'minutes', s.minutes) into v_best_day
  from public.day_stats s
  where s.owner_id = v_uid and s.local_day >= v_start and s.local_day < v_end and s.total_xp > 0
  order by s.total_xp desc, s.local_day
  limit 1;

  select jsonb_build_object('minutes', c.effective_minutes, 'hours', round(c.effective_minutes / 60.0, 1),
                            'key', c.similarity_key, 'date', c.local_day)
    into v_longest
  from public.completions c
  where c.owner_id = v_uid and c.state = 'active' and c.evaluation_status = 'evaluated'
    and c.local_day >= v_start and c.local_day < v_end and coalesce(c.effective_minutes, 0) > 0
  order by c.effective_minutes desc, c.completed_at
  limit 1;

  select coalesce(jsonb_agg(a.achievement_id order by a.unlocked_at), '[]'::jsonb) into v_achievements
  from public.achievements a
  join public.profiles p on p.id = a.owner_id
  where a.owner_id = v_uid
    and (a.unlocked_at at time zone p.time_zone)::date >= v_start
    and (a.unlocked_at at time zone p.time_zone)::date < v_end;

  select jsonb_build_object(
      'daily', count(*) filter (where q.tier = 'daily'),
      'contract', count(*) filter (where q.tier = 'contract'),
      'objective', count(*) filter (where q.tier = 'objective')
    ) into v_tiers
  from public.completions c
  join public.quests q on q.id = c.quest_id
  where c.owner_id = v_uid and c.state = 'active' and c.local_day >= v_start and c.local_day < v_end;

  select coalesce(sum(l.amount), 0) into v_xp_before_start from public.ledger_entries l
  where l.owner_id = v_uid and l.status = 'confirmed' and l.local_day < v_start;
  select coalesce(sum(l.amount), 0) into v_xp_before_end from public.ledger_entries l
  where l.owner_id = v_uid and l.status = 'confirmed' and l.local_day < v_end;

  return jsonb_build_object(
    'period', chronicle_facts.period,
    'periodStart', v_start,
    'periodEnd', v_end,
    'totals', v_current,
    'previous', v_previous,
    'xpByAttribute', v_xp,
    'previousXpByAttribute', v_prev_xp,
    'attributeDeltas', v_deltas,
    'topActivities', v_top,
    'records', jsonb_strip_nulls(jsonb_build_object('bestDay', v_best_day, 'longestSession', v_longest)),
    'achievementsUnlocked', v_achievements,
    'completionsByTier', v_tiers,
    'level', jsonb_build_object(
      'start', public.level_for_xp(v_xp_before_start),
      'end', public.level_for_xp(v_xp_before_end)
    )
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Privileges
-- ---------------------------------------------------------------------------

revoke execute on function public.apply_progression(uuid, jsonb, jsonb, text, text, jsonb) from public, anon, authenticated;
revoke execute on function public.get_day_state(uuid, date) from public, anon, authenticated;
revoke execute on function public.consume_ai_quota(uuid, text, integer) from public, anon, authenticated;
revoke execute on function public.count_similar_completions(uuid, uuid, text, uuid) from public, anon, authenticated;
revoke execute on function public.chronicle_facts(uuid, text, date) from public, anon, authenticated;
grant execute on function public.apply_progression(uuid, jsonb, jsonb, text, text, jsonb) to service_role;
grant execute on function public.get_day_state(uuid, date) to service_role;
grant execute on function public.consume_ai_quota(uuid, text, integer) to service_role;
grant execute on function public.count_similar_completions(uuid, uuid, text, uuid) to service_role;
grant execute on function public.chronicle_facts(uuid, text, date) to service_role;

revoke execute on function public.undo_completion(uuid) from public, anon;
revoke execute on function public.set_rest_day(date, boolean) from public, anon;
revoke execute on function public.update_character(text, text, text, boolean) from public, anon;
grant execute on function public.undo_completion(uuid) to authenticated;
grant execute on function public.set_rest_day(date, boolean) to authenticated;
grant execute on function public.update_character(text, text, text, boolean) to authenticated;
