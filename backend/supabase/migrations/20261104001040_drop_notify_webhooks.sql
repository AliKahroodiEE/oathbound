-- =============================================================================
-- Wyrd · retiring the dashboard notification webhooks
--
-- Before …_notify_triggers.sql, the README told owners to create three
-- Database Webhooks in the dashboard: INSERT on public.reactions,
-- public.comments and public.feed_events, POST to /functions/v1/notify. A
-- Database Webhook is a trigger that runs supabase_functions.http_request
-- with the URL among its arguments; next to our own triggers it would send
-- every push twice. This drops every such trigger on those three tables.
-- Our triggers (private.notify_on_insert) and webhooks to any other URL
-- stay. Where the supabase_functions schema does not exist (no webhook was
-- ever created, or PGlite in the validator) nothing matches.
-- =============================================================================

do $$
declare
  v_hook record;
begin
  for v_hook in
    select t.tgname, c.relname
    from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    join pg_proc p on p.oid = t.tgfoid
    join pg_namespace pn on pn.oid = p.pronamespace
    where n.nspname = 'public'
      and c.relname in ('reactions', 'comments', 'feed_events')
      and not t.tgisinternal
      and pn.nspname = 'supabase_functions' and p.proname = 'http_request'
      -- tgargs: the trigger arguments (URL, method, headers, …), each NUL-terminated.
      and position(convert_to('/functions/v1/notify', 'UTF8') in t.tgargs) > 0
  loop
    execute format('drop trigger %I on public.%I', v_hook.tgname, v_hook.relname);
    raise notice 'dropped dashboard webhook % on public.%: the notify triggers replace it',
      v_hook.tgname, v_hook.relname;
  end loop;
end;
$$;
