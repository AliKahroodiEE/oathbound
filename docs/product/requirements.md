# Wyrd — Product Requirements Document

Status: Draft 1 · Owner: product · Last updated: 2026-11-04

> "Your character is not someone you play. Your character is who you become."

Related documents:
[Behavioral science research](../research/behavioral-science.md) ·
[Progression rules](progression-rules.md) ·
[Design system](../design/design-system.md) ·
[Architecture](../architecture/overview.md) ·
[Localization](../localization.md)

---

## 1. Problem and opportunity

Productivity tools treat people as task lists; RPG-flavoured habit apps treat them as players
grinding points. Neither gives a person a durable, honest record of who they are becoming.

Wyrd turns accumulated real-world effort into a persistent character with a history,
inside a serious dark-fantasy world, and surrounds it with small accountability groups.
Success is measured by real-world follow-through, not time in app.

### Goals

| # | Goal | Measured by |
| --- | --- | --- |
| G1 | Help people follow through on what they intend to do | Share of planned quests completed within their window; weekly target kept rate |
| G2 | Make long-term growth visible and meaningful | Weekly chronicle open rate; snapshot comparisons viewed; 90-day retention |
| G3 | Provide supportive social accountability | Share of active users in ≥1 guild; reactions per shared completion; guild challenge completion |
| G4 | Be fair and understandable | "I understand why I got this reward" survey ≥ 80 %; reward dispute rate |
| G5 | Support well-being, not compulsion | Notification opt-out rate; return rate after ≥7 days away; no streak-loss churn spike |

### Non-goals

- Maximising session length or daily opens.
- Competitive, global leaderboards of individuals.
- Diagnosing, profiling or inferring users' emotional or mental states.
- Selling progression, attribute boosts, or randomised rewards.

## 2. Personas

**Sara, 22 — university student, Tehran (Persian, Jalali calendar).** Juggles coursework and a
part-time tutoring job. Starts ambitious study plans, abandons them after a bad week. Wants a
private guild with three classmates. Needs: RTL done right, Jalali dates, gentle return after
exam weeks, AI explanations in Persian.

**Daniel, 31 — software engineer, Toronto (English).** Long-term objective: ship a side
business. Lives in desktop browsers; wants keyboard-driven task entry, multi-column dashboard and
detailed analytics. Sceptical of gamification; will leave the moment rewards feel arbitrary.

**Maryam, 27 — designer, Berlin (bilingual; UI in English, AI in Persian).** Creative practice
and fitness routines. Motivated by visible progress and customisation. Member of a public guild
for illustrators. Wants granular sharing: show that she trained, not what she trained.

**Reza & friends — a five-person accountability pact.** Mixed platforms (Android, iOS,
the web app on laptops). Run a monthly "100-hour study" challenge. Need: invitations, reactions, a feed that
does not overwhelm, no punishment when one member disappears for a week.

## 3. Product principles

1. **Real effort is the only currency.** Progression is always traceable to a real activity.
2. **AI proposes, rules decide.** AI interprets; a deterministic, auditable engine grants.
3. **Growth is never erased.** Attributes, levels, achievements and history are permanent.
4. **Return, don't repent.** Missed days carry no punishment and no shame copy.
5. **Autonomy first.** Users choose goals, sharing, tone, notifications and AI involvement.
6. **Progressive disclosure.** The first session is: create a quest, complete it, see growth.
   Classes, titles, skill trees and analytics unfold as the character develops.
7. **Every locale is first-class.** No left-to-right or Gregorian assumptions anywhere.
8. **Atmosphere serves usability.** Dark fantasy is the voice, never the obstacle.

## 4. Feature inventory

Priority: **P0** first public release · **P1** fast follow · **P2** later.

### 4.1 Account and identity
| ID | Feature | Pri |
| --- | --- | --- |
| A1 | Email + password, magic link, Sign in with Apple, Google sign-in | P0 |
| A2 | Guest/local mode: full functionality on one device, upgrade to account without data loss | P0 |
| A3 | Profile: display name, handle, avatar/portrait, language, region, calendar, time zone | P0 |
| A4 | Account deletion (hard delete within 30 days) and full data export (JSON) | P0 |
| A5 | Multi-device sessions with remote sign-out | P1 |

### 4.2 Character
| ID | Feature | Pri |
| --- | --- | --- |
| C1 | Character sheet (home): name, portrait, level, XP to next level, six attributes, condition, recent growth | P0 |
| C2 | Attribute detail: XP history, top contributing activities, rank milestones | P0 |
| C3 | Reward ledger: every grant with AI rationale, rule adjustments and source task | P0 |
| C4 | Achievements and titles (equip one title) | P0 |
| C5 | Emergent class revealed at level 5, re-evaluated monthly from 90-day activity | P1 |
| C6 | Character frames, cosmetic equipment, portrait customisation | P1 |
| C7 | Specialisations and skill trees (cosmetic/identity only, no stat multipliers) | P2 |
| C8 | Historical snapshots: compare the character at any two dates | P1 |

### 4.3 Quests (tasks)
| ID | Feature | Pri |
| --- | --- | --- |
| Q1 | Create / edit / delete quests: title, notes, category, priority, due date/time, estimated minutes | P0 |
| Q2 | Three tiers: Daily Quest, Contract (has subtasks), Long-Term Objective (has contracts/quests) | P0 |
| Q3 | Recurrence: daily, weekdays, specific weekdays, every N days, N times per week | P0 |
| Q4 | Subtasks with independent completion | P0 |
| Q5 | Reminders (local notifications), quiet-hours aware | P0 |
| Q6 | Optional timer (start/pause/stop) feeding effective duration | P0 |
| Q7 | Quick add with natural phrasing ("Study electronics 90m tomorrow 18:00") | P1 |
| Q8 | AI breakdown: turn a vague objective into specific quests (user approves each) | P1 |
| Q9 | Implementation intention field: "When/where will you do this?" | P0 |
| Q10 | Reschedule, snooze, pause objective, archive | P0 |
| Q11 | Per-quest sharing level (see 4.6) | P0 |
| Q12 | Completion history and undo within 24 h | P0 |

### 4.4 Progression
| ID | Feature | Pri |
| --- | --- | --- |
| P1 | AI evaluation of each completion → proposal → deterministic validation → ledger | P0 |
| P2 | Offline completion with provisional local evaluation, reconciled on sync | P0 |
| P3 | Explanation card after completion: attributes, amounts, reasons, rule adjustments | P0 |
| P4 | Anti-exploitation: diminishing returns, daily soft/hard caps, trivial-task floor, duration plausibility | P0 |
| P5 | Follow-through bonus to Discipline for planned, on-time completions | P0 |
| P6 | Objective contribution: completing linked quests advances parent objective | P0 |
| P7 | Reward dispute: "This doesn't seem right" → re-evaluate once with user note | P1 |

### 4.5 Consistency and condition
| ID | Feature | Pri |
| --- | --- | --- |
| S1 | Weekly target (active days per week, user-set) and kept-weeks streak | P0 |
| S2 | Daily chain with automatic rest day (1/week) and manual rest days | P0 |
| S3 | Pause mode (travel, illness, exams): freezes consistency without loss | P0 |
| S4 | Condition (HP 0–100) reflecting recovery vs. overexertion; never reduced by missed tasks | P0 |
| S5 | Gentle return experience after ≥3 days away | P0 |

### 4.6 Guilds and social
| ID | Feature | Pri |
| --- | --- | --- |
| G1 | Private guilds (invite link/code, 2–50 members) | P0 |
| G2 | Public guilds (discoverable, join requests or open join, up to 5 000 members) | P1 |
| G3 | Activity feed: completion events at the member's chosen sharing level | P0 |
| G4 | Reactions (fixed, meaningful set) and comments | P0 |
| G5 | Roles: Guild Master, Officer, Member; permission matrix | P0 |
| G6 | Collective challenges with contribution tracking and milestones | P0 |
| G7 | Guild emblem, description, language tag, rules | P0 |
| G8 | Moderation: report, remove content, kick/ban, slow mode, keyword filter (public) | P0 (private) / P1 (public) |
| G9 | Mute guild, block user, per-guild notification settings | P0 |
| G10 | Guild achievements, cosmetic unlocks, titles | P1 |

Sharing levels per completion (default chosen per guild, overridable per quest):
1. **Full** — title and reward. 2. **Title only** — title, no reward details.
3. **Completion only** — "completed a Contract" with category glyph, no title.
4. **Private** — no event.

### 4.7 Analytics and chronicle
| ID | Feature | Pri |
| --- | --- | --- |
| H1 | Weekly view: completions, time invested, attribute XP by day, consistency | P0 |
| H2 | Monthly view: attribute growth, distribution, objectives completed, records, vs. last month | P0 |
| H3 | Yearly view: long-term attribute curves, totals, longest consistency, highlights | P1 |
| H4 | AI chronicle: weekly (P0), monthly (P1), yearly (P1), generated only from stored facts | P0 |
| H5 | Snapshot comparison (see C8) | P1 |
| H6 | Desktop: multi-panel analytics; mobile: stacked cards | P0 |

### 4.8 Motivation engine
| ID | Feature | Pri |
| --- | --- | --- |
| M1 | Motivation profile (optional): drivers + communication tone; editable any time | P0 |
| M2 | Daily briefing (opt-in): today's quests, deadlines, one suggested focus | P1 |
| M3 | Evening reflection (opt-in): what got done, growth, one next step | P1 |
| M4 | Weekly review with suggested adjustments (user accepts or dismisses each) | P0 |
| M5 | Overreach detection: repeated misses of one quest → suggest smaller step or new time | P1 |
| M6 | Balance suggestions for long-neglected objectives | P1 |
| M7 | Transparency panel: what the AI knows about you and why; reset personalisation | P0 |

### 4.9 Notifications
| ID | Feature | Pri |
| --- | --- | --- |
| N1 | Categories: reminders, guild reactions, guild comments, challenge milestones, objectives, weekly summary, briefing/reflection | P0 |
| N2 | Per-category toggles, per-guild mute, quiet hours (default 22:00–08:00 local) | P0 |
| N3 | Daily cap on non-reminder notifications (default 5); batching of reactions | P0 |
| N4 | Push via FCM/APNs/Web Push; local scheduling for reminders | P0 |

### 4.10 Settings, privacy, trust
Language, region, calendar (Gregorian/Jalali), time zone, number format, first day of week,
theme intensity (standard/reduced effects), reduced motion, text scale, AI usage controls
(AI evaluation on/off → deterministic-only fallback; AI chronicles on/off; AI language),
data export, account deletion, blocked users, sharing defaults. **P0.**

### 4.11 Monetization (freemium)
Free: full task system, character, basic AI progression, weekly analytics + chronicle,
private guilds (up to 3), reactions/comments, challenges.
Premium ("Patron"): advanced AI planning and insights, monthly/yearly chronicles, snapshot
comparisons beyond 12 months, advanced guild management (public guild ownership, custom
roles), cosmetic themes, frames and emblems.
**Never sold:** XP, attributes, levels, streak protection beyond the free allowance,
randomised items, social features essential to accountability.

## 5. Key user journeys

### J1 — First meaningful experience (target ≤ 3 minutes)
1. Welcome → choose language (English / فارسی). Layout flips immediately.
2. Continue as guest or create account.
3. Name the character; choose a portrait.
4. Pick 1–3 areas of life to develop (maps to suggested categories). Skip allowed.
5. Create the first quest from a suggestion or free text; optional "when/where".
6. Complete it (or "I already did this today").
7. Reward reveal: attributes rise, explanation shown, level 1 → progress visible.
8. Optional: motivation profile, notifications, guild invite — each skippable, revisitable.

### J2 — Daily loop
Open → character sheet shows today's quests and condition → complete quest → reward card
(2 s, dismissible, skippable animation) → optional share to guild → back to real life.

### J3 — Cross-device
Create a quest in the web app on a laptop → complete it on Android (offline on a train) → provisional reward
shown with "will confirm when online" → reconnect → server evaluates → ledger reconciles →
web app on another computer receives the realtime update within seconds.

### J4 — Guild challenge
Guild Master creates "The Iron Pact — 100-Hour Study Challenge" (metric: minutes in category
Study, 30 days) → members' qualifying completions contribute automatically (respecting
sharing level: contribution counted even if the completion is "completion only") →
milestones at 25/50/75/100 % post to the feed → emblem unlocked at 100 %.

### J5 — Return after absence
User returns after 11 days → no streak-loss screen → "Your journey hasn't been erased" card
with one suggested small quest → consistency resumes from the current week; the previous
best is preserved as a record.

### J6 — Long-term reflection
December → Chronicle → Year view → compare January snapshot vs. today → read the yearly
chronicle → export as image (P2).

## 6. Functional requirements (selected, testable)

- **FR-1** Completing a quest MUST create exactly one completion record, idempotent by
  client-generated UUID, regardless of retries or duplicate sync.
- **FR-2** Every attribute change MUST be backed by a ledger entry referencing a completion,
  an achievement, a correction, or a migration, with rule version and explanation.
- **FR-3** AI output MUST be schema-validated; invalid or unavailable AI MUST fall back to
  the deterministic heuristic evaluator, flagged as such in the ledger.
- **FR-4** No code path may decrease an attribute's lifetime XP except an explicit user undo
  (within 24 h) or an administrative correction, each recorded as a reversing entry.
- **FR-5** A recurring quest occurrence can be completed at most once per occurrence window.
- **FR-6** Sharing level MUST be enforced server-side (RLS / projection), never by clients.
- **FR-7** Blocked users' content MUST NOT be delivered to the blocker in feeds or
  notifications; blocking is invisible to the blocked party.
- **FR-8** All user-facing strings MUST resolve through the localization system; CI fails on
  missing keys in any shipped locale.
- **FR-9** Dates MUST render in the user's chosen calendar; stored timestamps are UTC with
  the user's IANA time zone used for day boundaries.
- **FR-10** User-authored content (titles, notes, comments, guild names) MUST never be
  machine-translated or rewritten.

## 7. Non-functional requirements

| Area | Requirement |
| --- | --- |
| Performance | Cold start < 2.5 s mid-range Android; 60 fps scrolling; completion feedback < 100 ms local, AI confirmation p95 < 6 s |
| Offline | Create, edit, complete, undo quests offline; sync conflict policy documented; no data loss on app kill |
| Sync latency | Realtime propagation between online devices p95 < 3 s |
| Availability | 99.5 % monthly for API; AI outage degrades to deterministic evaluation, never blocks completion |
| Security | RLS on every table; least-privilege service keys only server-side; OWASP MASVS L1 |
| Privacy | Private by default; AI receives minimal context; no training on user data; data export + deletion |
| Accessibility | WCAG 2.2 AA contrast; screen-reader labels; dynamic type to 200 %; reduced motion; keyboard navigation on desktop/web |
| Localization | 100 % string coverage for en and fa; RTL mirrored layouts; Jalali + Gregorian; Persian digits optional |
| Quality | Engine coverage ≥ 95 %; golden tests for key screens in LTR + RTL; integration tests for sync |

## 8. Release plan

| Milestone | Scope |
| --- | --- |
| M0 Foundation | Docs, design system, l10n, engine, local-first app shell, character sheet, quests, offline evaluation |
| M1 Connected | Auth, sync, server AI evaluation, ledger reconciliation, push |
| M2 Social | Private guilds, feed, reactions, comments, challenges, moderation basics |
| M3 Chronicle | Monthly/yearly analytics, AI chronicles, snapshots, motivation engine |
| M4 Public | Public guilds + moderation, premium, cosmetics, store releases on all five platforms |

## 9. Open questions

1. Product name and Persian brand rendering (working name: Wyrd).
2. Minimum age (proposed 16+ for public guilds; 13+ private-only).
3. Whether premium pricing differs by region (Iran payment rails are limited).
4. AI provider data-residency requirements for EU users.
