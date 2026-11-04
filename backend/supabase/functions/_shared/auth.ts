/**
 * Caller authentication for Edge Functions.
 *
 * - End users present their Supabase access token (JWT); it is verified
 *   with the Auth server (`auth.getUser`), which also rejects revoked
 *   sessions — the gateway's signature check alone would not.
 * - Internal callers (pg_cron via pg_net, Database Webhooks, other
 *   functions) present the service-role key as a bearer token, or the
 *   optional INTERNAL_FUNCTION_SECRET in `x-internal-secret`.
 */
import { HttpError } from './http.ts';
import { adminClient, optionalEnv } from './supabase.ts';

export type Caller = { kind: 'user'; userId: string } | { kind: 'service' };

function bearerToken(req: Request): string | null {
  const header = req.headers.get('Authorization') ?? '';
  const match = /^Bearer\s+(.+)$/i.exec(header.trim());
  return match ? (match[1] as string).trim() : null;
}

/** Constant-time string comparison (avoids leaking secrets through timing). */
export function timingSafeEqual(a: string, b: string): boolean {
  const x = new TextEncoder().encode(a);
  const y = new TextEncoder().encode(b);
  let diff = x.length ^ y.length;
  const length = Math.max(x.length, y.length);
  for (let i = 0; i < length; i++) diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  return diff === 0;
}

export function isServiceRequest(req: Request): boolean {
  const token = bearerToken(req);
  const serviceKey = optionalEnv('SUPABASE_SERVICE_ROLE_KEY');
  if (token !== null && serviceKey !== null && timingSafeEqual(token, serviceKey)) return true;
  const secret = optionalEnv('INTERNAL_FUNCTION_SECRET');
  const presented = req.headers.get('x-internal-secret');
  return secret !== null && presented !== null && timingSafeEqual(presented, secret);
}

export async function authenticate(req: Request, options: { allowService: boolean }): Promise<Caller> {
  if (options.allowService && isServiceRequest(req)) return { kind: 'service' };
  const token = bearerToken(req);
  if (token === null) throw new HttpError(401, 'unauthorized', 'Missing bearer token.');
  const { data, error } = await adminClient().auth.getUser(token);
  if (error || !data.user) throw new HttpError(401, 'unauthorized', 'Invalid or expired session.');
  return { kind: 'user', userId: data.user.id };
}

export async function requireUser(req: Request): Promise<string> {
  const caller = await authenticate(req, { allowService: false });
  if (caller.kind !== 'user') throw new HttpError(401, 'unauthorized');
  return caller.userId;
}

export function requireService(req: Request): void {
  if (!isServiceRequest(req)) throw new HttpError(401, 'unauthorized', 'Internal endpoint.');
}
