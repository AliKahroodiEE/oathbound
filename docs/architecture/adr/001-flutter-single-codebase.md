# ADR-001 — Flutter as the single client codebase

Status: Accepted · 2026-11-04 · Amended 2026-11-04 (see below)

## Context
Wyrd must ship on Android, iOS, macOS, Windows and Web with identical business logic,
a distinctive custom visual identity, and first-class RTL. Alternatives considered: native per
platform, React Native + react-native-web, Kotlin Multiplatform + Compose Multiplatform.

## Decision
Use Flutter (stable) for every client. Share all domain, state, sync and engine code. Build
three adaptive shells selected by window width, not by platform:

| Width class | Shell |
| --- | --- |
| compact (< 600 dp) | bottom navigation, single column, sheets for creation |
| medium (600–1199 dp) | navigation rail, two panes |
| expanded (≥ 1200 dp) | full sidebar, three-column dashboard, keyboard shortcuts |

Platform affordances (window sizing, menu shortcuts, hover states, pointer cursors, Cupertino
scroll physics on Apple platforms) are layered on through small adapters.

## Consequences
+ One rendering engine gives pixel-consistent custom UI and correct RTL mirroring everywhere.
+ Dart is shared with the progression engine package.
− Web bundle size and first paint need care (deferred loading, CanvasKit vs. Skwasm choice).
− Push notifications on Windows/macOS desktop need platform-specific handling (ADR-007).

## Amendment — desktop through the web app

Native macOS and Windows builds are dropped. Desktop users run the web app in their browser
(installable as a web app), which uses the same expanded layout, keyboard shortcuts and
data. This removes two platform toolchains, two signing and store pipelines, and the desktop
notification gaps, at the cost of background reminders on desktop (the browser shows them
only while the app is open). Supported targets: Android, iOS and Web.
