<div align="center">

# Oathbound

**Your character is not someone you play. Your character is who you become.**

A dark-fantasy RPG productivity ecosystem in which real-life effort shapes a persistent character,
its history, and the guilds it belongs to.

Android · iOS · macOS · Windows · Web — English & فارسی (full RTL) from day one

[![License: PolyForm Strict 1.0.0](https://img.shields.io/badge/license-PolyForm%20Strict%201.0.0-A71924)](LICENSE.md)

</div>

---

## What it is

Oathbound is a task and habit system wrapped in a serious, atmospheric RPG. You don't assign
yourself points. You do real things — study, train, build, reach out to people — and an AI
evaluator proposes how that effort should shape your character. A deterministic progression
engine then validates, caps and records every reward in an auditable ledger, and tells you
exactly why you grew.

| Pillar | What it means in the product |
| --- | --- |
| **Character** | Six attributes (Strength, Intelligence, Discipline, Creativity, Vitality, Social), levels, titles, emergent classes, a permanent chronicle. Attributes are never lost to inactivity. |
| **AI progression** | AI interprets each completed task; a deterministic engine caps, applies diminishing returns, and explains the result. AI never writes to your character directly. |
| **Quests** | Daily Quests → Contracts → Long-Term Objectives, with recurrence, subtasks, reminders and optional time tracking. |
| **Guilds** | Private and public guilds, an activity feed with reactions and comments, collective challenges that never punish members for one person's inactivity. |
| **Chronicle** | Weekly, monthly and yearly analytics, historical character snapshots, and AI-written chronicles grounded in your real data. |
| **Psychology** | Designed from published research on motivation, habit formation and self-compassion — no shame mechanics, no gambling loops, no streak terror. |

## Status

Milestone **M0 — Foundation** is implemented; **M1 — Connected** is in progress.

| Area | State |
| --- | --- |
| Research, product spec, progression rules, design system, UX, architecture | ✅ [`docs/`](docs/) |
| Progression engine (Dart) with 103 tests and shared conformance vectors | ✅ [`packages/oathbound_engine`](packages/oathbound_engine) |
| Local-first app: character sheet, quests (daily/contracts/objectives, recurrence, subtasks, timer, reminders), reward reveal with explanations, ledger, week/month/year chronicle, settings, onboarding | ✅ [`app/`](app/) |
| English + Persian, full RTL, Jalali/Gregorian, native/Latin digits | ✅ |
| Adaptive layouts: phone (bottom bar), tablet (rail), desktop/web (sidebar, multi-column) | ✅ |
| Backend: schema, row-level security, sync and progression RPCs, AI evaluation and chronicle functions | 🚧 [`backend/`](backend/) |
| Accounts, sync, guilds in the client | 🚧 |

Verified in this environment: engine and app test suites, static analysis, and the web build
exercised in a browser in English and Persian at phone, tablet and desktop widths. Android, iOS,
macOS and Windows builds need their platform toolchains (Android SDK, Xcode, Visual Studio)
and have not yet been built.

## Repository layout

```
.
├── app/            Flutter client (Android, iOS, macOS, Windows, Web)
├── packages/       Shared pure-Dart packages (the progression engine)
├── backend/        Supabase schema, row-level security, Edge Functions
└── docs/           Research, product spec, design system, architecture, ADRs
```

## Getting started

Prerequisites: Flutter 3.47+ (stable), Dart 3.13+, plus the toolchain for each target platform.

```bash
cd app
flutter pub get
flutter run -d chrome          # or: -d macos, -d windows, an Android device or iOS simulator
```

Without backend configuration the app runs fully on the device (guest mode): every feature
except accounts, sync and guilds works offline. To connect a Supabase backend:

```bash
flutter run --dart-define=SUPABASE_URL=https://<project>.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

Backend setup is documented in [`backend/README.md`](backend/README.md).

## Tests

```bash
cd packages/oathbound_engine && dart test     # rules, caps, curves, consistency, vectors
cd app && flutter test                        # data layer, l10n gates, RTL lint, smoke tests
cd app && flutter analyze --fatal-infos
```

CI runs all of these plus the web build on every push ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)).

## Localization

English and Persian are first-class launch languages. All UI strings live in ARB resource files
with stable keys; layouts use logical (start/end) directions only. Adding a language is a
content task, not an engineering project — see [`docs/localization.md`](docs/localization.md).

## License

**Source-available, not open source in the OSI sense.** This code is published so you can read
it, learn from it, and evaluate it. It is licensed under the
[PolyForm Strict License 1.0.0](LICENSE.md), which in plain terms means:

- ✅ You may read the code and run it for personal, noncommercial study or experimentation.
- ❌ You may **not** redistribute it, in whole or in part.
- ❌ You may **not** modify it or build new works based on it.
- ❌ You may **not** use it for any commercial purpose.

For any other use — commercial licensing, partnerships, or permission to reuse part of the
code — contact the author through GitHub. The license text in [`LICENSE.md`](LICENSE.md) is
the binding document; this summary is not legal advice.

## Contributing

Because the license does not permit derivative works, pull requests cannot be accepted without
a separate written contributor agreement. Bug reports and suggestions are welcome as issues.
See [`CONTRIBUTING.md`](CONTRIBUTING.md).

Copyright © 2026 AliKahroodiEE. All rights not expressly granted are reserved.
