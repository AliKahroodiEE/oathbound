-- =============================================================================
-- Oathbound · sync RPCs (ADR-003, overview §5)
--
-- sync_push(changes jsonb)  — applies the client outbox idempotently.
-- sync_pull(cursor bigint)  — returns the caller's rows changed after cursor.
--
-- Change envelope (one element of the `changes` array):
--   { "entity": "quest" | "subtask" | "completion" | "provisional_ledger",
--     "op":     "upsert" | "delete" | "insert" | "undo",
--     "id":     "<client uuid>",
--     "hlc":    "<hybrid logical clock>",
--     "payload": { …fields… } }
--
-- HLC strings are compared byte-wise (COLLATE "C"), so clients must emit a
-- fixed-width, lexicographically ordered encoding, e.g.
--   "<ISO-8601 UTC millis>-<4-digit hex counter>-<node id>"
--   "2026-11-04T08:00:00.000Z-0000-a1b2c3d4"
--
-- Conflict policy: quests and subtasks merge field by field — a field is
-- overwritten only by a strictly newer HLC (replays are no-ops). Deletes
-- are tombstones (`deleted_at`) and take part in the same per-field LWW.
-- Completions are insert-only (ON CONFLICT DO NOTHING); "undo" is a separate
-- op handled by private.undo_completion_internal (…_rpc_progression.sql).
-- =============================================================================

-- Field-level last-writer-wins merge of p_payload into p_current.
create or replace function private.lww_merge(
  p_current jsonb,
  p_field_hlc jsonb,
  p_payload jsonb,
  p_allowed text[],
  p_hlc text,
  out merged jsonb,
  out field_hlc jsonb,
  out changed boolean
)
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_key text;
begin
  merged := p_current;
  field_hlc := coalesce(p_field_hlc, '{}'::jsonb);
  changed := false;
  for v_key in select jsonb_object_keys(p_payload) loop
    continue when not (v_key = any (p_allowed));
    if (field_hlc ->> v_key) is null
       or (p_hlc collate "C") > ((field_hlc ->> v_key) collate "C") then
      merged := jsonb_set(merged, array[v_key], p_payload -> v_key, true);
      field_hlc := jsonb_set(field_hlc, array[v_key], to_jsonb(p_hlc), true);
      changed := true;
    end if;
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- Per-entity appliers (return 'applied' or 'ignored'; raise on rejection)
-- ---------------------------------------------------------------------------

create or replace function private.sync_quest(
  p_uid uuid, p_id uuid, p_op text, p_hlc text, p_payload jsonb
)
returns text
language plpgsql
set search_path = ''
as $$
declare
  c_fields constant text[] := array[
    'parent_id', 'tier', 'title', 'notes', 'category', 'priority', 'status', 'due_at',
    'estimated_minutes', 'recurrence', 'intention', 'share_level', 'reminder_at', 'deleted_at'
  ];
  v_payload jsonb := p_payload;
  v_row public.quests;
  v_new public.quests;
  v_merge record;
  v_created timestamptz;
begin
  if p_op = 'delete' then
    v_payload := jsonb_build_object('deleted_at', coalesce(p_payload -> 'deleted_at', to_jsonb(now())));
  elsif p_op <> 'upsert' then
    raise exception 'unsupported op "%" for quest', p_op using errcode = '22023';
  end if;

  select * into v_row from public.quests q where q.id = p_id for update;

  if not found then
    if p_op = 'delete' then
      return 'ignored';                      -- tombstone for a quest the server never saw
    end if;
    v_created := least(coalesce((p_payload ->> 'created_at')::timestamptz, now()), now());
    select * into v_merge from private.lww_merge(
      jsonb_build_object(
        'id', p_id, 'owner_id', p_uid, 'tier', 'daily', 'priority', 0, 'status', 'active',
        'created_at', v_created, 'updated_at', now(), 'change_id', 0
      ),
      '{}'::jsonb, v_payload, c_fields, p_hlc
    );
    v_new := jsonb_populate_record(
      null::public.quests,
      v_merge.merged || jsonb_build_object('hlc', p_hlc, 'field_hlc', v_merge.field_hlc)
    );
    insert into public.quests values (v_new.*);
    return 'applied';
  end if;

  if v_row.owner_id <> p_uid then
    raise exception 'quest belongs to another user' using errcode = '42501';
  end if;

  select * into v_merge from private.lww_merge(to_jsonb(v_row), v_row.field_hlc, v_payload, c_fields, p_hlc);
  if not v_merge.changed then
    return 'ignored';
  end if;
  v_new := jsonb_populate_record(null::public.quests, v_merge.merged);
  update public.quests q set
    parent_id = v_new.parent_id,
    tier = v_new.tier,
    title = v_new.title,
    notes = v_new.notes,
    category = v_new.category,
    priority = v_new.priority,
    status = v_new.status,
    due_at = v_new.due_at,
    estimated_minutes = v_new.estimated_minutes,
    recurrence = v_new.recurrence,
    intention = v_new.intention,
    share_level = v_new.share_level,
    reminder_at = v_new.reminder_at,
    deleted_at = v_new.deleted_at,
    hlc = greatest(q.hlc collate "C", p_hlc collate "C"),
    field_hlc = v_merge.field_hlc
  where q.id = p_id;
  return 'applied';
end;
$$;

create or replace function private.sync_subtask(
  p_uid uuid, p_id uuid, p_op text, p_hlc text, p_payload jsonb
)
returns text
language plpgsql
set search_path = ''
as $$
declare
  c_fields constant text[] := array['title', 'done', 'position', 'deleted_at'];
  v_payload jsonb := p_payload;
  v_row public.subtasks;
  v_new public.subtasks;
  v_merge record;
begin
  if p_op = 'delete' then
    v_payload := jsonb_build_object('deleted_at', coalesce(p_payload -> 'deleted_at', to_jsonb(now())));
  elsif p_op <> 'upsert' then
    raise exception 'unsupported op "%" for subtask', p_op using errcode = '22023';
  end if;

  select * into v_row from public.subtasks s where s.id = p_id for update;

  if not found then
    if p_op = 'delete' then
      return 'ignored';
    end if;
    select * into v_merge from private.lww_merge(
      jsonb_build_object(
        'id', p_id, 'owner_id', p_uid, 'quest_id', p_payload -> 'quest_id',
        'done', false, 'position', 0,
        'created_at', least(coalesce((p_payload ->> 'created_at')::timestamptz, now()), now()),
        'updated_at', now(), 'change_id', 0
      ),
      '{}'::jsonb, v_payload, c_fields, p_hlc
    );
    v_new := jsonb_populate_record(
      null::public.subtasks,
      v_merge.merged || jsonb_build_object('hlc', p_hlc, 'field_hlc', v_merge.field_hlc)
    );
    insert into public.subtasks values (v_new.*);
    return 'applied';
  end if;

  if v_row.owner_id <> p_uid then
    raise exception 'subtask belongs to another user' using errcode = '42501';
  end if;

  select * into v_merge from private.lww_merge(to_jsonb(v_row), v_row.field_hlc, v_payload, c_fields, p_hlc);
  if not v_merge.changed then
    return 'ignored';
  end if;
  v_new := jsonb_populate_record(null::public.subtasks, v_merge.merged);
  update public.subtasks s set
    title = v_new.title,
    done = v_new.done,
    position = v_new.position,
    deleted_at = v_new.deleted_at,
    hlc = greatest(s.hlc collate "C", p_hlc collate "C"),
    field_hlc = v_merge.field_hlc
  where s.id = p_id;
  return 'applied';
end;
$$;

-- Insert-only; replays of a known id are no-ops (FR-1).
create or replace function private.sync_completion(
  p_uid uuid, p_id uuid, p_hlc text, p_payload jsonb
)
returns text
language plpgsql
set search_path = ''
as $$
declare
  v_owner uuid;
  v_inserted integer;
begin
  select c.owner_id into v_owner from public.completions c where c.id = p_id;
  if found then
    if v_owner <> p_uid then
      raise exception 'completion belongs to another user' using errcode = '42501';
    end if;
    return 'ignored';
  end if;

  insert into public.completions (
    id, quest_id, owner_id, occurrence_day, completed_at,
    declared_minutes, tracked_minutes, local_day, hlc
  )
  values (
    p_id,
    (p_payload ->> 'quest_id')::uuid,
    p_uid,
    (p_payload ->> 'occurrence_day')::date,
    coalesce((p_payload ->> 'completed_at')::timestamptz, now()),
    round((p_payload ->> 'declared_minutes')::numeric)::integer,
    round((p_payload ->> 'tracked_minutes')::numeric)::integer,
    current_date,                            -- replaced by completions_guard
    p_hlc
  )
  on conflict (id) do nothing;
  get diagnostics v_inserted = row_count;
  return case when v_inserted = 1 then 'applied' else 'ignored' end;
end;
$$;

-- Offline (provisional) engine results, kept for audit and superseded by
-- the server result for the same completion (rules §11). They never count
-- towards caches.
create or replace function private.sync_provisional_ledger(
  p_uid uuid, p_id uuid, p_payload jsonb
)
returns text
language plpgsql
set search_path = ''
as $$
declare
  v_completion public.completions;
  v_status text := 'provisional';
  v_inserted integer;
begin
  select * into v_completion from public.completions c
  where c.id = (p_payload ->> 'completion_id')::uuid;
  if not found then
    raise exception 'completion % not found', p_payload ->> 'completion_id' using errcode = '23503';
  end if;
  if v_completion.owner_id <> p_uid then
    raise exception 'completion belongs to another user' using errcode = '42501';
  end if;
  if v_completion.evaluation_status = 'evaluated' or v_completion.state = 'undone' then
    v_status := 'superseded';
  end if;

  insert into public.ledger_entries (
    id, owner_id, completion_id, attribute, amount, raw_amount, kind, status,
    rule_version, adjustments, source, similarity_key, local_day
  )
  values (
    p_id,
    p_uid,
    v_completion.id,
    (p_payload ->> 'attribute')::public.attribute,
    greatest(0, round((p_payload ->> 'amount')::numeric)::integer),
    greatest(0, round((p_payload ->> 'raw_amount')::numeric)::integer),
    'grant',
    v_status,
    coalesce(p_payload ->> 'rule_version', 'unknown'),
    case when jsonb_typeof(p_payload -> 'adjustments') = 'array' then p_payload -> 'adjustments' else '[]'::jsonb end,
    case when p_payload ->> 'source' in ('ai', 'heuristic') then p_payload ->> 'source' else 'heuristic' end,
    left(p_payload ->> 'similarity_key', 48),
    v_completion.local_day
  )
  on conflict (id) do nothing;
  get diagnostics v_inserted = row_count;
  return case when v_inserted = 1 then 'applied' else 'ignored' end;
end;
$$;

-- ---------------------------------------------------------------------------
-- sync_push
-- ---------------------------------------------------------------------------

-- Applies up to 500 outbox changes in order. Each change succeeds or fails
-- on its own (sub-transaction); the response lists every change with
-- status 'applied' | 'ignored' (already known / older HLC) | 'rejected'.
-- Rejected changes carry `reason`; `retryable: true` means "push again after
-- the referenced row has been synced" (e.g. a parent quest).
create or replace function public.sync_push(changes jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_change jsonb;
  v_results jsonb := '[]'::jsonb;
  v_entity text;
  v_op text;
  v_id uuid;
  v_hlc text;
  v_payload jsonb;
  v_status text;
  v_reason text;
  v_detail text;
  v_retryable boolean;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  if changes is null or jsonb_typeof(changes) <> 'array' then
    raise exception 'changes must be a JSON array' using errcode = '22023';
  end if;
  if jsonb_array_length(changes) > 500 then
    raise exception 'at most 500 changes per push' using errcode = '54000';
  end if;

  for v_change in select value from jsonb_array_elements(changes) loop
    v_entity := v_change ->> 'entity';
    v_op := coalesce(v_change ->> 'op', 'upsert');
    v_hlc := coalesce(v_change ->> 'hlc', '');
    v_payload := case when jsonb_typeof(v_change -> 'payload') = 'object'
                      then v_change -> 'payload' else '{}'::jsonb end;
    v_status := null;
    v_reason := null;
    v_detail := null;
    v_retryable := false;
    begin
      v_id := (v_change ->> 'id')::uuid;
      if v_id is null then
        raise exception 'id is required' using errcode = '22023';
      end if;
      case v_entity
        when 'quest' then
          if v_hlc = '' then raise exception 'hlc is required' using errcode = '22023'; end if;
          v_status := private.sync_quest(v_uid, v_id, v_op, v_hlc, v_payload);
        when 'subtask' then
          if v_hlc = '' then raise exception 'hlc is required' using errcode = '22023'; end if;
          v_status := private.sync_subtask(v_uid, v_id, v_op, v_hlc, v_payload);
        when 'completion' then
          if v_op in ('insert', 'upsert') then
            v_status := private.sync_completion(v_uid, v_id, v_hlc, v_payload);
          elsif v_op = 'undo' then
            v_status := case private.undo_completion_internal(
                v_id, v_uid, least(coalesce((v_payload ->> 'undone_at')::timestamptz, now()), now())
              ) ->> 'status'
              when 'undone' then 'applied' else 'ignored' end;
          else
            raise exception 'unsupported op "%" for completion', v_op using errcode = '22023';
          end if;
        when 'provisional_ledger' then
          v_status := private.sync_provisional_ledger(v_uid, v_id, v_payload);
        else
          raise exception 'unknown entity "%"', coalesce(v_entity, 'null') using errcode = '22023';
      end case;
    exception
      when insufficient_privilege then
        v_status := 'rejected'; v_reason := 'forbidden';
      when foreign_key_violation or no_data_found then
        v_status := 'rejected'; v_reason := 'missing_reference'; v_retryable := true;
        v_detail := sqlerrm;
      when unique_violation then
        v_status := 'rejected'; v_reason := 'conflict'; v_detail := sqlerrm;
      when others then
        v_status := 'rejected'; v_reason := 'invalid'; v_detail := sqlerrm;
    end;
    v_results := v_results || jsonb_strip_nulls(jsonb_build_object(
      'entity', v_entity,
      'id', v_change ->> 'id',
      'status', v_status,
      'reason', v_reason,
      'detail', v_detail,
      'retryable', case when v_status = 'rejected' then v_retryable end
    ));
  end loop;

  return jsonb_build_object('results', v_results, 'server_time', now());
end;
$$;

-- ---------------------------------------------------------------------------
-- sync_pull
-- ---------------------------------------------------------------------------

-- Returns every row owned by the caller with change_id > cursor, across all
-- pulled tables, oldest first, at most max_rows per call:
--   { "cursor": <new cursor>, "has_more": bool, "server_time": …,
--     "changes": { "quests": [...], "subtasks": [...], … } }
-- Clients loop while has_more. Tombstoned rows are included (deleted_at set).
create or replace function public.sync_pull("cursor" bigint default 0, max_rows integer default 1000)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_cursor bigint := greatest(coalesce(sync_pull."cursor", 0), 0);
  v_limit integer := least(greatest(coalesce(sync_pull.max_rows, 1000), 1), 5000);
  v_changes jsonb;
  v_next bigint;
  v_more boolean;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  with changed as (
    select 'profiles'::text as entity, t.change_id, to_jsonb(t) as row
      from public.profiles t where t.id = v_uid and t.change_id > v_cursor
    union all
    select 'characters', t.change_id, to_jsonb(t)
      from public.characters t where t.owner_id = v_uid and t.change_id > v_cursor
    union all
    select 'quests', t.change_id, to_jsonb(t)
      from public.quests t where t.owner_id = v_uid and t.change_id > v_cursor
    union all
    select 'subtasks', t.change_id, to_jsonb(t)
      from public.subtasks t where t.owner_id = v_uid and t.change_id > v_cursor
    union all
    select 'completions', t.change_id, to_jsonb(t)
      from public.completions t where t.owner_id = v_uid and t.change_id > v_cursor
    union all
    select 'evaluations', t.change_id, to_jsonb(t) - 'input_hash'
      from public.evaluations t where t.owner_id = v_uid and t.change_id > v_cursor
    union all
    select 'ledger_entries', t.change_id, to_jsonb(t)
      from public.ledger_entries t where t.owner_id = v_uid and t.change_id > v_cursor
    union all
    select 'achievements', t.change_id, to_jsonb(t)
      from public.achievements t where t.owner_id = v_uid and t.change_id > v_cursor
    union all
    select 'day_stats', t.change_id, to_jsonb(t)
      from public.day_stats t where t.owner_id = v_uid and t.change_id > v_cursor
    union all
    select 'chronicles', t.change_id, to_jsonb(t)
      from public.chronicles t where t.owner_id = v_uid and t.change_id > v_cursor
    union all
    select 'notification_prefs', t.change_id, to_jsonb(t)
      from public.notification_prefs t where t.user_id = v_uid and t.change_id > v_cursor
  ),
  page as (
    select c.entity, c.change_id, c.row from changed c order by c.change_id limit v_limit + 1
  ),
  ranked as (
    select p.*, row_number() over (order by p.change_id) as rn, count(*) over () as total
    from page p
  )
  select
    coalesce((
      select jsonb_object_agg(g.entity, g.rows)
      from (
        select r.entity, jsonb_agg(r.row order by r.change_id) as rows
        from ranked r where r.rn <= v_limit group by r.entity
      ) g
    ), '{}'::jsonb),
    coalesce((select max(r.change_id) from ranked r where r.rn <= v_limit), v_cursor),
    coalesce((select max(r.total) from ranked r), 0) > v_limit
  into v_changes, v_next, v_more;

  return jsonb_build_object(
    'cursor', v_next,
    'has_more', v_more,
    'server_time', now(),
    'changes', jsonb_build_object(
      'profiles', '[]'::jsonb, 'characters', '[]'::jsonb, 'quests', '[]'::jsonb,
      'subtasks', '[]'::jsonb, 'completions', '[]'::jsonb, 'evaluations', '[]'::jsonb,
      'ledger_entries', '[]'::jsonb, 'achievements', '[]'::jsonb, 'day_stats', '[]'::jsonb,
      'chronicles', '[]'::jsonb, 'notification_prefs', '[]'::jsonb
    ) || v_changes
  );
end;
$$;

revoke execute on function public.sync_push(jsonb) from public, anon;
revoke execute on function public.sync_pull(bigint, integer) from public, anon;
grant execute on function public.sync_push(jsonb) to authenticated;
grant execute on function public.sync_pull(bigint, integer) to authenticated;
