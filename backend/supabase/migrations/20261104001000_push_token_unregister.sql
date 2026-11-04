-- =============================================================================
-- Wyrd · unregistering a device from push
--
-- On sign-out the app deletes this device's FCM token row while the session
-- is still valid (push_platform.dart: delete … where token = …), so the
-- account stops receiving pushes on a device it left. The WHERE clause reads
-- the token column, which needs SELECT on it. The push_tokens_select_own and
-- push_tokens_delete_own policies (…_rls.sql) keep both to the caller's own
-- rows; no other column becomes readable.
-- =============================================================================

grant select (token), delete on public.push_tokens to authenticated;
