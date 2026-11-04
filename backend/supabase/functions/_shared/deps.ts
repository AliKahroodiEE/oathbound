/**
 * Third-party dependencies of the Edge Functions, pinned in one place.
 * Edge Functions run on Deno; npm: specifiers are resolved by the runtime.
 */
export { default as Anthropic } from 'npm:@anthropic-ai/sdk@^1.4.0';
export { createClient } from 'npm:@supabase/supabase-js@^2.118.0';
export type { SupabaseClient } from 'npm:@supabase/supabase-js@^2.118.0';
