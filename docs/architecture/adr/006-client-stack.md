# ADR-006 — Client stack

Status: Accepted · 2026-11-04

| Concern | Choice | Why |
| --- | --- | --- |
| State | `flutter_riverpod` | Compile-safe providers, testable without widgets, good async/stream support |
| Routing | `go_router` | Declarative, deep links, URL-based web navigation, shell routes for adaptive scaffolds |
| Local DB | `drift` + `drift_flutter` | Typed SQL, migrations, reactive queries, works on all five platforms incl. web (wasm) |
| Backend SDK | `supabase_flutter` | Auth, PostgREST, Realtime, Storage |
| Localization | `flutter_localizations` + gen-l10n (ARB, ICU plural/select) | Stable keys, compile-time checking, per-locale plural rules |
| Calendars | `intl` + `shamsi_date` | Gregorian and Jalali formatting independent of UI language |
| Fonts | Bundled **Inter** (Latin) and **Vazirmatn** (Arabic script), plus a display serif for headings | Offline, privacy-preserving, correct Persian shaping; per-locale font fallback chain |
| Charts | `fl_chart` | Customisable, RTL-capable with mirrored axes |
| Notifications | `flutter_local_notifications`, `firebase_messaging` (M1) | See ADR-007 |
| IDs | `uuid` v7 | Time-ordered client-generated IDs for idempotency |

All dependencies must support Android, iOS, macOS, Windows and Web, or be isolated behind an
interface with a no-op implementation on unsupported platforms.
