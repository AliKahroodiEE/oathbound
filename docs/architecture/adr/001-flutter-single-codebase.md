# ADR-001 — Flutter as the single client codebase

Status: Accepted · 2026-11-04

## Context
Oathbound must ship on Android, iOS, macOS, Windows and Web with identical business logic,
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
