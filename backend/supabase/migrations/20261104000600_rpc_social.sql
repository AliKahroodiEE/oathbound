-- =============================================================================
-- Wyrd · social, safety and account RPCs
--
-- Every write to guild data goes through these SECURITY DEFINER functions,
-- which enforce the permission matrix (requirements G5):
--
--   action                          guild_master  officer  member
--   update guild settings               ✓           ✓
--   create / revoke invites             ✓           ✓
--   create challenges                   ✓           ✓
--   remove members                      ✓       members only
--   delete any comment                  ✓           ✓      own only
--   change roles / transfer mastery     ✓
--
-- Errors use SQLSTATE 42501 (forbidden), 22023 (invalid input), P0002 (not
-- found) and 54000 (rate limited); HINT carries a stable machine code.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Invite codes
-- ---------------------------------------------------------------------------

-- 12 Crockford base32 characters = 60 random bits (≥ 40 required), taken
-- from the fully random bytes of a v4 UUID (pg_strong_random under the hood).
create or replace function private.generate_invite_code()
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  c_alphabet constant text := '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  v_bytes bytea := uuid_send(gen_random_uuid());
  v_bits bigint := 0;
  v_code text := '';
  i integer;
begin
  -- Bytes 9–15 are random (56 bits); byte 7 is random too (5 more bits used).
  for i in 9..15 loop
    v_bits := (v_bits << 8) | get_byte(v_bytes, i);
  end loop;
  for i in 1..11 loop
    v_code := v_code || substr(c_alphabet, (v_bits & 31)::integer + 1, 1);
    v_bits := v_bits >> 5;
  end loop;
  v_code := v_code || substr(c_alphabet, (get_byte(v_bytes, 7) & 31) + 1, 1);
  return substr(v_code, 1, 4) || '-' || substr(v_code, 5, 4) || '-' || substr(v_code, 9, 4);
end;
$$;

-- Accepts codes typed by humans: any case, spaces or dashes, and the
-- Crockford confusables O→0, I/L→1.
create or replace function private.normalise_invite_code(p_code text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case when char_length(c) = 12
    then substr(c, 1, 4) || '-' || substr(c, 5, 4) || '-' || substr(c, 9, 4)
    else c end
  from (
    select translate(regexp_replace(upper(coalesce(p_code, '')), '[^0-9A-Z]', '', 'g'), 'OIL', '011') as c
  ) s;
$$;

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

create or replace function private.require_uid()
returns uuid
language plpgsql
stable
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '42501', hint = 'not_authenticated';
  end if;
  return v_uid;
end;
$$;

create or replace function private.member_role(p_guild_id uuid, p_user_id uuid)
returns public.guild_role
language sql
stable
set search_path = ''
as $$
  select m.role from public.guild_members m where m.guild_id = p_guild_id and m.user_id = p_user_id;
$$;

-- Removes a member; a leaving guild master hands over to the longest-serving
-- officer, else the longest-serving member; an empty guild is dissolved.
create or replace function private.leave_guild_internal(p_guild_id uuid, p_user_id uuid)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_role public.guild_role;
  v_successor uuid;
begin
  perform 1 from public.guilds g where g.id = p_guild_id for update;
  select m.role into v_role from public.guild_members m
  where m.guild_id = p_guild_id and m.user_id = p_user_id;
  if not found then
    raise exception 'not a member of this guild' using errcode = 'P0002', hint = 'not_member';
  end if;

  delete from public.guild_members m where m.guild_id = p_guild_id and m.user_id = p_user_id;

  if v_role = 'guild_master' then
    select m.user_id into v_successor from public.guild_members m
    where m.guild_id = p_guild_id
    order by (m.role = 'officer') desc, m.joined_at, m.user_id
    limit 1;
    if v_successor is null then
      delete from public.guilds g where g.id = p_guild_id;
    else
      update public.guild_members m set role = 'guild_master'
      where m.guild_id = p_guild_id and m.user_id = v_successor;
      update public.guilds g set owner_id = v_successor where g.id = p_guild_id;
    end if;
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Guilds and membership
-- ---------------------------------------------------------------------------

create or replace function public.create_guild(
  name text,
  description text default '',
  visibility text default 'private',
  language_tag text default null,
  emblem text default null,
  default_share_level public.share_level default 'completion_only'
)
returns public.guilds
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := private.require_uid();
  v_guild public.guilds;
begin
  if (select count(*) from public.guild_members m where m.user_id = v_uid and m.role = 'guild_master') >= 10 then
    raise exception 'you already lead 10 guilds' using errcode = '54000', hint = 'guild_limit';
  end if;
  if (select count(*) from public.guild_members m where m.user_id = v_uid) >= 50 then
    raise exception 'membership limit reached' using errcode = '54000', hint = 'membership_limit';
  end if;

  insert into public.guilds (
    name, description, visibility, language_tag, emblem, owner_id, member_limit, default_share_level
  )
  values (
    btrim(create_guild.name),
    coalesce(btrim(create_guild.description), ''),
    coalesce(create_guild.visibility, 'private'),
    create_guild.language_tag,
    create_guild.emblem,
    v_uid,
    case when coalesce(create_guild.visibility, 'private') = 'public' then 5000 else 50 end,
    coalesce(create_guild.default_share_level, 'completion_only')
  )
  returning * into v_guild;

  insert into public.guild_members (guild_id, user_id, role) values (v_guild.id, v_uid, 'guild_master');
  return v_guild;
end;
$$;

create or replace function public.create_invite(
  guild_id uuid, expires_in_hours integer default 168, max_uses integer default 10
)
returns public.guild_invites
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := private.require_uid();
  v_invite public.guild_invites;
  v_attempt integer := 0;
begin
  if coalesce(private.member_role(create_invite.guild_id, v_uid) in ('guild_master', 'officer'), false) is not true then
    raise exception 'only officers can create invites' using errcode = '42501', hint = 'forbidden';
  end if;
  if create_invite.expires_in_hours not between 1 and 24 * 30 then
    raise exception 'invites expire within 1 hour to 30 days' using errcode = '22023';
  end if;
  loop
    v_attempt := v_attempt + 1;
    begin
      insert into public.guild_invites (code, guild_id, created_by, expires_at, max_uses)
      values (
        private.generate_invite_code(), create_invite.guild_id, v_uid,
        now() + make_interval(hours => create_invite.expires_in_hours),
        create_invite.max_uses
      )
      returning * into v_invite;
      return v_invite;
    exception when unique_violation then
      if v_attempt >= 5 then
        raise;
      end if;
    end;
  end loop;
end;
$$;

create or replace function public.revoke_invite(code text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := private.require_uid();
  v_guild_id uuid;
begin
  select i.guild_id into v_guild_id from public.guild_invites i
  where i.code = private.normalise_invite_code(revoke_invite.code);
  if v_guild_id is null
     or coalesce(private.member_role(v_guild_id, v_uid) in ('guild_master', 'officer'), false) is not true then
    raise exception 'invite not found' using errcode = 'P0002', hint = 'invite_not_found';
  end if;
  update public.guild_invites i set revoked_at = now()
  where i.code = private.normalise_invite_code(revoke_invite.code) and i.revoked_at is null;
end;
$$;

create or replace function public.join_guild_by_code(
  code text, share_level public.share_level default null
)
returns public.guilds
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := private.require_uid();
  v_invite public.guild_invites;
  v_guild public.guilds;
  v_members integer;
begin
  select * into v_invite from public.guild_invites i
  where i.code = private.normalise_invite_code(join_guild_by_code.code)
  for update;
  -- One generic error for unknown, revoked, expired and used-up codes.
  if not found or v_invite.revoked_at is not null or v_invite.expires_at <= now()
     or v_invite.uses >= v_invite.max_uses then
    raise exception 'this invite is not valid' using errcode = 'P0002', hint = 'invite_invalid';
  end if;

  select * into v_guild from public.guilds g where g.id = v_invite.guild_id for update;

  if exists (select 1 from public.guild_members m where m.guild_id = v_guild.id and m.user_id = v_uid) then
    return v_guild;                          -- already a member: idempotent, no use consumed
  end if;
  if (select count(*) from public.guild_members m where m.user_id = v_uid) >= 50 then
    raise exception 'membership limit reached' using errcode = '54000', hint = 'membership_limit';
  end if;
  select count(*) into v_members from public.guild_members m where m.guild_id = v_guild.id;
  if v_members >= v_guild.member_limit then
    raise exception 'this guild is full' using errcode = '54000', hint = 'guild_full';
  end if;

  insert into public.guild_members (guild_id, user_id, role, share_level)
  values (v_guild.id, v_uid, 'member', join_guild_by_code.share_level);
  update public.guild_invites i set uses = i.uses + 1 where i.code = v_invite.code;
  insert into public.feed_events (guild_id, actor_id, kind, payload)
  values (v_guild.id, v_uid, 'member_joined', '{}'::jsonb);
  return v_guild;
end;
$$;

create or replace function public.leave_guild(guild_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.leave_guild_internal(leave_guild.guild_id, private.require_uid());
end;
$$;

-- Only the guild master changes roles. Promoting someone to guild_master
-- transfers mastery (the caller becomes an officer).
create or replace function public.set_member_role(guild_id uuid, user_id uuid, role public.guild_role)
returns void
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := private.require_uid();
  v_target_role public.guild_role;
begin
  perform 1 from public.guilds g where g.id = set_member_role.guild_id for update;
  if private.member_role(set_member_role.guild_id, v_uid) is distinct from 'guild_master' then
    raise exception 'only the guild master can change roles' using errcode = '42501', hint = 'forbidden';
  end if;
  if set_member_role.user_id = v_uid then
    raise exception 'transfer mastery by promoting another member' using errcode = '22023', hint = 'self_role_change';
  end if;
  v_target_role := private.member_role(set_member_role.guild_id, set_member_role.user_id);
  if v_target_role is null then
    raise exception 'not a member of this guild' using errcode = 'P0002', hint = 'not_member';
  end if;

  if set_member_role.role = 'guild_master' then
    update public.guild_members m set role = 'officer'
    where m.guild_id = set_member_role.guild_id and m.user_id = v_uid;
    update public.guilds g set owner_id = set_member_role.user_id where g.id = set_member_role.guild_id;
  end if;
  update public.guild_members m set role = set_member_role.role
  where m.guild_id = set_member_role.guild_id and m.user_id = set_member_role.user_id;
end;
$$;

create or replace function public.remove_member(guild_id uuid, user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := private.require_uid();
  v_role public.guild_role := private.member_role(remove_member.guild_id, v_uid);
  v_target_role public.guild_role := private.member_role(remove_member.guild_id, remove_member.user_id);
begin
  if v_target_role is null then
    raise exception 'not a member of this guild' using errcode = 'P0002', hint = 'not_member';
  end if;
  if remove_member.user_id = v_uid then
    raise exception 'use leave_guild to leave' using errcode = '22023', hint = 'use_leave';
  end if;
  if not (
    (v_role = 'guild_master' and v_target_role <> 'guild_master')
    or (v_role = 'officer' and v_target_role = 'member')
  ) then
    raise exception 'not allowed to remove this member' using errcode = '42501', hint = 'forbidden';
  end if;
  delete from public.guild_members m
  where m.guild_id = remove_member.guild_id and m.user_id = remove_member.user_id;
end;
$$;

-- The caller's guilds with their own per-guild preferences.
create or replace function public.my_guilds()
returns table (
  guild_id uuid,
  name text,
  emblem text,
  visibility text,
  language_tag text,
  default_share_level public.share_level,
  role public.guild_role,
  share_level public.share_level,
  effective_share_level public.share_level,
  contribute_private boolean,
  muted boolean,
  joined_at timestamptz,
  member_count integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := private.require_uid();
begin
  return query
    select g.id, g.name, g.emblem, g.visibility, g.language_tag, g.default_share_level,
           m.role, m.share_level, coalesce(m.share_level, g.default_share_level),
           m.contribute_private, m.muted, m.joined_at,
           (select count(*)::integer from public.guild_members x where x.guild_id = g.id)
    from public.guild_members m
    join public.guilds g on g.id = m.guild_id
    where m.user_id = v_uid
    order by m.joined_at;
end;
$$;

-- Display data of co-members only (profiles themselves stay owner-only).
create or replace function public.guild_roster(guild_id uuid)
returns table (
  user_id uuid,
  role public.guild_role,
  display_name text,
  handle text,
  character_name text,
  portrait text,
  level integer,
  equipped_title text,
  class_id text,
  joined_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  if not public.is_guild_member(guild_roster.guild_id) then
    raise exception 'not a member of this guild' using errcode = '42501', hint = 'forbidden';
  end if;
  return query
    select m.user_id, m.role, p.display_name, p.handle, c.name, c.portrait, c.level,
           c.equipped_title, c.class_id, m.joined_at
    from public.guild_members m
    left join public.profiles p on p.id = m.user_id
    left join public.characters c on c.owner_id = m.user_id
    where m.guild_id = guild_roster.guild_id
    order by m.role, m.joined_at;
end;
$$;

-- ---------------------------------------------------------------------------
-- Reactions and comments
-- ---------------------------------------------------------------------------

create or replace function private.visible_event(p_event_id uuid, p_user_id uuid)
returns public.feed_events
language plpgsql
stable
set search_path = ''
as $$
declare
  v_event public.feed_events;
begin
  select * into v_event from public.feed_events e
  where e.id = p_event_id and e.hidden_at is null
    and exists (select 1 from public.guild_members m where m.guild_id = e.guild_id and m.user_id = p_user_id)
    and not exists (select 1 from public.blocks b where b.blocker_id = p_user_id and b.blocked_id = e.actor_id);
  if not found then
    raise exception 'event not found' using errcode = 'P0002', hint = 'event_not_found';
  end if;
  return v_event;
end;
$$;

create or replace function public.react(event_id uuid, kind public.reaction_kind)
returns void
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := private.require_uid();
begin
  perform private.visible_event(react.event_id, v_uid);
  insert into public.reactions (event_id, user_id, kind)
  values (react.event_id, v_uid, react.kind)
  on conflict do nothing;
end;
$$;

create or replace function public.unreact(event_id uuid, kind public.reaction_kind)
returns void
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := private.require_uid();
begin
  delete from public.reactions r
  where r.event_id = unreact.event_id and r.user_id = v_uid and r.kind = unreact.kind;
end;
$$;

-- 30 comments per hour per user per guild; honours guild slow mode.
create or replace function public.add_comment(event_id uuid, body text)
returns public.comments
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := private.require_uid();
  v_event public.feed_events;
  v_body text := btrim(coalesce(add_comment.body, ''));
  v_slow_mode integer;
  v_last timestamptz;
  v_comment public.comments;
begin
  if char_length(v_body) not between 1 and 1000 then
    raise exception 'comments are 1–1000 characters' using errcode = '22023', hint = 'invalid_length';
  end if;
  v_event := private.visible_event(add_comment.event_id, v_uid);

  -- Serialise this member's comments in this guild so the limits hold.
  perform pg_advisory_xact_lock(hashtextextended('comment:' || v_uid::text || ':' || v_event.guild_id::text, 0));
  if (
    select count(*) from public.comments c
    where c.author_id = v_uid and c.guild_id = v_event.guild_id and c.created_at > now() - interval '1 hour'
  ) >= 30 then
    raise exception 'comment limit reached, try again later' using errcode = '54000', hint = 'rate_limited';
  end if;
  select g.slow_mode_seconds into v_slow_mode from public.guilds g where g.id = v_event.guild_id;
  if v_slow_mode > 0 then
    select max(c.created_at) into v_last from public.comments c
    where c.author_id = v_uid and c.guild_id = v_event.guild_id;
    if v_last is not null and v_last > now() - make_interval(secs => v_slow_mode) then
      raise exception 'slow mode is on in this guild' using errcode = '54000', hint = 'slow_mode';
    end if;
  end if;

  insert into public.comments (event_id, guild_id, author_id, body)
  values (v_event.id, v_event.guild_id, v_uid, v_body)
  returning * into v_comment;
  return v_comment;
end;
$$;

create or replace function public.delete_comment(comment_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := private.require_uid();
  v_comment public.comments;
begin
  select * into v_comment from public.comments c where c.id = delete_comment.comment_id and c.deleted_at is null;
  if not found or not (
    v_comment.author_id = v_uid
    or coalesce(private.member_role(v_comment.guild_id, v_uid) in ('guild_master', 'officer'), false)
  ) then
    raise exception 'comment not found' using errcode = 'P0002', hint = 'comment_not_found';
  end if;
  update public.comments c set deleted_at = now(), deleted_by = v_uid where c.id = v_comment.id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Challenges
-- ---------------------------------------------------------------------------

create or replace function public.create_challenge(
  guild_id uuid,
  title text,
  metric text,
  target integer,
  ends_at timestamptz,
  starts_at timestamptz default now(),
  description text default '',
  metric_category public.quest_category default null,
  metric_attribute public.attribute default null
)
returns public.challenges
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := private.require_uid();
  v_challenge public.challenges;
begin
  if coalesce(private.member_role(create_challenge.guild_id, v_uid) in ('guild_master', 'officer'), false) is not true then
    raise exception 'only officers can create challenges' using errcode = '42501', hint = 'forbidden';
  end if;
  if (select count(*) from public.challenges ch
      where ch.guild_id = create_challenge.guild_id and ch.status = 'active') >= 5 then
    raise exception 'a guild can run at most 5 challenges at once' using errcode = '54000', hint = 'challenge_limit';
  end if;
  if create_challenge.ends_at <= now() then
    raise exception 'the challenge must end in the future' using errcode = '22023';
  end if;

  insert into public.challenges (
    guild_id, created_by, title, description, metric, metric_category, metric_attribute,
    target, starts_at, ends_at
  )
  values (
    create_challenge.guild_id, v_uid, btrim(create_challenge.title),
    coalesce(btrim(create_challenge.description), ''), create_challenge.metric,
    create_challenge.metric_category, create_challenge.metric_attribute, create_challenge.target,
    greatest(coalesce(create_challenge.starts_at, now()), now() - interval '1 day'),
    create_challenge.ends_at
  )
  returning * into v_challenge;

  insert into public.feed_events (guild_id, actor_id, kind, payload, challenge_id)
  values (
    v_challenge.guild_id, v_uid, 'challenge_created',
    jsonb_build_object(
      'challenge_id', v_challenge.id, 'title', v_challenge.title, 'metric', v_challenge.metric,
      'metric_category', v_challenge.metric_category, 'metric_attribute', v_challenge.metric_attribute,
      'target', v_challenge.target, 'starts_at', v_challenge.starts_at, 'ends_at', v_challenge.ends_at
    ),
    v_challenge.id
  );
  return v_challenge;
end;
$$;

-- ---------------------------------------------------------------------------
-- Safety
-- ---------------------------------------------------------------------------

create or replace function public.block_user(user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := private.require_uid();
begin
  if block_user.user_id = v_uid then
    raise exception 'you cannot block yourself' using errcode = '22023';
  end if;
  insert into public.blocks (blocker_id, blocked_id) values (v_uid, block_user.user_id)
  on conflict do nothing;
end;
$$;

create or replace function public.unblock_user(user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  delete from public.blocks b
  where b.blocker_id = private.require_uid() and b.blocked_id = unblock_user.user_id;
end;
$$;

-- Files a report. In public guilds, content reported by 3 different members
-- is hidden automatically pending review (overview §6).
create or replace function public.report_content(
  target_type text, target_id uuid, reason text, details text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  c_auto_hide_threshold constant integer := 3;
  v_uid uuid := private.require_uid();
  v_guild_id uuid;
  v_visibility text;
  v_report_id uuid;
  v_reporters integer;
begin
  case report_content.target_type
    when 'feed_event' then
      v_guild_id := (private.visible_event(report_content.target_id, v_uid)).guild_id;
    when 'comment' then
      select c.guild_id into v_guild_id from public.comments c
      where c.id = report_content.target_id and c.deleted_at is null
        and public.is_guild_member(c.guild_id);
      if v_guild_id is null then
        raise exception 'comment not found' using errcode = 'P0002', hint = 'not_found';
      end if;
    when 'guild' then
      select g.id into v_guild_id from public.guilds g
      where g.id = report_content.target_id and (g.visibility = 'public' or public.is_guild_member(g.id));
      if v_guild_id is null then
        raise exception 'guild not found' using errcode = 'P0002', hint = 'not_found';
      end if;
    when 'user' then
      if report_content.target_id = v_uid then
        raise exception 'you cannot report yourself' using errcode = '22023';
      end if;
      v_guild_id := null;
    else
      raise exception 'unknown target type' using errcode = '22023';
  end case;

  insert into public.reports (reporter_id, target_type, target_id, guild_id, reason, details)
  values (v_uid, report_content.target_type, report_content.target_id, v_guild_id,
          report_content.reason, nullif(btrim(coalesce(report_content.details, '')), ''))
  on conflict (reporter_id, target_type, target_id) where status in ('open', 'reviewing') do nothing
  returning id into v_report_id;

  if v_guild_id is not null and report_content.target_type in ('feed_event', 'comment') then
    select g.visibility into v_visibility from public.guilds g where g.id = v_guild_id;
    if v_visibility = 'public' then
      select count(distinct r.reporter_id) into v_reporters from public.reports r
      where r.target_type = report_content.target_type and r.target_id = report_content.target_id
        and r.status in ('open', 'reviewing');
      if v_reporters >= c_auto_hide_threshold then
        if report_content.target_type = 'feed_event' then
          update public.feed_events e set hidden_at = coalesce(e.hidden_at, now()) where e.id = report_content.target_id;
        else
          update public.comments c set hidden_at = coalesce(c.hidden_at, now()) where c.id = report_content.target_id;
        end if;
      end if;
    end if;
  end if;

  return coalesce(v_report_id, (
    select r.id from public.reports r
    where r.reporter_id = v_uid and r.target_type = report_content.target_type
      and r.target_id = report_content.target_id and r.status in ('open', 'reviewing')
  ));
end;
$$;

-- ---------------------------------------------------------------------------
-- Push tokens (a device token moves to whoever signed in on it last)
-- ---------------------------------------------------------------------------

create or replace function public.register_push_token(token text, platform text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  v_uid uuid := private.require_uid();
begin
  delete from public.push_tokens t where t.token = register_push_token.token and t.user_id <> v_uid;
  insert into public.push_tokens (user_id, token, platform)
  values (v_uid, register_push_token.token, register_push_token.platform)
  on conflict (token) do update set last_seen_at = now(), platform = excluded.platform;
end;
$$;

-- ---------------------------------------------------------------------------
-- Data export and account deletion (requirements A4, overview §6)
-- ---------------------------------------------------------------------------

create or replace function public.export_my_data()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_uid();
begin
  return jsonb_build_object(
    'format', 'wyrd-export/1',
    'exported_at', now(),
    'user_id', v_uid,
    'profile', (select to_jsonb(p) from public.profiles p where p.id = v_uid),
    'character', (select to_jsonb(c) from public.characters c where c.owner_id = v_uid),
    'quests', coalesce((select jsonb_agg(to_jsonb(q) order by q.created_at)
                        from public.quests q where q.owner_id = v_uid), '[]'::jsonb),
    'subtasks', coalesce((select jsonb_agg(to_jsonb(s) order by s.created_at)
                          from public.subtasks s where s.owner_id = v_uid), '[]'::jsonb),
    'completions', coalesce((select jsonb_agg(to_jsonb(c) order by c.completed_at)
                             from public.completions c where c.owner_id = v_uid), '[]'::jsonb),
    'evaluations', coalesce((select jsonb_agg(to_jsonb(e) order by e.created_at)
                             from public.evaluations e where e.owner_id = v_uid), '[]'::jsonb),
    'ledger_entries', coalesce((select jsonb_agg(to_jsonb(l) order by l.created_at)
                                from public.ledger_entries l where l.owner_id = v_uid), '[]'::jsonb),
    'achievements', coalesce((select jsonb_agg(to_jsonb(a) order by a.unlocked_at)
                              from public.achievements a where a.owner_id = v_uid), '[]'::jsonb),
    'day_stats', coalesce((select jsonb_agg(to_jsonb(d) order by d.local_day)
                           from public.day_stats d where d.owner_id = v_uid), '[]'::jsonb),
    'snapshots', coalesce((select jsonb_agg(to_jsonb(s) order by s.taken_on)
                           from public.snapshots s where s.owner_id = v_uid), '[]'::jsonb),
    'chronicles', coalesce((select jsonb_agg(to_jsonb(c) order by c.period_start)
                            from public.chronicles c where c.owner_id = v_uid), '[]'::jsonb),
    'guild_memberships', coalesce((
      select jsonb_agg(jsonb_build_object(
        'guild_id', m.guild_id, 'guild_name', g.name, 'role', m.role, 'share_level', m.share_level,
        'contribute_private', m.contribute_private, 'muted', m.muted, 'joined_at', m.joined_at)
        order by m.joined_at)
      from public.guild_members m join public.guilds g on g.id = m.guild_id
      where m.user_id = v_uid), '[]'::jsonb),
    'feed_events', coalesce((select jsonb_agg(to_jsonb(e) order by e.created_at)
                             from public.feed_events e where e.actor_id = v_uid), '[]'::jsonb),
    'comments', coalesce((select jsonb_agg(to_jsonb(c) order by c.created_at)
                          from public.comments c where c.author_id = v_uid), '[]'::jsonb),
    'reactions', coalesce((select jsonb_agg(to_jsonb(r) order by r.created_at)
                           from public.reactions r where r.user_id = v_uid), '[]'::jsonb),
    'challenge_contributions', coalesce((
      select jsonb_agg(to_jsonb(cc) order by cc.created_at)
      from public.challenge_contributions cc
      where cc.user_id = v_uid
         or cc.completion_id in (select c.id from public.completions c where c.owner_id = v_uid)
    ), '[]'::jsonb),
    'challenges_created', coalesce((select jsonb_agg(to_jsonb(ch) order by ch.created_at)
                                    from public.challenges ch where ch.created_by = v_uid), '[]'::jsonb),
    'invites_created', coalesce((select jsonb_agg(to_jsonb(i) order by i.created_at)
                                 from public.guild_invites i where i.created_by = v_uid), '[]'::jsonb),
    'blocks', coalesce((select jsonb_agg(to_jsonb(b) order by b.created_at)
                        from public.blocks b where b.blocker_id = v_uid), '[]'::jsonb),
    'reports', coalesce((select jsonb_agg(to_jsonb(r) order by r.created_at)
                         from public.reports r where r.reporter_id = v_uid), '[]'::jsonb),
    'notification_prefs', (select to_jsonb(n) from public.notification_prefs n where n.user_id = v_uid),
    -- Device tokens are credentials for the push service; only metadata is exported.
    'push_devices', coalesce((
      select jsonb_agg(jsonb_build_object('platform', t.platform, 'created_at', t.created_at,
                                          'last_seen_at', t.last_seen_at) order by t.created_at)
      from public.push_tokens t where t.user_id = v_uid), '[]'::jsonb),
    'ai_usage', coalesce((select jsonb_agg(to_jsonb(u) order by u.usage_day)
                          from public.ai_usage u where u.owner_id = v_uid), '[]'::jsonb)
  );
end;
$$;

-- Anonymises authored guild content to "Former member" (actor/author null),
-- hands over guild mastery, removes personal activity from feeds, then
-- deletes the auth user; every personal table cascades from auth.users.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_uid();
  v_guild_id uuid;
begin
  for v_guild_id in
    select m.guild_id from public.guild_members m where m.user_id = v_uid and m.role = 'guild_master'
  loop
    perform private.leave_guild_internal(v_guild_id, v_uid);
  end loop;

  delete from public.feed_events e where e.actor_id = v_uid and e.kind = 'completion';
  update public.feed_events e set actor_id = null where e.actor_id = v_uid;
  update public.comments c set author_id = null where c.author_id = v_uid;
  update public.comments c set deleted_by = null where c.deleted_by = v_uid;
  update public.challenge_contributions cc set user_id = null, anonymous = true where cc.user_id = v_uid;
  update public.challenges ch set created_by = null where ch.created_by = v_uid;
  update public.guild_invites i set created_by = null where i.created_by = v_uid;
  update public.reports r set reporter_id = null where r.reporter_id = v_uid;
  update public.reports r set resolved_by = null where r.resolved_by = v_uid;
  update public.guilds g set owner_id = null where g.owner_id = v_uid;

  delete from auth.users u where u.id = v_uid;
end;
$$;

-- ---------------------------------------------------------------------------
-- Privileges: callable by signed-in users only
-- ---------------------------------------------------------------------------

do $$
declare
  v_signature text;
begin
  foreach v_signature in array array[
    'public.create_guild(text, text, text, text, text, public.share_level)',
    'public.create_invite(uuid, integer, integer)',
    'public.revoke_invite(text)',
    'public.join_guild_by_code(text, public.share_level)',
    'public.leave_guild(uuid)',
    'public.set_member_role(uuid, uuid, public.guild_role)',
    'public.remove_member(uuid, uuid)',
    'public.guild_roster(uuid)',
    'public.my_guilds()',
    'public.react(uuid, public.reaction_kind)',
    'public.unreact(uuid, public.reaction_kind)',
    'public.add_comment(uuid, text)',
    'public.delete_comment(uuid)',
    'public.create_challenge(uuid, text, text, integer, timestamptz, timestamptz, text, public.quest_category, public.attribute)',
    'public.block_user(uuid)',
    'public.unblock_user(uuid)',
    'public.report_content(text, uuid, text, text)',
    'public.register_push_token(text, text)',
    'public.export_my_data()',
    'public.delete_my_account()'
  ] loop
    execute format('revoke execute on function %s from public, anon', v_signature);
    execute format('grant execute on function %s to authenticated', v_signature);
  end loop;
end;
$$;
