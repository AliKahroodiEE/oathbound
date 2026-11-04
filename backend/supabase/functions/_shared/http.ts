/**
 * HTTP helpers shared by every Edge Function: CORS, JSON responses, typed
 * errors and bounded JSON body parsing.
 */

export const corsHeaders: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-internal-secret',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Max-Age': '86400',
};

/** An error that maps to an HTTP response with a stable machine-readable code. */
export class HttpError extends Error {
  readonly status: number;
  readonly code: string;

  constructor(status: number, code: string, message?: string) {
    super(message ?? code);
    this.name = 'HttpError';
    this.status = status;
    this.code = code;
  }
}

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json; charset=utf-8' },
  });
}

/** Answers CORS preflight requests; returns null for everything else. */
export function preflight(req: Request): Response | null {
  return req.method === 'OPTIONS' ? new Response('ok', { headers: corsHeaders }) : null;
}

export function requirePost(req: Request): void {
  if (req.method !== 'POST') throw new HttpError(405, 'method_not_allowed');
}

/** Converts any thrown value into a response; unexpected errors are logged, not leaked. */
export function errorResponse(error: unknown, context: Record<string, unknown> = {}): Response {
  if (error instanceof HttpError) {
    return json({ error: error.code, message: error.message }, error.status);
  }
  log('error', 'unhandled_error', {
    ...context,
    error: error instanceof Error ? `${error.name}: ${error.message}` : String(error),
  });
  return json({ error: 'internal_error', message: 'Something went wrong.' }, 500);
}

/** Reads a JSON object body of at most `maxBytes`. */
export async function readJsonObject(req: Request, maxBytes = 16_384): Promise<Record<string, unknown>> {
  const text = await req.text();
  if (new TextEncoder().encode(text).length > maxBytes) {
    throw new HttpError(413, 'payload_too_large');
  }
  if (text.trim() === '') return {};
  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch {
    throw new HttpError(400, 'invalid_json');
  }
  if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
    throw new HttpError(400, 'invalid_body', 'The request body must be a JSON object.');
  }
  return parsed as Record<string, unknown>;
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function requireUuid(value: unknown, field: string): string {
  if (typeof value !== 'string' || !UUID.test(value)) {
    throw new HttpError(400, 'invalid_request', `${field} must be a UUID.`);
  }
  return value.toLowerCase();
}

/** Structured, single-line JSON logs (no user content, no secrets). */
export function log(level: 'info' | 'warn' | 'error', event: string, fields: Record<string, unknown> = {}): void {
  const line = JSON.stringify({ level, event, at: new Date().toISOString(), ...fields });
  if (level === 'error') console.error(line);
  else if (level === 'warn') console.warn(line);
  else console.log(line);
}
