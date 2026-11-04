# Wyrd backend

Supabase project for Wyrd: Postgres schema with row-level security, the
sync and progression RPCs, the TypeScript twin of the progression engine and
three Edge Functions (AI evaluation, chronicles, push notifications).

Design background: [architecture overview](../docs/architecture/overview.md),
[ADR-002](../docs/architecture/adr/002-supabase-backend.md) (Supabase),
[ADR-003](../docs/architecture/adr/003-local-first-sync.md) (sync),
[ADR-004](../docs/architecture/adr/004-dual-engine-conformance.md) (two engines),
[ADR-005](../docs/architecture/adr/005-ai-evaluation.md) (AI),
[ADR-007](../docs/architecture/adr/007-notifications.md) (notifications) and the
[progression rules](../docs/product/progression-rules.md).

```
backend/
├── package.json                 Node tooling only (tests, SQL validation)
├── scripts/validate-sql.mjs     Applies all migrations to PGlite + smoke checks
└── supabase/
    ├── config.toml              Local stack (auth: e-mail + magic link; Apple/Google off)
    ├── migrations/              Ordered SQL migrations (see below)
    └── functions/               Deno Edge Functions
        ├── deno.json / deno.lock
        ├── .env.example         Local secrets template
        ├── _shared/
        │   ├── engine/          TypeScript progression engine (+ conformance tests)
        │   ├── ai/              Claude client, prompts, schemas, output validation
        │   ├── i18n/            en.json, fa.json — server-rendered text
        │   └── …                auth, http/CORS, Supabase admin client, policy helpers
        ├── evaluate-completion/
        ├── generate-chronicle/
        └── notify/
```

## Prerequisites

| Tool | Version | Used for |
| --- | --- | --- |
| [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started) | 2.x | local stack, migrations, deploys |
| Docker | current | `supabase start` |
| Node.js | ≥ 23.6 (26 recommended) | engine tests, SQL validation (native TypeScript type stripping) |
| Deno | 2.x (optional) | type-checking functions; `npx deno@2` works without installing |

## Local development

All Supabase CLI commands run from `backend/` (the CLI looks for `./supabase`).

```bash
cd backend
supabase start                      # Postgres 17, Auth, Realtime, Storage, Studio, Inbucket
supabase status                     # prints API URL, anon key, service-role key
supabase db reset                   # re-applies every migration from scratch

cp supabase/functions/.env.example supabase/functions/.env   # then fill in
supabase functions serve --env-file supabase/functions/.env
```

Local URLs: API `http://127.0.0.1:54321`, Studio `http://127.0.0.1:54323`,
Inbucket (auth e-mails, magic links) `http://127.0.0.1:54324`.

Without `ANTHROPIC_API_KEY` everything still works: evaluations use the
deterministic heuristic and chronicles the localized template. Without
`FCM_SERVICE_ACCOUNT`, `notify` answers `{"sent": false, "reason": "push_not_configured"}`.

### Secrets (Edge Functions)

| Name | Required | Purpose |
| --- | --- | --- |
| `ANTHROPIC_API_KEY` | for AI | Claude API key (function secret only, never in the client) |
| `AI_EVALUATION_MODEL` | no | model for evaluate-completion, default `claude-opus-5-5` |
| `AI_CHRONICLE_MODEL` | no | model for generate-chronicle, default `claude-opus-5-5` |
| `AI_SERVER_FALLBACKS` | no | `off` disables the server-side refusal fallback (`fallbacks: "default"`) |
| `FCM_SERVICE_ACCOUNT` | for push | Google service-account JSON (raw or base64) with FCM permission |
| `INTERNAL_FUNCTION_SECRET` | no | alternative to the service-role key for internal callers (`x-internal-secret`) |

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected by Supabase. Hosted:

```bash
supabase secrets set ANTHROPIC_API_KEY=… AI_EVALUATION_MODEL=claude-opus-5-5 AI_CHRONICLE_MODEL=claude-opus-5-5
supabase secrets set FCM_SERVICE_ACCOUNT="$(base64 < firebase-service-account.json)"
```

### Scheduled jobs

`…_cron.sql` installs pg_cron jobs when the extension is available (it is on
hosted Supabase; the migration skips scheduling elsewhere):

| Job | Schedule (UTC) | Function |
| --- | --- | --- |
| `wyrd-monthly` | 05:00 on the 1st | `private.take_monthly_snapshots()`, `private.recompute_classes()` |
| `wyrd-chronicles` | 03:15 daily | `private.enqueue_weekly_chronicles()` (idempotent per user/week) |
| `wyrd-dispatch` | every 15 min | `private.dispatch_pending_chronicles()` → `generate-chronicle {mode:"pending"}` |
| `wyrd-hourly` | :07 hourly | `private.refresh_conditions()`, `private.end_challenges()` |
| `wyrd-retention` | 04:30 daily | `private.retention_cleanup()` |

The dispatch job uses pg_net and two Vault secrets (run once per project):

```sql
select vault.create_secret('https://<project-ref>.supabase.co', 'wyrd_project_url');
select vault.create_secret('<service-role key>', 'wyrd_service_role_key');
```

### Notification webhooks

`notify` accepts Supabase Database Webhook payloads. Create three webhooks
(Dashboard → Database → Webhooks), each **INSERT**, HTTP POST to
`https://<project-ref>.supabase.co/functions/v1/notify` with header
`Authorization: Bearer <service-role key>`: tables `reactions`, `comments`,
`feed_events` (milestones fan out to members). Other senders POST
`{ user_id, category, template_key, params, guild_id? }` directly.

## Flutter configuration

The app reads the backend location from compile-time defines; with none it
runs in local-only (guest/demo) mode.

```bash
flutter run \
  --dart-define=WYRD_ENV=local \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_ANON_KEY=<anon key from `supabase status`>
```

Android emulators reach the host at `http://10.0.2.2:54321`. Only the anon
key ever ships in the client; RLS and the RPCs below enforce everything.

## Tests and verification

```bash
cd backend
npm install                  # PGlite (dev only)
npm test                     # engine conformance vectors + heuristic + shared modules (Node)
npm run validate:sql         # all migrations on PGlite + RLS/sync/progression smoke checks
npm run check:functions      # deno check of every function and test (strict)
npm run lint:functions       # deno lint
npm run verify               # test + validate:sql + check:functions
```

The engine conformance test can also be run on its own from the repo root:

```bash
node --test backend/supabase/functions/_shared/engine/engine.test.ts
```

It loads `packages/wyrd_engine/test/vectors/reward_cases.json` and
`curves.json` — the same files the Dart engine tests use (ADR-004). Any rule
change must update both engines, bump `RULES_VERSION` and regenerate the
vectors (`dart run tool/generate_vectors.dart` in the Dart package).

`validate-sql.mjs` stubs only what Supabase provides (`auth.users`,
`auth.uid()` from the `request.jwt.claim.sub` GUC, the anon / authenticated /
service_role roles and Supabase's default grants) and drives
`apply_progression` with the real TypeScript engine. It does not exercise
pg_cron, pg_net, Vault, Realtime or Storage.

## Database

### Migrations

Applied in filename order; each file is self-contained so it can be reviewed
and committed separately.

| File | Contents |
| --- | --- |
| `20261104000100_core_schema.sql` | enums, sync sequence/trigger, profiles, characters, quests, subtasks, completions, evaluations, ledger_entries, achievements, day_stats, snapshots, chronicles, ai_usage; signup trigger |
| `20261104000200_social_schema.sql` | guilds, guild_members, guild_invites, feed_events, reactions, comments, challenges, challenge_contributions, blocks, reports, notification_prefs, push_tokens, notification_deliveries |
| `20261104000300_rls.sql` | RLS on every table, policies, column-level grants, membership/block helpers, Realtime publication |
| `20261104000400_rpc_sync.sql` | `sync_push`, `sync_pull` |
| `20261104000500_rpc_progression.sql` | curves, condition, `apply_progression`, `undo_completion`, day-state/quota/facts helpers |
| `20261104000600_rpc_social.sql` | guild, invite, role, reaction, comment, challenge, safety, export and deletion RPCs |
| `20261104000700_cron.sql` | job functions and pg_cron schedules |

New migrations: create with `supabase migration new <name>`; every new table
needs `enable row level security` and the revokes described at the top of
`…_rls.sql` (Supabase's default privileges re-grant new tables to `anon`).

### Access model

* Clients read their own rows; they write directly only `profiles` (settings
  columns), `quests` / `subtasks` (owner, no hard delete), `completions`
  (insert only), `notification_prefs` and `push_tokens`.
* `characters`, `ledger_entries`, `day_stats`, `evaluations`, `achievements`,
  `feed_events`, `challenge_contributions`, `snapshots`, `chronicles` are
  written only by SECURITY DEFINER functions or the service role.
* Guild data is visible to members; public guild metadata to signed-in users.
  Feed events, reactions and comments from users the viewer blocked are
  filtered out by RLS (FR-7); the blocked party cannot see the block.
* Feed payloads are projected at write time from the effective share level
  (quest override → member's per-guild level → guild default):
  `full` → title, total XP, attribute deltas · `title_only` → title ·
  `completion_only` → tier and category · `private` → no event.
  Trivial completions are not posted.

### Sync protocol (client ↔ server)

`sync_push(changes jsonb)` — up to 500 outbox entries, applied in order:

```json
[{ "entity": "quest", "op": "upsert", "id": "<uuid>",
   "hlc": "2026-11-04T08:00:00.000Z-0000-<node>",
   "payload": { "title": "…", "tier": "daily", "created_at": "…" } },
 { "entity": "completion", "op": "insert", "id": "<uuid>",
   "payload": { "quest_id": "<uuid>", "completed_at": "…", "declared_minutes": 90,
                "tracked_minutes": null, "occurrence_day": null } },
 { "entity": "completion", "op": "undo", "id": "<uuid>", "payload": { "undone_at": "…" } }]
```

Entities: `quest` and `subtask` (`upsert` / `delete` = tombstone), `completion`
(`insert`, `undo`), `provisional_ledger` (offline engine grants, kept for audit
and marked `superseded`). Quests and subtasks merge field by field: a field
changes only when the change's HLC is strictly newer than that field's
(`field_hlc`). HLC strings are compared byte-wise, so they must be fixed-width
and lexicographically ordered. The response lists each change as `applied`,
`ignored` (replay / older clock) or `rejected` with `reason`
(`forbidden`, `missing_reference` + `retryable: true`, `conflict`, `invalid`).
`completions.local_day` is always recomputed from `profiles.time_zone`.

`sync_pull(cursor bigint default 0, max_rows int default 1000)` returns
`{ cursor, has_more, server_time, changes: { profiles, characters, quests,
subtasks, completions, evaluations, ledger_entries, achievements, day_stats,
chronicles, notification_prefs } }`. Loop while `has_more`. Realtime events
on these tables are only a signal to pull.

### RPC reference (callable by signed-in users)

| Function | Notes |
| --- | --- |
| `undo_completion(completion_id)` | within 24 h; appends reversal entries, rolls back caches, removes the feed event |
| `set_rest_day(local_day, rest = true)` | ±7 days of today; returns the new condition |
| `update_character(name?, portrait?, equipped_title?, clear_title = false)` | title must be unlocked |
| `create_guild(name, description = '', visibility = 'private', language_tag?, emblem?, default_share_level = 'completion_only')` | caller becomes guild master |
| `create_invite(guild_id, expires_in_hours = 168, max_uses = 10)` / `revoke_invite(code)` | officers; codes are 12 Crockford base32 chars (60 bits) |
| `join_guild_by_code(code, share_level?)` | tolerant of case, spaces, O/0 and I/L/1 |
| `leave_guild(guild_id)` | a leaving master hands over; an empty guild is dissolved |
| `set_member_role(guild_id, user_id, role)` | guild master only; promoting to master transfers mastery |
| `remove_member(guild_id, user_id)` | master: anyone but self; officer: members |
| `guild_roster(guild_id)` | display data of co-members |
| `my_guilds()` | the caller's guilds with their own sharing / mute preferences (co-members cannot read these) |
| `react(event_id, kind)` / `unreact(event_id, kind)` | kinds: `honour`, `steel`, `flame`, `laurel` |
| `add_comment(event_id, body)` / `delete_comment(comment_id)` | 1–1000 chars; 30 per hour per guild; slow mode |
| `create_challenge(guild_id, title, metric, target, ends_at, starts_at = now(), description = '', metric_category?, metric_attribute?)` | officers; ≤ 5 active |
| `block_user(user_id)` / `unblock_user(user_id)` | |
| `report_content(target_type, target_id, reason, details?)` | public guilds auto-hide at 3 reporters |
| `register_push_token(token, platform)` | moves a device token to the current user |
| `export_my_data()` | all user-owned rows as JSON |
| `delete_my_account()` | anonymises authored guild content ("Former member"), then deletes the user |

Errors use SQLSTATE `42501` (forbidden), `22023` (invalid), `P0002` (not
found), `54000` (limit) with a machine code in the error `hint`.

Service-role only: `apply_progression`, `get_day_state`, `consume_ai_quota`,
`count_similar_completions`, `chronicle_facts`.

## Edge Functions

### `evaluate-completion`

`POST { "completion_id": "<uuid>", "client_proposal"?: {…}, "client_model"?: "<name>" }`
with the user's access token. `client_proposal` is a proposal the app obtained from the
user's own AI provider (bring your own key; the server never sees that key). It is validated
like model output and bounded by the server heuristic (difficulty ±1, estimate ≤ 2× the
heuristic's, min 15 min); it needs no server AI key and uses no server quota.
Returns `{ status, result, proposal, source, character, achievements }`
(`result` is the engine's RewardResult JSON, identical in shape to the Dart
engine's). Steps: ownership check → minimised inputs (title, notes ≤ 1 000
chars, tier, category hint, minutes, parent title, AI language, similar count)
→ 7-day proposal cache → Claude with structured output (`output_config.format`,
effort `low`, cached system prompt, 8 s timeout, one SDK retry, server-side
refusal fallback) → strict schema validation → TypeScript engine →
`apply_progression` (idempotent; recomputed if the day state changed
concurrently). Any AI failure, refusal, invalid output, user opt-out
(`profiles.ai_evaluation_enabled = false`) or the 120/day limit uses the
heuristic evaluator, recorded in `evaluations.fallback_reason`.
404 `completion_not_found` means "push the completion first".

### `generate-chronicle`

`POST { "period": "week" | "month" | "year", "period_start": "YYYY-MM-DD", "force"?: true }`
with the user's token, or `{ "mode": "pending" }` with the service role.
Facts come from `chronicle_facts` (SQL); Claude (effort `medium`) may only
narrate them in the user's AI language (120–220 words, second person, no
judgement or generic motivation). Text with numbers that are not in the facts
or of the wrong length is rejected in favour of the deterministic English /
Persian template. Body and facts are stored in `chronicles`.

### `notify`

Internal (service-role key or `INTERNAL_FUNCTION_SECRET`). Enforces category
toggles, per-guild mute, blocks, quiet hours in the user's time zone (default
22:00–08:00), the daily cap (default 5, reminders exempt), reaction batching
(30 min) and at most one re-engagement message per 7 days; renders
`_shared/i18n/<locale>.json`; sends through FCM HTTP v1; logs every decision
in `notification_deliveries`.

## Deployment

```bash
supabase link --project-ref <ref>
supabase db push
supabase functions deploy evaluate-completion generate-chronicle notify
```

Then set the secrets, the Vault entries and the notification webhooks above,
and enable e-mail confirmations and the Apple / Google providers in the
dashboard (Auth → Providers).
