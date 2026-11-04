# ADR-005 — AI evaluation: Claude proposes, the engine decides

Status: Accepted · 2026-11-04

## Context
AI must interpret free-text tasks in any language (English, Persian, mixed), choose
attributes and difficulty, and explain the result in the user's AI language. It must not be
able to grant arbitrary XP, and the product must keep working when AI is unavailable or
disabled by the user.

## Decision
- **Provider:** Anthropic Messages API, called only from Edge Functions using the official
  TypeScript SDK (`npm:@anthropic-ai/sdk`). Keys live in function secrets.
- **Model:** configurable per route via environment (`AI_EVALUATION_MODEL`,
  `AI_CHRONICLE_MODEL`), defaulting to `claude-opus-5-5`. Evaluation runs at low effort
  (short classification-style task); chronicles at medium effort. The model and effort are
  operator decisions and can be changed without a client release; cost and quality are
  tracked per route.
- **Structured output:** responses are constrained to the proposal JSON schema
  (progression-rules §3) and re-validated server-side; any violation triggers the
  deterministic heuristic evaluator.
- **Prompt caching:** the system prompt (rubric, schema, guardrails) is static and cached;
  per-request content follows the cache breakpoint.
- **Grounding for chronicles:** the function first computes a facts object (totals,
  records, top activities, attribute deltas) with SQL; the model may only narrate those
  facts. The facts are stored with the chronicle for audit.
- **Data minimisation:** only the fields listed in progression-rules §8.2 are sent. No
  identity data, no other users' data.
- **Language:** outputs in `profiles.ai_locale`; user-authored text is never translated.
- **Failure policy:** 8-second timeout, one retry on 5xx/429 with backoff, then heuristic
  fallback. Completion is never blocked by AI.
- **Refusals:** a `refusal` stop reason is treated like a failure (heuristic fallback); the
  server-side fallback beta is enabled where the model supports it.

## Consequences
+ Rewards are fair, bounded and auditable regardless of model behaviour.
+ Users can opt out of AI and still use the full product.
− AI cost scales with completions; mitigated by caching identical proposals for 7 days and
  per-user daily evaluation limits.
