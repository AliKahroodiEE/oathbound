#!/usr/bin/env node
/**
 * Offline validation of the Supabase migrations with PGlite (Postgres 17 in
 * WebAssembly). No Docker or Supabase CLI required:
 *
 *   cd backend && npm install && npm run validate:sql
 *
 * 1. Creates a stub of what the Supabase platform provides: `auth.users`,
 *    `auth.uid()` reading the `request.jwt.claim.sub` GUC, the roles anon /
 *    authenticated / service_role (BYPASSRLS) and Supabase's default grants.
 * 2. Applies every file in supabase/migrations/ in order. pg_cron / pg_net
 *    do not exist in PGlite; the cron migration skips scheduling itself.
 * 3. Runs smoke checks as the real roles: RLS isolation, sync_push LWW and
 *    idempotency, sync_pull cursors, apply_progression driven by the real
 *    TypeScript engine (idempotency, stale-day protection, privacy
 *    projection, challenges), undo, social RPCs, export/deletion, cron jobs.
 *
 * Exit code 0 means every migration applied and every check passed.
 */
import { readdirSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { PGlite } from '@electric-sql/pglite';

import * as engine from '../supabase/functions/_shared/engine/index.ts';

const MIGRATIONS = fileURLToPath(new URL('../supabase/migrations/', import.meta.url));
const CURVES = JSON.parse(
  readFileSync(
    new URL('../../packages/oathbound_engine/test/vectors/curves.json', import.meta.url),
    'utf8',
  ),
);

const SUPABASE_STUB = /* sql */ `
  create role anon nologin noinherit;
  create role authenticated nologin noinherit;
  create role service_role nologin noinherit bypassrls;

  create schema auth;
  create table auth.users (
    id uuid primary key,
    email text,
    raw_user_meta_data jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
  );
  create function auth.uid() returns uuid language sql stable as $$
    select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
  $$;
  grant usage on schema auth to anon, authenticated, service_role;
  grant execute on all functions in schema auth to anon, authenticated, service_role;

  -- Supabase's default privileges on the public schema.
  grant usage on schema public to anon, authenticated, service_role;
  alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
  alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;
  alter default privileges in schema public grant execute on functions to anon, authenticated, service_role;
`;

// ---------------------------------------------------------------------------
// Tiny test harness
// ---------------------------------------------------------------------------

const results = [];

function check(name, ok, detail = '') {
  results.push({ name, ok: Boolean(ok), detail });
  console.log(`${ok ? '  ok  ' : '  FAIL'} ${name}${detail ? ` — ${detail}` : ''}`);
}

/** Runs `fn(tx)` in a transaction as `role`, with auth.uid() = `uid`. */
function as(db, role, uid, fn) {
  return db.transaction(async (tx) => {
    await tx.exec(`set local role ${role};`);
    await tx.query(`select set_config('request.jwt.claim.sub', $1, true)`, [uid ?? '']);
    return fn(tx);
  });
}

async function one(db, role, uid, sql, params = []) {
  const res = await as(db, role, uid, (tx) => tx.query(sql, params));
  return res.rows[0];
}

async function rows(db, role, uid, sql, params = []) {
  const res = await as(db, role, uid, (tx) => tx.query(sql, params));
  return res.rows;
}

async function expectError(name, promise, pattern) {
  try {
    await promise;
    check(name, false, 'expected an error but the statement succeeded');
  } catch (error) {
    const message = String(error?.message ?? error);
    const ok = pattern === undefined || pattern.test(message);
    check(name, ok, ok ? `rejected (${message})` : `unexpected error: ${message}`);
  }
}

// ---------------------------------------------------------------------------
// Migrations
// ---------------------------------------------------------------------------

async function applyMigrations(db) {
  const files = readdirSync(MIGRATIONS).filter((f) => f.endsWith('.sql')).sort();
  for (const file of files) {
    const sql = readFileSync(MIGRATIONS + file, 'utf8');
    try {
      await db.exec(sql);
      check(`migration ${file}`, true);
    } catch (error) {
      const position = Number(error.position);
      let context = '';
      if (Number.isFinite(position) && position > 0) {
        const line = sql.slice(0, position).split('\n').length;
        context = ` (line ${line}: ${sql.split('\n')[line - 1]?.trim()})`;
      }
      check(`migration ${file}`, false, `${error.message}${context}`);
      throw error;
    }
  }
}

// ---------------------------------------------------------------------------
// Smoke checks
// ---------------------------------------------------------------------------

const A = '00000000-0000-4000-8000-00000000000a';
const B = '00000000-0000-4000-8000-00000000000b';
const C = '00000000-0000-4000-8000-00000000000c';
const OBJECTIVE = '10000000-0000-4000-8000-000000000001';
const QUEST = '10000000-0000-4000-8000-000000000002';
const QUEST_FULL = '10000000-0000-4000-8000-000000000003';
const SUBTASK = '20000000-0000-4000-8000-000000000001';
const DONE_1 = '30000000-0000-4000-8000-000000000001';
const DONE_2 = '30000000-0000-4000-8000-000000000002';
const DONE_3 = '30000000-0000-4000-8000-000000000003';
const DONE_DUP = '30000000-0000-4000-8000-000000000004';
const PROVISIONAL = '40000000-0000-4000-8000-000000000001';

const hlc = (ms, counter = 0, node = 'devA') =>
  `${new Date(ms).toISOString()}-${counter.toString(16).padStart(4, '0')}-${node}`;

/** Server-side flow of evaluate-completion, minus the AI call. */
async function evaluateAndApply(db, completionId, { staleDayChangeId } = {}) {
  const c = await one(db, 'service_role', null, `
    select c.*, q.title, q.notes, q.tier, q.category as quest_category, q.created_at as quest_created_at,
           q.due_at, q.recurrence, q.intention, q.estimated_minutes
    from public.completions c join public.quests q on q.id = c.quest_id where c.id = $1`, [completionId]);
  const proposal = engine.evaluateHeuristic({
    title: c.title,
    notes: c.notes ?? '',
    tier: c.tier,
    categoryHint: c.quest_category,
    declaredMinutes: c.declared_minutes,
    estimatedMinutes: c.estimated_minutes,
  });
  const day = (await one(db, 'service_role', null,
    `select public.get_day_state($1, $2) as s`, [c.owner_id, c.local_day])).s;
  const facts = {
    tier: c.tier,
    createdAt: new Date(c.quest_created_at),
    completedAt: new Date(c.completed_at),
    declaredMinutes: c.declared_minutes,
    trackedMinutes: c.tracked_minutes,
    dueAt: c.due_at ? new Date(c.due_at) : null,
    isRecurringOccurrence: c.recurrence !== null || c.occurrence_day !== null,
    hasImplementationIntention: Boolean(c.intention),
  };
  const result = engine.evaluate(proposal, facts, engine.dayStateFromJson(day));
  const meta = {
    latency_ms: 3,
    fallback_reason: 'validation',
    day_change_id: staleDayChangeId !== undefined ? staleDayChangeId : day.changeId,
  };
  const applied = (await one(db, 'service_role', null,
    `select public.apply_progression($1, $2, $3, 'heuristic', null, $4) as r`,
    [completionId, engine.resultToJson(result), engine.proposalToJson(proposal), meta])).r;
  return { applied, result, proposal };
}

async function smoke(db) {
  // --- accounts --------------------------------------------------------------
  await db.query(`insert into auth.users (id, email, raw_user_meta_data) values
    ($1, 'a@example.test', '{"display_name":"Arin","time_zone":"Asia/Tehran","locale":"fa"}'),
    ($2, 'b@example.test', '{"display_name":"Bahar"}'),
    ($3, 'c@example.test', '{}')`, [A, B, C]);
  const profileA = await one(db, 'authenticated', A, 'select * from public.profiles');
  check('signup trigger creates profile with metadata', profileA?.display_name === 'Arin'
    && profileA?.time_zone === 'Asia/Tehran' && profileA?.locale === 'fa');
  const charA = await one(db, 'authenticated', A, 'select * from public.characters');
  check('signup trigger creates character', charA?.level === 1 && Number(charA?.total_xp) === 0);

  // --- curves ---------------------------------------------------------------
  const curveRows = await rows(db, 'anon', null, `
    select n, public.xp_to_advance_level(n) as level_cost, public.xp_to_advance_rank(n) as rank_cost
    from generate_series(1, 50) n order by n`);
  check('SQL level curve matches curves.json (n = 1..50)',
    curveRows.every((r, i) => r.level_cost === CURVES.levelCosts[i]));
  check('SQL rank curve matches curves.json (n = 1..50)',
    curveRows.every((r, i) => r.rank_cost === CURVES.rankCosts[i]));
  let levelAtOk = true;
  for (const [xp, level] of Object.entries(CURVES.levelAt)) {
    const r = await one(db, 'anon', null, 'select public.level_for_xp($1) as l', [Number(xp)]);
    if (r.l !== level) levelAtOk = false;
  }
  check('SQL level_for_xp matches curves.json levelAt', levelAtOk);

  // --- sync_push --------------------------------------------------------------
  const t0 = Date.parse('2026-11-04T05:00:00.000Z');
  const now = Date.now();
  const recent = new Date(now - 3 * 60 * 60 * 1000).toISOString();
  const batch = [
    { entity: 'quest', op: 'upsert', id: OBJECTIVE, hlc: hlc(t0, 1),
      payload: { title: 'Ship the side business', tier: 'objective', category: 'work',
                 created_at: new Date(now - 48 * 3600e3).toISOString() } },
    { entity: 'quest', op: 'upsert', id: QUEST, hlc: hlc(t0, 2),
      payload: { title: 'Study electronics 90m', tier: 'daily', parent_id: OBJECTIVE,
                 category: 'study', created_at: new Date(now - 24 * 3600e3).toISOString() } },
    { entity: 'subtask', op: 'upsert', id: SUBTASK, hlc: hlc(t0, 3),
      payload: { quest_id: QUEST, title: 'Chapter 3', position: 1 } },
    { entity: 'completion', op: 'insert', id: DONE_1, hlc: hlc(t0, 4),
      payload: { quest_id: QUEST, completed_at: recent, declared_minutes: 90 } },
  ];
  const push1 = (await one(db, 'authenticated', A, 'select public.sync_push($1) as r', [batch])).r;
  check('sync_push applies quests, subtask and completion',
    push1.results.every((r) => r.status === 'applied'), JSON.stringify(push1.results.map((r) => r.status)));
  const push2 = (await one(db, 'authenticated', A, 'select public.sync_push($1) as r', [batch])).r;
  check('sync_push replay is a no-op (idempotent)',
    push2.results.every((r) => r.status === 'ignored'), JSON.stringify(push2.results.map((r) => r.status)));

  // Field-level LWW: two devices edit different fields; an older HLC loses.
  await one(db, 'authenticated', A, 'select public.sync_push($1) as r', [[
    { entity: 'quest', op: 'upsert', id: QUEST, hlc: hlc(t0 + 2000, 0, 'devB'), payload: { notes: 'from device B' } },
    { entity: 'quest', op: 'upsert', id: QUEST, hlc: hlc(t0 + 1000, 0, 'devA'),
      payload: { title: 'Study electronics (90 min)', notes: 'stale note' } },
  ]]);
  const merged = await one(db, 'authenticated', A, 'select title, notes, hlc from public.quests where id = $1', [QUEST]);
  check('field-level LWW merges concurrent edits',
    merged.title === 'Study electronics (90 min)' && merged.notes === 'from device B',
    `title=${merged.title}; notes=${merged.notes}`);
  check('row hlc tracks the newest clock', merged.hlc === hlc(t0 + 2000, 0, 'devB'));

  const localDay = await one(db, 'authenticated', A,
    `select local_day, (completed_at at time zone 'Asia/Tehran')::date as expected from public.completions where id = $1`, [DONE_1]);
  check('completion local_day is computed in the user time zone',
    String(localDay.local_day) === String(localDay.expected));

  // --- RLS isolation ----------------------------------------------------------
  const bQuests = await rows(db, 'authenticated', B, 'select id from public.quests');
  const bCompletions = await rows(db, 'authenticated', B, 'select id from public.completions');
  check('RLS: another user cannot read quests or completions', bQuests.length === 0 && bCompletions.length === 0);
  const bUpdate = await as(db, 'authenticated', B,
    (tx) => tx.query(`update public.quests set title = 'hijacked' where id = $1`, [QUEST]));
  check('RLS: another user cannot update quests', bUpdate.affectedRows === 0);
  const bPush = (await one(db, 'authenticated', B, 'select public.sync_push($1) as r', [[
    { entity: 'quest', op: 'upsert', id: QUEST, hlc: hlc(t0 + 9e9), payload: { title: 'hijacked' } },
  ]])).r;
  check('sync_push rejects writes to another user\'s quest', bPush.results[0].reason === 'forbidden');
  await expectError('anon has no table access',
    rows(db, 'anon', null, 'select * from public.quests'), /permission denied/);
  await expectError('clients cannot write ledger_entries',
    as(db, 'authenticated', A, (tx) => tx.query(`insert into public.ledger_entries
      (owner_id, attribute, amount, raw_amount, rule_version, local_day, completion_id)
      values ($1, 'strength', 999, 999, 'x', current_date, $2)`, [A, DONE_1])), /permission denied/);
  await expectError('clients cannot write characters',
    as(db, 'authenticated', A, (tx) => tx.query(`update public.characters set total_xp = 1e6`)), /permission denied/);
  await expectError('clients cannot write feed_events',
    as(db, 'authenticated', A, (tx) => tx.query(`insert into public.feed_events (guild_id, kind) values (gen_random_uuid(), 'completion')`)),
    /permission denied/);
  await expectError('clients cannot call apply_progression',
    one(db, 'authenticated', A, `select public.apply_progression($1, '{}', '{}', 'ai', null)`, [DONE_1]),
    /permission denied/);
  await expectError('completion facts are immutable even for the service role',
    as(db, 'service_role', null, (tx) => tx.query(`update public.completions set declared_minutes = 600 where id = $1`, [DONE_1])),
    /immutable/);

  // --- sync_pull ---------------------------------------------------------------
  const pull = (await one(db, 'authenticated', A, 'select public.sync_pull(0) as r')).r;
  check('sync_pull returns own rows per table',
    pull.changes.quests.length === 2 && pull.changes.subtasks.length === 1
      && pull.changes.completions.length === 1 && pull.changes.profiles.length === 1
      && pull.changes.characters.length === 1 && pull.cursor > 0 && pull.has_more === false,
    `quests=${pull.changes.quests.length} cursor=${pull.cursor}`);
  const pullAgain = (await one(db, 'authenticated', A, 'select public.sync_pull($1) as r', [pull.cursor])).r;
  check('sync_pull after cursor returns nothing new',
    Object.values(pullAgain.changes).every((list) => list.length === 0) && pullAgain.cursor === pull.cursor);
  const paged = (await one(db, 'authenticated', A, 'select public.sync_pull(0, 2) as r')).r;
  check('sync_pull pages with has_more',
    paged.has_more === true && Object.values(paged.changes).flat().length === 2);
  const pullB = (await one(db, 'authenticated', B, 'select public.sync_pull(0) as r')).r;
  check('sync_pull never returns other users\' rows', pullB.changes.quests.length === 0);

  // --- guild setup ---------------------------------------------------------------
  const guild = await one(db, 'authenticated', A, `select * from public.create_guild('The Iron Pact', 'Study together')`);
  check('create_guild makes the creator guild master',
    (await one(db, 'authenticated', A, 'select role from public.guild_members where guild_id = $1', [guild.id]))?.role === 'guild_master');
  const invite = await one(db, 'authenticated', A, 'select * from public.create_invite($1)', [guild.id]);
  check('invite codes are 12 Crockford base32 chars (60 bits)', /^[0-9A-HJKMNP-TV-Z]{4}(-[0-9A-HJKMNP-TV-Z]{4}){2}$/.test(invite.code), invite.code);
  await expectError('members cannot create invites',
    one(db, 'authenticated', C, 'select * from public.create_invite($1)', [guild.id]), /officers/);
  const typed = ` ${invite.code.replaceAll('-', ' ').toLowerCase()} `;
  await one(db, 'authenticated', B, 'select * from public.join_guild_by_code($1)', [typed]);
  check('join_guild_by_code accepts human-typed codes',
    (await rows(db, 'authenticated', B, 'select 1 from public.guild_members where guild_id = $1', [guild.id])).length === 2);
  await expectError('unknown invite codes are rejected',
    one(db, 'authenticated', C, 'select * from public.join_guild_by_code($1)', ['AAAA-BBBB-CCCC']), /not valid/);
  await expectError('co-members cannot read each other\'s guild preferences',
    rows(db, 'authenticated', B, 'select muted from public.guild_members where user_id = $1', [A]), /permission denied/);
  const mine = await rows(db, 'authenticated', B, 'select * from public.my_guilds()');
  check('my_guilds returns own membership and preferences',
    mine.length === 1 && mine[0].effective_share_level === 'completion_only' && mine[0].member_count === 2);
  await one(db, 'authenticated', A, `select * from public.create_challenge($1, '100-Hour Study', 'minutes_in_category', 300,
    now() + interval '30 days', now() - interval '1 day', '', 'study')`, [guild.id]);

  // --- apply_progression ----------------------------------------------------------
  const first = await evaluateAndApply(db, DONE_1);
  check('apply_progression applies the engine result', first.applied.status === 'applied',
    `${first.applied.status}; totalXp=${engine.totalXp(first.result)}`);
  const ledger = await rows(db, 'authenticated', A,
    `select attribute, amount, raw_amount from public.ledger_entries where completion_id = $1 and status = 'confirmed'`, [DONE_1]);
  check('one confirmed ledger row per grant', ledger.length === first.result.grants.length
    && ledger.every((l) => first.result.grants.some((g) => g.attribute === l.attribute && g.amount === l.amount)));
  const charAfter = await one(db, 'authenticated', A, 'select total_xp, level, attr_xp from public.characters');
  check('character cache updated (total XP and curve level)',
    Number(charAfter.total_xp) === engine.totalXp(first.result)
      && charAfter.level === engine.level(engine.totalXp(first.result)).step);
  const dayRow = await one(db, 'authenticated', A,
    `select minutes, completions, similarity_counts from public.day_stats`);
  check('day_stats mirrors RewardResult.applyTo',
    dayRow.minutes === first.result.effectiveMinutes && dayRow.completions === 1
      && dayRow.similarity_counts[first.result.similarityKey] === 1);
  const achievements = await rows(db, 'authenticated', A, 'select achievement_id, title_id from public.achievements');
  check('first_oath achievement unlocked with its title',
    achievements.some((a) => a.achievement_id === 'first_oath' && a.title_id === 'sworn'));

  const again = (await one(db, 'service_role', null,
    `select public.apply_progression($1, $2, '{}', 'heuristic', null) as r`,
    [DONE_1, engine.resultToJson(first.result)])).r;
  const ledgerCount = await one(db, 'service_role', null,
    'select count(*)::int as n from public.ledger_entries where completion_id = $1', [DONE_1]);
  const charAgain = await one(db, 'authenticated', A, 'select total_xp from public.characters');
  check('apply_progression is idempotent', again.status === 'already_applied'
    && ledgerCount.n === first.result.grants.length && Number(charAgain.total_xp) === Number(charAfter.total_xp));

  // Feed projection: guild default is completion_only → no title in payload.
  const feedB = await rows(db, 'authenticated', B, `select kind, payload from public.feed_events where kind = 'completion'`);
  check('feed event projected at completion_only (no title, no XP)',
    feedB.length === 1 && Object.keys(feedB[0].payload).sort().join(',') === 'category,share_level,tier',
    JSON.stringify(feedB[0]?.payload));
  const feedC = await rows(db, 'authenticated', C, 'select * from public.feed_events');
  check('non-members cannot read the guild feed', feedC.length === 0);
  const challenge = await one(db, 'authenticated', B, 'select progress, milestones_reached from public.challenges');
  check('challenge contribution counted for a shared completion',
    Number(challenge.progress) === first.result.effectiveMinutes, `progress=${challenge.progress}`);

  // Blocking hides the blocked user's events from the blocker only.
  await one(db, 'authenticated', B, 'select public.block_user($1)', [A]);
  const blockedView = await rows(db, 'authenticated', B, `select * from public.feed_events where actor_id = $1`, [A]);
  const blockVisibleToA = await rows(db, 'authenticated', A, 'select * from public.blocks');
  check('blocked user\'s feed events are hidden from the blocker', blockedView.length === 0);
  check('blocks are invisible to the blocked party', blockVisibleToA.length === 0);
  await one(db, 'authenticated', B, 'select public.unblock_user($1)', [A]);

  // Comments and reactions.
  const event = await one(db, 'authenticated', B, `select id from public.feed_events where kind = 'completion'`);
  await one(db, 'authenticated', B, `select public.react($1, 'honour')`, [event.id]);
  const comment = await one(db, 'authenticated', B, `select * from public.add_comment($1, 'Well fought!')`, [event.id]);
  check('members can react and comment',
    (await rows(db, 'authenticated', A, 'select * from public.reactions')).length === 1 && comment.body === 'Well fought!');
  await expectError('non-members cannot comment',
    one(db, 'authenticated', C, `select * from public.add_comment($1, 'hi')`, [event.id]), /not found/);
  await expectError('empty comments are rejected',
    one(db, 'authenticated', B, `select * from public.add_comment($1, '   ')`, [event.id]), /1–1000/);

  // Full sharing on a quest exposes title and XP; stale day state is refused.
  await one(db, 'authenticated', A, 'select public.sync_push($1) as r', [[
    { entity: 'quest', op: 'upsert', id: QUEST_FULL, hlc: hlc(t0 + 5000),
      payload: { title: 'Morning run 30m', category: 'fitness', share_level: 'full',
                 created_at: new Date(now - 24 * 3600e3).toISOString() } },
    { entity: 'completion', op: 'insert', id: DONE_2, hlc: hlc(t0 + 5001),
      payload: { quest_id: QUEST_FULL, completed_at: recent, declared_minutes: 30 } },
  ]]);
  const stale = await evaluateAndApply(db, DONE_2, { staleDayChangeId: 1 });
  check('apply_progression refuses a stale day state', stale.applied.status === 'stale_day_state');
  const second = await evaluateAndApply(db, DONE_2);
  check('second completion applied after re-reading the day state', second.applied.status === 'applied');
  const fullEvent = await one(db, 'authenticated', B,
    `select payload from public.feed_events where kind = 'completion' and payload->>'share_level' = 'full'`);
  check('full sharing projects title, total XP and attribute deltas',
    fullEvent?.payload.title === 'Morning run 30m' && fullEvent.payload.total_xp === engine.totalXp(second.result)
      && typeof fullEvent.payload.attributes === 'object');

  // A private member level hides the deed and keeps it out of challenges.
  await as(db, 'authenticated', A, (tx) => tx.query(
    `update public.guild_members set share_level = 'private' where guild_id = $1 and user_id = $2`, [guild.id, A]));
  await one(db, 'authenticated', A, 'select public.sync_push($1) as r', [[
    { entity: 'completion', op: 'insert', id: DONE_3, hlc: hlc(t0 + 6000),
      payload: { quest_id: QUEST, completed_at: new Date(now - 60e3).toISOString(), declared_minutes: 45 } },
  ]]);
  const progressBefore = Number((await one(db, 'authenticated', B, 'select progress from public.challenges')).progress);
  await evaluateAndApply(db, DONE_3);
  const privateEvents = await rows(db, 'service_role', null,
    `select 1 from public.feed_events where completion_id = $1`, [DONE_3]);
  const progressAfter = Number((await one(db, 'authenticated', B, 'select progress from public.challenges')).progress);
  check('private share level: no feed event and no challenge contribution',
    privateEvents.length === 0 && progressAfter === progressBefore);
  await expectError('members cannot change their own role',
    as(db, 'authenticated', B, (tx) => tx.query(`update public.guild_members set role = 'guild_master' where user_id = $1`, [B])),
    /permission denied/);

  // Provisional (offline) ledger rows are superseded by the server result.
  await one(db, 'authenticated', A, 'select public.sync_push($1) as r', [[
    { entity: 'provisional_ledger', op: 'insert', id: PROVISIONAL, payload: {
      completion_id: DONE_3, attribute: 'intelligence', amount: 20, raw_amount: 20, rule_version: '2026.11.1' } },
  ]]);
  const prov = await one(db, 'authenticated', A, 'select status from public.ledger_entries where id = $1', [PROVISIONAL]);
  check('provisional rows arriving after evaluation are stored as superseded', prov?.status === 'superseded');

  // FR-5: one completion per recurring occurrence.
  const occurrence = (await one(db, 'authenticated', A, 'select public.sync_push($1) as r', [[
    { entity: 'completion', op: 'insert', id: DONE_DUP, hlc: hlc(t0 + 7000),
      payload: { quest_id: QUEST, completed_at: recent, occurrence_day: '2026-11-04' } },
    { entity: 'completion', op: 'insert', id: '30000000-0000-4000-8000-000000000005', hlc: hlc(t0 + 7001),
      payload: { quest_id: QUEST, completed_at: recent, occurrence_day: '2026-11-04' } },
  ]])).r;
  check('a recurring occurrence can be completed only once',
    occurrence.results[0].status === 'applied' && occurrence.results[1].reason === 'conflict');

  // --- undo ------------------------------------------------------------------------
  const totalBeforeUndo = Number((await one(db, 'authenticated', A, 'select total_xp from public.characters')).total_xp);
  const undo = (await one(db, 'authenticated', A, 'select public.undo_completion($1) as r', [DONE_1])).r;
  const reversals = await rows(db, 'authenticated', A,
    `select amount from public.ledger_entries where completion_id = $1 and kind = 'reversal'`, [DONE_1]);
  const totalAfterUndo = Number((await one(db, 'authenticated', A, 'select total_xp from public.characters')).total_xp);
  check('undo appends reversal entries and rolls back the cache',
    undo.status === 'undone' && reversals.length === first.result.grants.length
      && totalAfterUndo === totalBeforeUndo - engine.totalXp(first.result),
    `${totalBeforeUndo} → ${totalAfterUndo}`);
  const undoneEvent = await rows(db, 'service_role', null,
    `select 1 from public.feed_events where completion_id = $1`, [DONE_1]);
  const progressUndone = Number((await one(db, 'authenticated', B, 'select progress from public.challenges')).progress);
  const orphanComments = await rows(db, 'postgres', null, `select 1 from public.comments where body = 'Well fought!'`);
  check('undo removes the feed event (with its reactions/comments) and the challenge contribution',
    undoneEvent.length === 0 && orphanComments.length === 0
      && progressUndone === progressAfter - first.result.effectiveMinutes);
  const undoAgain = (await one(db, 'authenticated', A, 'select public.undo_completion($1) as r', [DONE_1])).r;
  check('undo is idempotent', undoAgain.status === 'already_undone');
  await expectError('users cannot undo someone else\'s completion',
    one(db, 'authenticated', B, 'select public.undo_completion($1)', [DONE_2]), /not found/);

  // --- condition, rest days, character ------------------------------------------------
  const rest = await one(db, 'authenticated', A, `select public.set_rest_day(private_today) as r
    from (select (now() at time zone 'Asia/Tehran')::date - 1 as private_today) t`);
  check('set_rest_day returns the recomputed condition', typeof rest.r.condition === 'number');
  await expectError('equipping a locked title is rejected',
    one(db, 'authenticated', A, `select * from public.update_character(equipped_title => 'oathkeeper')`), /not unlocked/);
  const named = await one(db, 'authenticated', A, `select * from public.update_character(name => ' Arin ', equipped_title => 'sworn')`);
  check('update_character sets name and an unlocked title', named.name === 'Arin' && named.equipped_title === 'sworn');

  // --- chronicle facts ----------------------------------------------------------------
  const facts = (await one(db, 'service_role', null, `select public.chronicle_facts($1, 'month',
    date_trunc('month', now() at time zone 'Asia/Tehran')::date) as f`, [A])).f;
  check('chronicle_facts computes grounded totals',
    facts.totals.completions >= 2 && Array.isArray(facts.topActivities) && facts.level.end >= 1,
    JSON.stringify(facts.totals));
  await expectError('chronicle_facts is service-role only',
    one(db, 'authenticated', A, `select public.chronicle_facts($1, 'week', current_date)`, [A]), /permission denied/);

  // --- cron job functions ----------------------------------------------------------------
  const jobs = await one(db, 'postgres', null, `select
      private.take_monthly_snapshots() as snapshots,
      private.recompute_classes() as classes,
      private.enqueue_weekly_chronicles() as chronicles,
      private.refresh_conditions() as conditions,
      private.end_challenges() as challenges,
      private.retention_cleanup() as retention`);
  await one(db, 'postgres', null, 'select private.dispatch_pending_chronicles()');
  check('cron job functions run without pg_cron/pg_net', jobs.snapshots === 3, JSON.stringify(jobs));

  // --- export and deletion -----------------------------------------------------------------
  const exported = (await one(db, 'authenticated', A, 'select public.export_my_data() as e')).e;
  check('export_my_data contains the user\'s rows',
    exported.quests.length === 3 && exported.ledger_entries.length > 0 && exported.guild_memberships.length === 1
      && exported.push_devices !== undefined);

  await one(db, 'authenticated', A, 'select public.leave_guild($1)', [guild.id]);
  const newMaster = await one(db, 'authenticated', B, 'select user_id, role from public.guild_members where guild_id = $1', [guild.id]);
  check('a leaving guild master hands over mastery', newMaster.user_id === B && newMaster.role === 'guild_master');

  const inviteC = await one(db, 'authenticated', B, 'select * from public.create_invite($1)', [guild.id]);
  await one(db, 'authenticated', C, 'select * from public.join_guild_by_code($1)', [inviteC.code]);
  const survivingEvent = await one(db, 'authenticated', B,
    `select id from public.feed_events where kind = 'completion' and completion_id = $1`, [DONE_2]);
  await one(db, 'authenticated', B, `select * from public.add_comment($1, 'Farewell, companions')`, [survivingEvent.id]);
  await one(db, 'authenticated', B, 'select public.delete_my_account()');
  const remaining = await one(db, 'postgres', null, `select
      (select count(*)::int from auth.users where id = $1) as users,
      (select count(*)::int from public.profiles where id = $1) as profiles,
      (select count(*)::int from public.comments where author_id is null and body = 'Farewell, companions') as anonymised,
      (select role::text from public.guild_members where guild_id = $2 and user_id = $3) as successor`,
    [B, guild.id, C]);
  check('delete_my_account removes the user, anonymises comments, hands over the guild',
    remaining.users === 0 && remaining.profiles === 0 && remaining.anonymised === 1
      && remaining.successor === 'guild_master',
    JSON.stringify(remaining));

  await one(db, 'authenticated', C, 'select public.leave_guild($1)', [guild.id]);
  const dissolved = await one(db, 'postgres', null, 'select count(*)::int as n from public.guilds where id = $1', [guild.id]);
  check('the last member leaving dissolves the guild', dissolved.n === 0);

  // --- RLS coverage -----------------------------------------------------------------------
  const unprotected = await rows(db, 'postgres', null, `
    select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity`);
  check('RLS enabled on every public table', unprotected.length === 0, unprotected.map((r) => r.relname).join(', '));
}

async function main() {
  const db = await PGlite.create();
  await db.exec(SUPABASE_STUB);
  console.log('Applying migrations');
  await applyMigrations(db);
  console.log('Smoke checks');
  try {
    await smoke(db);
  } catch (error) {
    check('smoke checks completed', false, String(error?.message ?? error));
  }
  const failed = results.filter((r) => !r.ok);
  console.log(`\n${results.length - failed.length}/${results.length} checks passed`);
  await db.close();
  process.exit(failed.length === 0 ? 0 : 1);
}

main().catch((error) => {
  console.error(`\nValidation aborted: ${error?.message ?? error}`);
  process.exit(1);
});
