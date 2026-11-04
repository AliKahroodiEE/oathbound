# Progression Rules — v2026.11.1

These rules are the contract between the AI evaluator, the deterministic engine, the client and
the server. They are implemented once in Dart (`packages/oathbound_engine`, used by clients for
offline/provisional results) and once in TypeScript (server, authoritative). Both
implementations must pass the shared conformance vectors in
`packages/oathbound_engine/test/vectors/`. Any change to a number in this document bumps the
rule version, and every ledger entry records the version that produced it.

Design rationale for each rule is in the [research document](../research/behavioral-science.md).

---

## 1. Vocabulary

| Term | Meaning |
| --- | --- |
| **Attribute** | One of `strength`, `intelligence`, `discipline`, `creativity`, `vitality`, `social`. Lifetime XP per attribute is permanent. |
| **Grant** | XP added to one attribute by one ledger entry. |
| **Character XP** | Sum of all attribute XP. There is no separate XP pool to farm. |
| **Level** | Derived from character XP (§6). |
| **Rank** | Per-attribute level derived from that attribute's XP (§6). |
| **Local day** | Calendar day in the user's IANA time zone; day boundaries never use UTC. |
| **Proposal** | The evaluator's structured interpretation of a completion (AI or heuristic). |
| **Result** | The engine's validated, capped, explained grants for that completion. |

## 2. Pipeline

```
completion ─▶ evaluator (AI, or heuristic fallback) ─▶ proposal
proposal + completion facts + today's ledger ─▶ engine ─▶ result ─▶ ledger (append-only)
```

The engine is a pure function: `evaluate(proposal, facts, dayState) → result`. Same inputs,
same outputs, on every platform.

## 3. Proposal schema (evaluator output)

| Field | Type | Constraint |
| --- | --- | --- |
| `category` | enum | `study, work, fitness, health, creative, social, chores, admin, mindfulness, reading, other` |
| `similarityKey` | string | lowercase slug `category.topic`, ≤ 48 chars, language-independent (e.g. `study.electronics`) |
| `difficulty` | int | 1–5 (see rubric §8.3) |
| `estimatedMinutes` | int | 1–600, plausible real effort for the described activity |
| `attributes` | list | 1–3 of `{attribute, weight (0–1), reason}`; reasons in the user's AI language |
| `trivial` | bool | true for tasks under ~5 minutes of real effort or without substance |
| `confidence` | number | 0–1, evaluator's confidence in its interpretation |
| `summary` | string | ≤ 160 chars, user's AI language, describes the effort, not the person |
| `source` | enum | `ai` or `heuristic` |

## 4. Completion facts (deterministic inputs)

`tier` (daily / contract / objective) · `declaredMinutes?` · `trackedMinutes?` (timer) ·
`createdAt` · `completedAt` · `dueAt?` · `isRecurringOccurrence` · `hasImplementationIntention`.

## 5. Engine steps

### 5.1 Normalise the proposal
1. Clamp `difficulty` to 1–5 and `confidence` to 0–1.
2. Drop unknown attributes, non-positive or non-finite weights, and duplicates (keep the
   higher weight).
3. Scale weights to sum to 1, then keep the three highest (ties broken by attribute order:
   strength, intelligence, discipline, creativity, vitality, social).
4. Drop kept weights whose scaled value is < 0.10; if none would remain, keep the highest.
5. Rescale the survivors to sum to 1. If nothing remains at all, use the category defaults
   (§8.1) and record adjustment `weights_defaulted`.

### 5.2 Effective minutes `m`
1. If `trackedMinutes ≥ 1` → `m = trackedMinutes` (timer is the strongest evidence).
2. Else if `declaredMinutes` is present → `m = min(declared, max(2 × estimatedMinutes, 15))`.
   Adjustment `duration_plausibility` when reduced.
3. Else → `m = estimatedMinutes`.
4. Clamp to the tier cap: daily 240, contract 480, objective 480.
5. **Daily effort budget:** credited minutes across a local day ≤ 960. `m` is reduced to the
   remaining budget (adjustment `daily_budget`).

### 5.3 Base XP
```
base = 20 × (m / 30)^0.65 × D[difficulty] × T[tier]
D = {1: 0.50, 2: 0.75, 3: 1.00, 4: 1.30, 5: 1.60}
T = {daily: 1.00, contract: 1.25, objective: 1.50}
```
The sub-linear duration exponent rewards real time without making marathon logging dominant.

### 5.4 Trivial tasks
If `trivial` or `m < 5`: `base = min(base, 3)` (adjustment `trivial_floor`). After 10 trivial
completions in a local day, further trivial completions grant 0 (adjustment `trivial_limit`).
One hundred trivial tasks therefore yield at most 30 XP per day.

### 5.5 Repetition (diminishing returns)
`n` = completions earlier the same local day with the same `similarityKey`.
Multiplier `R = [1.00, 0.80, 0.60, 0.40, 0.25]`, then `0.10` for every later repetition.
Repetition is per day only: a daily habit is never diminished across days.

### 5.6 Confidence
If `confidence < 0.40`: multiplier 0.75 (adjustment `low_confidence`), with a suggestion to
describe the task more concretely. Heuristic evaluations carry no penalty.

### 5.7 Distribute
`adjusted = base × R × confidenceMultiplier`; each attribute receives `adjusted × weight`.

### 5.8 Follow-through bonus (deterministic Discipline)
If the completion is non-trivial **and** the quest was planned (created ≥ 60 min before
completion, or it is a recurring occurrence)
**and** it was completed on or before `dueAt` (or has no due date): Discipline receives
`+10 %` of `adjusted`, plus `+5 %` if it had an implementation intention. Minimum +1.
Adjustment `follow_through`. This is the only place the engine creates attribute value the
evaluator did not propose, and it rewards exactly what Discipline means: planning and keeping.

### 5.9 Daily caps (per attribute)
Raw amounts are accumulated per attribute per local day. Effective XP follows

```
effective(x) = min(x, 200) + 0.5 × clamp(x − 200, 0, 400)      // ceiling 400 per attribute per day
grant        = round(effective(rawToday + raw) − effective(rawToday))
```
Adjustments `soft_cap` / `hard_cap`. The copy frames this as rest, not restriction.

### 5.10 Output
Raw amounts are rounded to integers before caps. Integer grants (zero grants dropped), total, effective minutes, adjustments with parameters,
rule version, and whether the proposal came from AI or the heuristic.

### Worked example
"Studied electronics for 90 minutes" — daily, declared 90, AI estimate 90, difficulty 3,
weights intelligence 0.75 / discipline 0.25, planned that morning, no due date.

| Step | Value |
| --- | --- |
| `m` | 90 |
| base | 20 × 3^0.65 × 1.0 × 1.0 = 40.8 |
| repetition, confidence | ×1.0, ×1.0 |
| intelligence | 40.8 × 0.75 = 30.6 → **31** |
| discipline | 40.8 × 0.25 + 10 % × 40.8 = 14.3 → **14** |
| total | **45 XP** |

## 6. Levels and ranks

| Curve | XP required to advance from `n` to `n + 1` |
| --- | --- |
| Character level | `round(100 × n^1.5)` → 100, 283, 520, 800, 1118 … |
| Attribute rank | `round(40 × n^1.4)` → 40, 106, 186, 279, 381 … |

Both start at 1 with 0 XP. A level is never lost. Progress bars always show true remaining
XP — no artificial acceleration near the end of a bar.

## 7. Consistency, condition and recovery

### 7.1 Active days and weekly target
- An **active day** has at least one non-trivial completion.
- The user sets a **weekly target** of 1–7 active days (default 4). A week is **kept** when
  `activeDays ≥ target`. The first day of the week follows the user's region (Saturday for
  `fa-IR`, Monday for ISO regions, Sunday for `en-US`), overridable in settings.
- **Week streak** = consecutive kept weeks. An unfinished current week never breaks it.
- **Paused** weeks (pause mode) are skipped: neither kept nor broken.

### 7.2 Daily chain
Consecutive active days, where one missing day per week is forgiven automatically (rest day)
and paused days are skipped. The chain ends only on an unforgiven gap. Best chain and best
week streak are permanent records shown with the same weight as the current one.

### 7.3 Condition (HP 0–100)
Condition reflects recovery versus overexertion. **Missed or overdue quests never reduce it.**

| Event (per local day) | Effect |
| --- | --- |
| Credited minutes over 600 | −1 per 10 minutes over, max −30 |
| Day ending at ≤ 600 credited minutes | +15 |
| ≥ 20 Vitality XP that day | +10 |
| Declared rest day | +25 |

Bounds 25–100; starts at 100. Labels: **Rested** ≥ 80, **Steady** 50–79, **Strained** < 50.
Condition never modifies XP; it only informs and suggests recovery.

### 7.4 Return after absence
After ≥ 3 inactive days the next session shows a welcome-back card (no streak-loss screen),
offers one small quest, and records nothing negative. Completing a quest after ≥ 7 inactive
days unlocks the achievement **The Return** once.

## 8. Evaluator rules

### 8.1 Category defaults (heuristic and fallback weights)

| Category | Weights |
| --- | --- |
| study | intelligence 0.8, discipline 0.2 |
| reading | intelligence 0.8, creativity 0.2 |
| work | discipline 0.6, intelligence 0.4 |
| fitness | strength 0.7, vitality 0.3 |
| health | vitality 0.8, discipline 0.2 |
| mindfulness | vitality 0.6, discipline 0.4 |
| creative | creativity 0.8, discipline 0.2 |
| social | social 1.0 |
| chores | discipline 0.7, vitality 0.3 |
| admin | discipline 0.8, intelligence 0.2 |
| other | discipline 1.0 |

### 8.2 AI evaluator guardrails
- Receives only: title, notes (truncated to 1 000 chars), tier, category hint, declared /
  tracked / estimated minutes, parent objective title, the user's AI language, and counts of
  similar completions in the last 7 days. Never guild data, other users, or identity data.
- Must evaluate the concrete activity, not adjectives: "an epic, brutal, life-changing
  20-minute walk" is a 20-minute walk.
- Must never comment on the user's character, worth, mood or health status.
- Output is JSON validated against §3; any violation → heuristic fallback, logged.
- Temperature 0; identical inputs within 7 days reuse the cached proposal.
- User-authored text is never translated or rewritten; `reason` and `summary` use the
  user's AI language, which is independent of guild languages.

### 8.3 Difficulty rubric
1 routine, little focus · 2 some focus or mild exertion · 3 sustained focus or moderate
exertion · 4 demanding, skill-stretching · 5 exceptional (exam, competition, major delivery).

## 9. Achievements, titles, classes

### 9.1 Achievements (deterministic, evaluated after each ledger write)
`first_oath` first completion · `deeds_10` / `deeds_100` / `deeds_1000` completions ·
`first_contract` · `first_objective` · `level_5` / `level_10` / `level_25` ·
`rank_10_<attribute>` · `kept_weeks_4` / `kept_weeks_12` / `kept_weeks_52` ·
`the_return` · `balanced` (all ranks ≥ 3) · `hours_100` (6 000 credited minutes).
Achievements never grant XP — they are recognition, not currency.

### 9.2 Titles
Unlocked by achievements; one may be equipped. Examples: `first_oath` → *the Sworn*,
`kept_weeks_12` → *the Steadfast*, `the_return` → *the Returned*,
`rank_10_intelligence` → *Adept of Lore*, `balanced` → *the Whole*.

### 9.3 Emergent class (revealed at level 5, recomputed on the 1st of each month)
Shares are computed from the last 90 days of attribute XP.

1. If the top share < 0.25 and at least five attributes have share ≥ 0.10 → **Explorer**.
2. Hybrids when both shares ≥ 0.25: intelligence + discipline → **Strategist**;
   intelligence + creativity → **Arcanist**.
3. Otherwise by top attribute: intelligence → **Scholar**, discipline → **Warden**,
   creativity → **Artisan**, strength → **Vanguard**, social → **Envoy**,
   vitality → **Druid**.

Classes are identity, not mechanics: no class changes XP.

## 10. Guild challenges

Metrics: `minutes_in_category`, `completions`, `xp_in_attribute`. Contributions come from
completions after the challenge start, counted server-side. Completions shared at any level
except **Private** contribute; members may opt in to anonymous contribution of private
completions. Milestones at 25/50/75/100 % post to the feed. No member is ever penalised for
another member's inactivity; there is no failure state beyond "the season ended at 82 %",
which is recorded as a result, not a loss.

## 11. Corrections

- **Undo** (≤ 24 h): appends reversing entries for that completion; today's raw totals drop
  accordingly.
- **Reconciliation:** provisional (offline) results are superseded by the server result for
  the same completion ID; the ledger keeps both, with the provisional marked `superseded`.
- **Dispute:** one re-evaluation with the user's note; the better-founded result stands and
  both are kept.
- Editing a completed quest does not re-evaluate it.
