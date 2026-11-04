# UX Specification

## 1. Information architecture

```
Character (home)
├── Character sheet: portrait, name, title, class, level, XP, condition
├── Six attributes → Attribute detail (history, top activities, ranks)
├── Today's quests (inline complete)
├── Recent growth (last 5 ledger results) → Reward detail
└── Achievements & titles
Quests
├── Today · Upcoming · Contracts · Objectives · Completed
├── Quest editor (sheet on mobile, side panel on desktop)
└── Objective detail (linked contracts/quests, progress)
Guilds
├── My guilds · Discover (public, M4)
└── Guild hall: Feed · Challenges · Members · Settings
Chronicle
├── Week · Month · Year analytics
├── Written chronicles
├── Snapshots (compare two dates)
└── Reward ledger
Settings (avatar menu / sidebar footer)
├── Language, region, calendar, time zone, digits, first day of week
├── Motivation profile, AI preferences & transparency
├── Notifications, quiet hours
├── Sharing defaults, blocked users
├── Appearance (reduced effects, reduced motion, text size)
└── Account: export, delete, sign out
```

## 2. Navigation

| Width class | Pattern |
| --- | --- |
| Compact (< 600) | Bottom navigation: Character · Quests · Guilds · Chronicle. Quick-add floating button at the bottom end. Settings from the avatar in the top bar. |
| Medium (600–1199) | Navigation rail at the start edge with quick-add on top; content in up to two panes (list + detail). |
| Expanded (≥ 1200) | Sidebar (240 px) at the start edge: brand, four destinations, guild shortcuts, settings at the bottom. Character screen becomes a three-column dashboard: sheet · today's quests · growth & guild activity. |

In RTL the start edge is the right edge: sidebar, rail, back arrows, swipe directions and
progress fills all mirror. Numerals in Persian can be Persian or Latin digits (setting).

Desktop/web keyboard: `N` new quest, `/` search, `G then C/Q/G/H` go to destination,
`Space` complete focused quest, `E` edit, `?` shortcut help.

## 3. Key screens

### Character sheet (home)
- **Header band:** portrait seal (64/96 px), character name in `title`, equipped title and
  class in `ashMuted`, level numeral in a carved seal, XP bar with exact numbers.
- **Condition:** small label (Rested/Steady/Strained) with a single-sentence explanation on tap.
- **Attributes:** six rows (compact) or a 2 × 3 grid (expanded). Each shows rank, bar to next
  rank, and "+N today" when non-zero. Tap → attribute detail.
- **Today:** up to 5 quests inline; overflow links to Quests. Empty: "No quests sworn for
  today." + "Swear a quest".
- **Recent growth:** compact list of reward results with deltas.

### Quest editor
Progressive disclosure: title (required) → tier (Daily Quest default) → optional: due,
estimate, category (AI suggests), "When and where?" (implementation intention), recurrence,
reminder, subtasks, parent objective, sharing. One primary action: "Swear quest".

### Completion and reward
Tap seal → seal fills (120 ms) → reward card slides up (200 ms) → XP bar and attribute bars
fill (900 ms) → rationale text. Offline: "Provisional — will be confirmed when you're online."
Card dismisses on tap outside; never blocks the next action. "Undo" available for 24 h.

### Chronicle
Segmented control Week/Month/Year; period stepper with calendar-aware labels
("Aban 1405" or "November 2026"). Charts: stacked bar of XP per attribute per day/week,
radar of attribute distribution vs. previous period, time-invested line, consistency
calendar (active / rest / paused days). Written chronicle card at top when available.

### Guild hall
Header (emblem, name, member count, language tag) → tabs Feed / Challenges / Members.
Feed items respect each actor's share level. Reaction bar is single-tap; comments open a
thread sheet. Challenges show collective progress with milestone ticks; individual
contributions are visible only to the member themself by default.

## 4. Onboarding
1 Language → 2 Guest or account → 3 Name + portrait → 4 Areas to grow (multi-select, skippable)
→ 5 First quest (suggestions based on step 4) → 6 Complete or schedule it → 7 Reward reveal
explaining "AI interprets, rules decide" in two sentences → done. Motivation profile,
notifications and guild invitations are offered later in context (first evening, first week).

## 5. States catalogue
Every data view defines: loading (skeleton), empty (voice + action), error (retry), offline
(banner "Working offline — changes will sync"), and partial (stale data with a quiet
"Updated 3 h ago").
