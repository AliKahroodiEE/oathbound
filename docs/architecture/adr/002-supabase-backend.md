# ADR-002 — Supabase as the backend platform

Status: Accepted · 2026-11-04

## Context
Requirements: relational data (guilds, memberships, challenges, ledgers, analytics), strict
per-row access control for private tasks, realtime updates across devices, social auth incl.
Sign in with Apple, server-side AI calls with secret keys, scheduled jobs (chronicles,
snapshots), file storage (portraits, emblems), modest ops burden for a small team.

## Options

| Option | For | Against |
| --- | --- | --- |
| **Supabase** | Postgres (SQL analytics, constraints, transactions), RLS, Realtime, Auth, Edge Functions, Storage, pg_cron; open source and self-hostable; mature Flutter SDK | Edge Functions are TypeScript (engine must be ported, see ADR-004); Realtime fan-out limits for very large public guilds |
| Firebase | Excellent mobile SDKs, FCM, offline Firestore | Document model is a poor fit for ledgers and cross-entity analytics; security rules cannot express joins well; vendor lock-in |
| Serverpod (Dart) | Shared Dart models and engine | Self-managed infrastructure, smaller ecosystem, auth/realtime/storage less turnkey |
| Custom (Go/Node + Postgres) | Full control | Highest build and ops cost for M0–M2 |

## Decision
Supabase, using: Postgres with RLS on every table; `SECURITY DEFINER` RPCs for all
privileged writes; Realtime (Postgres changes) as a "something changed" signal; Auth with
email, magic link, Apple and Google; Edge Functions for AI and push; pg_cron for scheduled
work; Storage for images.

## Consequences
+ Privacy rules live next to the data and are testable with SQL.
+ Self-hosting remains possible if pricing or data residency requires it.
− Two languages on the critical path (Dart, TypeScript), mitigated by conformance vectors.
− Public guild feeds above ~5 000 members will need a fan-out-on-read projection (M4).
