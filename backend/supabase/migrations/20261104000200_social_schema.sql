-- =============================================================================
-- Oathbound · social schema
--
-- Guilds, membership, invites, the privacy-projected activity feed,
-- reactions, comments, collective challenges, safety (blocks, reports) and
-- notification settings. Clients never write feed_events or
-- challenge_contributions; those are produced by SECURITY DEFINER functions
-- (…_rpc_progression.sql) so a client bug cannot leak a private title.
-- =============================================================================

create type public.guild_role as enum ('guild_master', 'officer', 'member');

-- Fixed, meaningful reaction set (requirements G4).
create type public.reaction_kind as enum ('honour', 'steel', 'flame', 'laurel');

-- ---------------------------------------------------------------------------
-- guilds
-- ---------------------------------------------------------------------------

create table public.guilds (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  emblem text,
  visibility text not null default 'private',
  language_tag text,
  rules text not null default '',
  -- Set null when the owner's account is deleted; ownership is transferred
  -- first (see delete_my_account), so this is only a backstop.
  owner_id uuid references auth.users (id) on delete set null,
  member_limit integer not null default 50,
  -- Sharing level for members who have not chosen one for this guild.
  default_share_level public.share_level not null default 'completion_only',
  -- Minimum seconds between two comments by the same member (0 = off).
  slow_mode_seconds integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint guilds_name_length check (char_length(btrim(name)) between 2 and 60),
  constraint guilds_description_length check (char_length(description) <= 500),
  constraint guilds_rules_length check (char_length(rules) <= 2000),
  constraint guilds_emblem_length check (emblem is null or char_length(emblem) <= 200),
  constraint guilds_visibility check (visibility in ('private', 'public')),
  constraint guilds_language_tag check (language_tag is null or language_tag ~ '^[a-z]{2,3}(-[A-Za-z0-9]{2,8})*$'),
  constraint guilds_member_limit check (
    member_limit between 2 and 5000 and (visibility = 'public' or member_limit <= 50)
  ),
  constraint guilds_slow_mode check (slow_mode_seconds between 0 and 3600)
);

create index guilds_public_idx on public.guilds (created_at desc) where visibility = 'public';

create trigger guilds_touch
  before update on public.guilds
  for each row execute function private.touch_updated_at();

-- ---------------------------------------------------------------------------
-- guild_members (membership and per-guild preferences)
-- ---------------------------------------------------------------------------

create table public.guild_members (
  guild_id uuid not null references public.guilds (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role public.guild_role not null default 'member',
  -- The member's default sharing level for this guild (null = guild default).
  share_level public.share_level,
  -- Opt-in: private completions still count (anonymously) towards challenges.
  contribute_private boolean not null default false,
  -- Mutes notifications from this guild (the feed is unaffected).
  muted boolean not null default false,
  joined_at timestamptz not null default now(),
  primary key (guild_id, user_id)
);

create index guild_members_user_idx on public.guild_members (user_id);
create unique index guild_members_one_master on public.guild_members (guild_id)
  where role = 'guild_master';

-- ---------------------------------------------------------------------------
-- guild_invites (high-entropy codes, ≥ 40 bits; see private.generate_invite_code)
-- ---------------------------------------------------------------------------

create table public.guild_invites (
  code text primary key,
  guild_id uuid not null references public.guilds (id) on delete cascade,
  created_by uuid references auth.users (id) on delete set null,
  expires_at timestamptz not null,
  max_uses integer not null default 10,
  uses integer not null default 0,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  constraint guild_invites_code_format check (code ~ '^[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}-[0-9A-HJKMNP-TV-Z]{4}$'),
  constraint guild_invites_uses check (max_uses between 1 and 1000 and uses between 0 and max_uses)
);

create index guild_invites_guild_idx on public.guild_invites (guild_id);

-- ---------------------------------------------------------------------------
-- feed_events (privacy-projected activity; written only by definer functions)
-- ---------------------------------------------------------------------------

create table public.feed_events (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references public.guilds (id) on delete cascade,
  -- Null once the actor's account is deleted ("Former member").
  actor_id uuid references auth.users (id) on delete set null,
  kind text not null,
  -- Only the fields permitted by the actor's effective share level.
  payload jsonb not null default '{}'::jsonb,
  completion_id uuid,
  challenge_id uuid,
  hidden_at timestamptz,                     -- moderation (auto-hide or officer action)
  created_at timestamptz not null default now(),
  constraint feed_events_kind check (kind in (
    'completion', 'challenge_milestone', 'challenge_created', 'member_joined'
  )),
  constraint feed_events_payload_object check (jsonb_typeof(payload) = 'object')
);

create index feed_events_guild_idx on public.feed_events (guild_id, created_at desc);
create unique index feed_events_one_per_completion on public.feed_events (guild_id, completion_id)
  where kind = 'completion';
create index feed_events_completion_idx on public.feed_events (completion_id)
  where completion_id is not null;
create index feed_events_actor_idx on public.feed_events (actor_id);

-- ---------------------------------------------------------------------------
-- reactions and comments
-- ---------------------------------------------------------------------------

create table public.reactions (
  event_id uuid not null references public.feed_events (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  kind public.reaction_kind not null,
  created_at timestamptz not null default now(),
  primary key (event_id, user_id, kind)
);

create index reactions_user_idx on public.reactions (user_id);

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.feed_events (id) on delete cascade,
  guild_id uuid not null references public.guilds (id) on delete cascade,
  author_id uuid references auth.users (id) on delete set null,   -- null = "Former member"
  body text not null,
  created_at timestamptz not null default now(),
  edited_at timestamptz,
  deleted_at timestamptz,
  deleted_by uuid references auth.users (id) on delete set null,
  hidden_at timestamptz,
  constraint comments_body_length check (char_length(body) <= 1000)
);

create index comments_event_idx on public.comments (event_id, created_at);
create index comments_author_guild_idx on public.comments (author_id, guild_id, created_at desc);

-- ---------------------------------------------------------------------------
-- challenges and contributions (rules §10)
-- ---------------------------------------------------------------------------

create table public.challenges (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references public.guilds (id) on delete cascade,
  created_by uuid references auth.users (id) on delete set null,
  title text not null,
  description text not null default '',
  metric text not null,
  metric_category public.quest_category,
  metric_attribute public.attribute,
  target integer not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  progress bigint not null default 0,
  milestones_reached smallint not null default 0,   -- highest of 0/25/50/75/100
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint challenges_title_length check (char_length(btrim(title)) between 2 and 80),
  constraint challenges_description_length check (char_length(description) <= 500),
  constraint challenges_metric check (metric in ('minutes_in_category', 'completions', 'xp_in_attribute')),
  constraint challenges_metric_params check (
    (metric = 'minutes_in_category' and metric_category is not null and metric_attribute is null)
    or (metric = 'xp_in_attribute' and metric_attribute is not null and metric_category is null)
    or (metric = 'completions' and metric_attribute is null)
  ),
  constraint challenges_target check (target between 1 and 10000000),
  constraint challenges_window check (ends_at > starts_at and ends_at <= starts_at + interval '366 days'),
  constraint challenges_progress check (progress >= 0),
  constraint challenges_milestones check (milestones_reached in (0, 25, 50, 75, 100)),
  constraint challenges_status check (status in ('active', 'ended', 'cancelled'))
);

create index challenges_guild_idx on public.challenges (guild_id, ends_at desc);
create index challenges_active_idx on public.challenges (guild_id) where status = 'active';

create trigger challenges_touch
  before update on public.challenges
  for each row execute function private.touch_updated_at();

create table public.challenge_contributions (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.challenges (id) on delete cascade,
  -- Null for anonymous (opted-in private) contributions and after account deletion.
  user_id uuid references auth.users (id) on delete set null,
  completion_id uuid,                        -- no FK: totals survive account deletion
  amount integer not null,
  kind text not null default 'contribution',
  anonymous boolean not null default false,
  created_at timestamptz not null default now(),
  constraint challenge_contributions_kind check (kind in ('contribution', 'reversal')),
  constraint challenge_contributions_sign check (
    (kind = 'contribution' and amount > 0) or (kind = 'reversal' and amount < 0)
  ),
  unique (challenge_id, completion_id, kind)
);

create index challenge_contributions_challenge_idx on public.challenge_contributions (challenge_id);
create index challenge_contributions_completion_idx on public.challenge_contributions (completion_id);
create index challenge_contributions_user_idx on public.challenge_contributions (user_id);

-- ---------------------------------------------------------------------------
-- safety: blocks and reports
-- ---------------------------------------------------------------------------

create table public.blocks (
  blocker_id uuid not null references auth.users (id) on delete cascade,
  blocked_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint blocks_not_self check (blocker_id <> blocked_id)
);

create index blocks_blocked_idx on public.blocks (blocked_id);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references auth.users (id) on delete set null,
  target_type text not null,
  target_id uuid not null,
  guild_id uuid references public.guilds (id) on delete cascade,
  reason text not null,
  details text,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references auth.users (id) on delete set null,
  constraint reports_target_type check (target_type in ('feed_event', 'comment', 'guild', 'user')),
  constraint reports_reason check (reason in ('spam', 'harassment', 'hate', 'self_harm', 'sexual', 'violence', 'other')),
  constraint reports_details_length check (details is null or char_length(details) <= 1000),
  constraint reports_status check (status in ('open', 'reviewing', 'actioned', 'dismissed'))
);

create unique index reports_one_open_per_reporter
  on public.reports (reporter_id, target_type, target_id)
  where status in ('open', 'reviewing');
create index reports_target_idx on public.reports (target_type, target_id);
create index reports_queue_idx on public.reports (created_at) where status = 'open';

-- ---------------------------------------------------------------------------
-- notifications
-- ---------------------------------------------------------------------------

create table public.notification_prefs (
  user_id uuid primary key references auth.users (id) on delete cascade,
  -- Category toggles (requirements N1). Missing keys use these defaults.
  categories jsonb not null default '{
    "reminders": true,
    "guild_reactions": true,
    "guild_comments": true,
    "challenge_milestones": true,
    "objectives": true,
    "weekly_summary": true,
    "briefing": false
  }'::jsonb,
  quiet_hours_start time not null default '22:00',
  quiet_hours_end time not null default '08:00',
  daily_cap smallint not null default 5,
  updated_at timestamptz not null default now(),
  change_id bigint not null default 0,
  constraint notification_prefs_categories_object check (jsonb_typeof(categories) = 'object'),
  constraint notification_prefs_daily_cap check (daily_cap between 0 and 50)
);

create index notification_prefs_change_idx on public.notification_prefs (user_id, change_id);

create trigger notification_prefs_sync
  before insert or update on public.notification_prefs
  for each row execute function private.touch_sync_columns('user_id');

create table public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  token text not null unique,
  platform text not null,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  constraint push_tokens_platform check (platform in ('android', 'ios', 'macos', 'web', 'windows')),
  constraint push_tokens_token_length check (char_length(token) between 10 and 4096)
);

create index push_tokens_user_idx on public.push_tokens (user_id);

-- Delivery log: daily caps, reaction batching, 7-day re-engagement limit.
create table public.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  category text not null,
  template_key text not null,
  guild_id uuid references public.guilds (id) on delete set null,
  dedupe_key text,                           -- e.g. "reaction:<event_id>" for batching
  local_day date not null,
  status text not null,
  reason text,
  created_at timestamptz not null default now(),
  constraint notification_deliveries_status check (status in ('sent', 'suppressed', 'failed'))
);

create index notification_deliveries_user_day_idx on public.notification_deliveries (user_id, local_day);
create index notification_deliveries_dedupe_idx on public.notification_deliveries (user_id, dedupe_key, created_at desc)
  where dedupe_key is not null;

-- Comment rate limiting (30 per hour per user per guild) reads this table
-- through comments_author_guild_idx; no separate counter is needed.
