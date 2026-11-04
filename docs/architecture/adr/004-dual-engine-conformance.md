# ADR-004 — One rulebook, two engines, shared conformance vectors

Status: Accepted · 2026-11-04

## Context
The deterministic progression engine must run on the client (offline/provisional results,
previews, level curves) and on the server (authoritative grants). The server runtime is Deno
(ADR-002); the client is Dart. Options: compile Dart to JS/Wasm for Deno; implement rules in
PL/pgSQL only; implement twice.

## Decision
Implement the engine as a small, pure, dependency-free module in both languages:
`packages/oathbound_engine` (Dart) and `backend/supabase/functions/_shared/engine/` (TS).
Both test suites load the same JSON **conformance vectors**
(`packages/oathbound_engine/test/vectors/*.json`): inputs and the exact expected output.
CI fails if either implementation disagrees with a vector. Every rule change bumps
`RULES_VERSION`, adds vectors, and is recorded in the ledger.

Dart→JS compilation was rejected: brittle interop, large output, hard debugging in the
function runtime. PL/pgSQL-only was rejected: the client still needs the rules offline.

## Consequences
+ Each implementation is idiomatic and debuggable.
+ The vectors double as executable documentation of the rulebook.
− Changes must be made twice; mitigated by keeping the engine small (~400 lines) and
  vector-driven.
