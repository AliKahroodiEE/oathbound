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

Early development. The work is organised in phases (see [`docs/`](docs/)):

1. Research — behavioural science foundations
2. Product specification — requirements, progression and AI rules
3. UX/UI — information architecture and design system
4. Technical architecture — backend, sync, AI, notifications
5. Implementation
6. Testing across platforms and locales

## Repository layout

```
.
├── app/            Flutter client (Android, iOS, macOS, Windows, Web)
├── packages/       Shared pure-Dart packages (e.g. the progression engine)
├── backend/        Database schema, row-level security, server functions
└── docs/           Research, product spec, design system, architecture, ADRs
```

## Getting started

Prerequisites: Flutter (stable, 3.47+), Dart 3.13+. Platform toolchains as needed
(Xcode for iOS/macOS, Android SDK for Android, Visual Studio for Windows).

```bash
cd app
flutter pub get
flutter run -d chrome
```

Backend setup and environment variables are documented in [`backend/README.md`](backend/README.md)
once that phase lands.

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
