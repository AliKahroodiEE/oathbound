-- =============================================================================
-- Oathbound · scheduled jobs (pg_cron) and their job functions
--
-- The job functions are plain SQL and can be run by hand or from any
-- scheduler. Scheduling is skipped (with a NOTICE) when pg_cron is not
-- available, e.g. in PGlite-based validation; pg_net + Vault are optional
-- and only used to wake the generate-chronicle Edge Function.
--
--   oathbound-monthly         05:00 UTC on the 1st  snapshots + emergent classes
--   oathbound-chronicles      03:15 UTC daily        enqueue last week's chronicles
--   oathbound-dispatch        every 15 minutes       drain pending chronicles (pg_net)
--   oathbound-hourly          minute 7 every hour    condition rollover, end challenges
--   oathbound-retention       04:30 UTC daily        retention cleanup
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Monthly snapshots (requirements C8) and emergent classes (rules §9.3)
-- ---------------------------------------------------------------------------

create or replace function private.take_monthly_snapshots(p_taken_on date default current_date)
returns integer
language plpgsql
set search_path = ''
as $$
declare
  v_count integer;
begin
  insert into public.snapshots (owner_id, taken_on, data)
  select c.owner_id, p_taken_on, jsonb_build_object(
    'level', c.level,
    'total_xp', c.total_xp,
    'attr_xp', c.attr_xp,
    'ranks', (
      select jsonb_object_agg(a.key, public.rank_for_xp(a.value::bigint))
      from jsonb_each_text(c.attr_xp) a
    ),
    'class_id', c.class_id,
    'equipped_title', c.equipped_title,
    'condition', c.condition
  )
  from public.characters c
  on conflict (owner_id, taken_on) do nothing;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- Twin of Classes.compute in recognition.dart. A character keeps its class
-- when the last 90 days hold no XP (growth is never erased).
create or replace function private.compute_class(p_xp jsonb, p_level integer)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  c_order constant text[] := array['strength', 'intelligence', 'discipline', 'creativity', 'vitality', 'social'];
  v_total numeric := 0;
  v_top text;
  v_top_share numeric := -1;
  v_present integer := 0;
  v_share numeric;
  v_attribute text;
begin
  if p_level < 5 then
    return null;
  end if;
  foreach v_attribute in array c_order loop
    v_total := v_total + greatest(coalesce((p_xp ->> v_attribute)::numeric, 0), 0);
  end loop;
  if v_total <= 0 then
    return null;
  end if;
  foreach v_attribute in array c_order loop
    v_share := greatest(coalesce((p_xp ->> v_attribute)::numeric, 0), 0) / v_total;
    if v_share > v_top_share then          -- strict: ties keep the earlier attribute
      v_top := v_attribute;
      v_top_share := v_share;
    end if;
    if v_share >= 0.10 then
      v_present := v_present + 1;
    end if;
  end loop;

  if v_top_share < 0.25 and v_present >= 5 then
    return 'explorer';
  end if;
  if coalesce((p_xp ->> 'intelligence')::numeric, 0) / v_total >= 0.25
     and coalesce((p_xp ->> 'discipline')::numeric, 0) / v_total >= 0.25 then
    return 'strategist';
  end if;
  if coalesce((p_xp ->> 'intelligence')::numeric, 0) / v_total >= 0.25
     and coalesce((p_xp ->> 'creativity')::numeric, 0) / v_total >= 0.25 then
    return 'arcanist';
  end if;
  return case v_top
    when 'intelligence' then 'scholar'
    when 'discipline' then 'warden'
    when 'creativity' then 'artisan'
    when 'strength' then 'vanguard'
    when 'social' then 'envoy'
    when 'vitality' then 'druid'
  end;
end;
$$;

create or replace function private.recompute_classes()
returns integer
language plpgsql
set search_path = ''
as $$
declare
  v_character record;
  v_class text;
  v_count integer := 0;
begin
  for v_character in
    select c.owner_id, c.level, c.class_id, (
      select coalesce(jsonb_object_agg(t.attribute, t.amount), '{}'::jsonb)
      from (
        select l.attribute::text as attribute, sum(l.amount) as amount
        from public.ledger_entries l
        where l.owner_id = c.owner_id and l.status = 'confirmed'
          and l.local_day >= private.user_today(c.owner_id) - 90
        group by l.attribute
      ) t
    ) as xp90
    from public.characters c
    where c.level >= 5
  loop
    v_class := private.compute_class(v_character.xp90, v_character.level);
    if v_class is not null and v_class is distinct from v_character.class_id then
      update public.characters c set class_id = v_class where c.owner_id = v_character.owner_id;
      v_count := v_count + 1;
    end if;
  end loop;
  return v_count;
end;
$$;

-- ---------------------------------------------------------------------------
-- Weekly chronicles
-- ---------------------------------------------------------------------------

-- ISO weekday the user's week starts on (rules §7.1): explicit setting,
-- else Saturday for fa / IR / AF, Sunday for US, Monday otherwise.
create or replace function private.week_start_dow(p_profile public.profiles)
returns integer
language sql
immutable
set search_path = ''
as $$
  select coalesce(
    p_profile.week_start::integer,
    case
      when p_profile.region in ('IR', 'AF') or p_profile.locale like 'fa%' then 6
      when p_profile.region = 'US' or p_profile.locale = 'en-US' then 7
      else 1
    end
  );
$$;

-- Enqueues the most recent completed week for every user who was active in
-- it. Idempotent (unique owner/period/period_start), so running daily is safe
-- across time zones.
create or replace function private.enqueue_weekly_chronicles()
returns integer
language plpgsql
set search_path = ''
as $$
declare
  v_count integer;
begin
  with weeks as (
    select p.id as owner_id,
           coalesce(p.ai_locale, p.locale) as locale,
           (t.today - ((extract(isodow from t.today)::integer - private.week_start_dow(p) + 7) % 7) - 7) as week_start
    from public.profiles p
    cross join lateral (select (now() at time zone p.time_zone)::date as today) t
  )
  insert into public.chronicles (owner_id, period, period_start, period_end, locale, status)
  select w.owner_id, 'week', w.week_start, w.week_start + 7, w.locale, 'pending'
  from weeks w
  where exists (
    select 1 from public.day_stats s
    where s.owner_id = w.owner_id and s.local_day >= w.week_start and s.local_day < w.week_start + 7
      and s.completions > 0
  )
  on conflict (owner_id, period, period_start) do nothing;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- Wakes generate-chronicle to drain pending rows. Requires pg_net and two
-- Vault secrets (see backend/README.md): oathbound_project_url and
-- oathbound_service_role_key. Without them it does nothing; pending rows
-- can also be drained by calling the function from any external scheduler.
create or replace function private.dispatch_pending_chronicles()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_key text;
begin
  if not exists (select 1 from public.chronicles c where c.status = 'pending' and c.attempts < 5) then
    return;
  end if;
  begin
    execute 'select decrypted_secret from vault.decrypted_secrets where name = $1'
      into v_url using 'oathbound_project_url';
    execute 'select decrypted_secret from vault.decrypted_secrets where name = $1'
      into v_key using 'oathbound_service_role_key';
    if v_url is null or v_key is null then
      raise notice 'chronicle dispatch: Vault secrets not configured';
      return;
    end if;
    execute 'select net.http_post(url := $1, body := $2, headers := $3, timeout_milliseconds := 60000)'
      using rtrim(v_url, '/') || '/functions/v1/generate-chronicle',
            jsonb_build_object('mode', 'pending', 'limit', 20),
            jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'Bearer ' || v_key);
  exception
    when undefined_table or undefined_function or invalid_schema_name then
      raise notice 'chronicle dispatch: pg_net/Vault unavailable (%)', sqlerrm;
  end;
end;
$$;

-- ---------------------------------------------------------------------------
-- Hourly: condition rollover and challenge endings
-- ---------------------------------------------------------------------------

-- Refreshes the condition cache for users whose local day just changed
-- (local hour 0), so yesterday's recovery/strain is folded in (rules §7.3).
create or replace function private.refresh_conditions()
returns integer
language plpgsql
set search_path = ''
as $$
declare
  v_count integer;
begin
  update public.characters c
  set condition = private.compute_condition(c.owner_id, (now() at time zone p.time_zone)::date)
  from public.profiles p
  where p.id = c.owner_id
    and extract(hour from now() at time zone p.time_zone) = 0
    and exists (select 1 from public.day_stats s where s.owner_id = c.owner_id);
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- Ends challenges one day after their window (grace for offline devices
-- that sync late). The result is recorded as a percentage, never a failure.
create or replace function private.end_challenges()
returns integer
language plpgsql
set search_path = ''
as $$
declare
  v_count integer;
begin
  update public.challenges ch set status = 'ended'
  where ch.status = 'active' and ch.ends_at + interval '1 day' < now();
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- ---------------------------------------------------------------------------
-- Retention
-- ---------------------------------------------------------------------------

create or replace function private.retention_cleanup()
returns jsonb
language plpgsql
set search_path = ''
as $$
declare
  v_deliveries integer;
  v_usage integer;
  v_invites integer;
  v_tokens integer;
  v_comments integer;
  v_reports integer;
  v_chronicles integer;
begin
  delete from public.notification_deliveries d where d.created_at < now() - interval '60 days';
  get diagnostics v_deliveries = row_count;

  delete from public.ai_usage u where u.usage_day < current_date - 90;
  get diagnostics v_usage = row_count;

  delete from public.guild_invites i
  where coalesce(i.revoked_at, i.expires_at) < now() - interval '30 days';
  get diagnostics v_invites = row_count;

  delete from public.push_tokens t where t.last_seen_at < now() - interval '270 days';
  get diagnostics v_tokens = row_count;

  -- Deleted comments keep their place in the thread but lose their text
  -- after a 30-day moderation window.
  update public.comments c set body = ''
  where c.deleted_at < now() - interval '30 days' and c.body <> '';
  get diagnostics v_comments = row_count;

  delete from public.reports r
  where r.status in ('actioned', 'dismissed') and r.resolved_at < now() - interval '365 days';
  get diagnostics v_reports = row_count;

  delete from public.chronicles c where c.status = 'failed' and c.updated_at < now() - interval '30 days';
  get diagnostics v_chronicles = row_count;

  return jsonb_build_object(
    'notification_deliveries', v_deliveries, 'ai_usage', v_usage, 'guild_invites', v_invites,
    'push_tokens', v_tokens, 'comment_bodies', v_comments, 'reports', v_reports,
    'failed_chronicles', v_chronicles
  );
end;
$$;

revoke execute on all functions in schema private from public;

-- ---------------------------------------------------------------------------
-- Schedules
-- ---------------------------------------------------------------------------

do $outer$
begin
  begin
    create extension if not exists pg_cron;
  exception when others then
    raise notice 'pg_cron is not available (%); scheduled jobs were not installed', sqlerrm;
    return;
  end;

  begin
    create extension if not exists pg_net with schema extensions;
  exception when others then
    raise notice 'pg_net is not available (%); chronicle dispatch will be a no-op', sqlerrm;
  end;

  perform cron.schedule('oathbound-monthly', '0 5 1 * *',
    $job$select private.take_monthly_snapshots(); select private.recompute_classes();$job$);
  perform cron.schedule('oathbound-chronicles', '15 3 * * *',
    $job$select private.enqueue_weekly_chronicles();$job$);
  perform cron.schedule('oathbound-dispatch', '*/15 * * * *',
    $job$select private.dispatch_pending_chronicles();$job$);
  perform cron.schedule('oathbound-hourly', '7 * * * *',
    $job$select private.refresh_conditions(); select private.end_challenges();$job$);
  perform cron.schedule('oathbound-retention', '30 4 * * *',
    $job$select private.retention_cleanup();$job$);
end;
$outer$;
