/**
 * Claude access for Edge Functions (ADR-005).
 *
 * - Official SDK, key from the `ANTHROPIC_API_KEY` function secret.
 * - Model per route from `AI_EVALUATION_MODEL` / `AI_CHRONICLE_MODEL`,
 *   defaulting to claude-opus-5-5. The operator chooses the model.
 * - Structured output (`output_config.format` JSON schema); the caller still
 *   re-validates everything.
 * - The static system prompt is sent as a cached block (prompt caching);
 *   per-request content comes after the cache breakpoint.
 * - Server-side refusal fallback (`fallbacks: "default"`) is on unless
 *   `AI_SERVER_FALLBACKS=off`; a final `stop_reason: "refusal"` is treated
 *   as a failure and the caller falls back to deterministic output.
 * - Hard timeout per attempt and exactly one SDK retry (429/5xx/network).
 */
import { Anthropic } from '../deps.ts';
import { log } from '../http.ts';
import { optionalEnv } from '../supabase.ts';

export const DEFAULT_MODEL = 'claude-opus-5-5';

export type AiRoute = 'evaluation' | 'chronicle';

export type AiFailureReason =
  | 'not_configured'
  | 'refusal'
  | 'max_tokens'
  | 'no_output'
  | 'invalid_json'
  | 'timeout'
  | 'rate_limited'
  | 'api_error';

export type StructuredOutcome =
  | { ok: true; value: unknown; model: string; latencyMs: number }
  | { ok: false; reason: AiFailureReason; detail?: string; latencyMs: number };

export interface StructuredRequest {
  route: AiRoute;
  /** Static, byte-identical across requests so it can be cached. */
  system: string;
  /** Per-request content (after the cache breakpoint). */
  user: string;
  schema: Record<string, unknown>;
  effort: 'low' | 'medium' | 'high';
  /** Covers thinking and the answer (thinking counts towards max_tokens). */
  maxTokens: number;
  timeoutMs: number;
}

export function aiConfigured(): boolean {
  return optionalEnv('ANTHROPIC_API_KEY') !== null;
}

export function modelFor(route: AiRoute): string {
  return optionalEnv(route === 'evaluation' ? 'AI_EVALUATION_MODEL' : 'AI_CHRONICLE_MODEL') ?? DEFAULT_MODEL;
}

function serverFallbacksEnabled(): boolean {
  return (optionalEnv('AI_SERVER_FALLBACKS') ?? 'on').toLowerCase() !== 'off';
}

let client: InstanceType<typeof Anthropic> | null = null;

function anthropic(): InstanceType<typeof Anthropic> {
  if (client === null) {
    client = new Anthropic({ apiKey: optionalEnv('ANTHROPIC_API_KEY') ?? undefined });
  }
  return client;
}

/**
 * Sends one structured-output request. Never throws: every failure is
 * returned as a reason so callers can fall back deterministically.
 */
export async function requestStructured(request: StructuredRequest): Promise<StructuredOutcome> {
  const started = Date.now();
  if (!aiConfigured()) {
    return { ok: false, reason: 'not_configured', latencyMs: 0 };
  }
  const model = modelFor(request.route);
  const fallbacks = serverFallbacksEnabled();

  const params: Anthropic.Beta.Messages.MessageCreateParamsNonStreaming = {
    model,
    max_tokens: request.maxTokens,
    system: [{ type: 'text', text: request.system, cache_control: { type: 'ephemeral' } }],
    messages: [{ role: 'user', content: request.user }],
    output_config: {
      effort: request.effort,
      format: { type: 'json_schema', schema: request.schema },
    },
    ...(fallbacks ? { betas: ['server-side-fallback-2026-07-01'], fallbacks: 'default' as const } : {}),
  };

  try {
    const message = await anthropic().beta.messages.create(params, {
      timeout: request.timeoutMs,
      maxRetries: 1,
    });
    const latencyMs = Date.now() - started;
    log('info', 'ai_response', {
      route: request.route,
      requested_model: model,
      served_model: message.model,
      stop_reason: message.stop_reason,
      latency_ms: latencyMs,
      input_tokens: message.usage.input_tokens,
      output_tokens: message.usage.output_tokens,
      cache_read_input_tokens: message.usage.cache_read_input_tokens,
      cache_creation_input_tokens: message.usage.cache_creation_input_tokens,
    });

    // Check the stop reason before reading content: a refusal may carry an
    // empty or partial body.
    if (message.stop_reason === 'refusal') {
      return {
        ok: false,
        reason: 'refusal',
        detail: message.stop_details?.category ?? undefined,
        latencyMs,
      };
    }
    if (message.stop_reason === 'max_tokens') {
      return { ok: false, reason: 'max_tokens', latencyMs };
    }

    // Read by block type: thinking and fallback blocks may precede the answer.
    const text = message.content
      .flatMap((block) => (block.type === 'text' ? [block.text] : []))
      .join('')
      .trim();
    if (text === '') return { ok: false, reason: 'no_output', latencyMs };
    try {
      return { ok: true, value: JSON.parse(text), model: message.model, latencyMs };
    } catch {
      return { ok: false, reason: 'invalid_json', latencyMs };
    }
  } catch (error) {
    const latencyMs = Date.now() - started;
    let reason: AiFailureReason = 'api_error';
    let detail: string | undefined;
    if (error instanceof Anthropic.APIConnectionTimeoutError) {
      reason = 'timeout';
    } else if (error instanceof Anthropic.RateLimitError) {
      reason = 'rate_limited';
    } else if (error instanceof Anthropic.APIError) {
      detail = `status ${error.status ?? 'n/a'}`;
    } else if (error instanceof Error) {
      detail = error.name;
    }
    log('warn', 'ai_request_failed', { route: request.route, model, reason, detail, latency_ms: latencyMs });
    return { ok: false, reason, detail, latencyMs };
  }
}
