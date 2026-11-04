/**
 * Firebase Cloud Messaging HTTP v1 transport (ADR-007). FCM is used only as
 * a transport: content, caps and quiet hours are decided in notify/index.ts.
 *
 * Credentials: the `FCM_SERVICE_ACCOUNT` secret holds a Google service
 * account JSON key (raw JSON or base64 of it) with the
 * "Firebase Cloud Messaging API" permission. Access tokens are minted with a
 * self-signed RS256 JWT (Web Crypto) and cached until shortly before expiry.
 */
import { log } from '../_shared/http.ts';
import { optionalEnv } from '../_shared/supabase.ts';

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri?: string;
}

export interface PushMessage {
  token: string;
  title: string;
  body: string;
  /** String-only key/value data for the client (category, ids for deep links). */
  data: Record<string, string>;
  /** Groups related notifications (APNs thread-id / Android tag). */
  thread: string;
}

export type PushResult = 'sent' | 'unregistered' | 'failed';

let cachedAccount: ServiceAccount | null | undefined;
let cachedToken: { value: string; expiresAt: number } | null = null;

export function serviceAccount(): ServiceAccount | null {
  if (cachedAccount !== undefined) return cachedAccount;
  const raw = optionalEnv('FCM_SERVICE_ACCOUNT');
  if (raw === null) {
    cachedAccount = null;
    return null;
  }
  try {
    const text = raw.startsWith('{') ? raw : new TextDecoder().decode(Uint8Array.from(atob(raw), (c) => c.charCodeAt(0)));
    const parsed = JSON.parse(text) as Partial<ServiceAccount>;
    if (!parsed.project_id || !parsed.client_email || !parsed.private_key) throw new Error('incomplete key');
    cachedAccount = parsed as ServiceAccount;
  } catch (error) {
    log('error', 'fcm_service_account_invalid', { error: String(error) });
    cachedAccount = null;
  }
  return cachedAccount;
}

function base64Url(bytes: Uint8Array | string): string {
  const data = typeof bytes === 'string' ? new TextEncoder().encode(bytes) : bytes;
  let binary = '';
  for (const b of data) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function pemToPkcs8(pem: string): ArrayBuffer {
  const body = pem.replace(/-----(BEGIN|END) PRIVATE KEY-----/g, '').replace(/\s+/g, '');
  const bytes = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  return bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength) as ArrayBuffer;
}

async function accessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt - 60 > now) return cachedToken.value;

  const tokenUri = account.token_uri ?? 'https://oauth2.googleapis.com/token';
  const header = base64Url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claims = base64Url(JSON.stringify({
    iss: account.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: tokenUri,
    iat: now,
    exp: now + 3600,
  }));
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToPkcs8(account.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${header}.${claims}`)),
  );
  const assertion = `${header}.${claims}.${base64Url(signature)}`;

  const response = await fetch(tokenUri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }),
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok) throw new Error(`FCM token exchange failed with status ${response.status}`);
  const token = await response.json() as { access_token: string; expires_in: number };
  cachedToken = { value: token.access_token, expiresAt: now + token.expires_in };
  return token.access_token;
}

export async function sendPush(account: ServiceAccount, message: PushMessage): Promise<PushResult> {
  const token = await accessToken(account);
  const response = await fetch(`https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message: {
        token: message.token,
        notification: { title: message.title, body: message.body },
        data: message.data,
        android: { priority: 'normal', notification: { tag: message.thread } },
        apns: { payload: { aps: { 'thread-id': message.thread } } },
        webpush: { headers: { Urgency: 'normal' } },
      },
    }),
    signal: AbortSignal.timeout(10_000),
  });
  if (response.ok) return 'sent';
  const detail = await response.text();
  // NOT_FOUND / UNREGISTERED (and malformed tokens) mean the token is dead.
  if (response.status === 404 || /UNREGISTERED|registration-token-not-registered/i.test(detail)) {
    return 'unregistered';
  }
  if (response.status === 400 && /INVALID_ARGUMENT/.test(detail) && /token/i.test(detail)) {
    return 'unregistered';
  }
  log('warn', 'fcm_send_failed', { status: response.status });
  return 'failed';
}
