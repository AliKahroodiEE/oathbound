-- =============================================================================
-- Wyrd · live reaction updates without exposing who reacted
--
-- Realtime cannot apply RLS to DELETE events. With public.reactions in the
-- supabase_realtime publication, anyone subscribed to it received the
-- primary key (event_id, user_id, kind) of every removed reaction, in every
-- guild. Reactions leave the publication. Instead, adding or removing a
-- reaction touches its feed event (reactions_changed_at); Realtime filters
-- those UPDATE events through the members-only policy, and the guild hall
-- refetches on them (guild_api.dart, ADR-003).
-- =============================================================================

alter table public.feed_events add column if not exists reactions_changed_at timestamptz;

create or replace function private.touch_feed_event_reactions()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event uuid;
begin
  if tg_op = 'DELETE' then
    v_event := old.event_id;
  else
    v_event := new.event_id;
  end if;
  -- No row when the feed event itself is being deleted (cascade).
  update public.feed_events set reactions_changed_at = now() where id = v_event;
  return null;
end;
$$;

revoke execute on function private.touch_feed_event_reactions() from public;

drop trigger if exists reactions_touch_feed_event on public.reactions;
create trigger reactions_touch_feed_event
  after insert or delete on public.reactions
  for each row execute function private.touch_feed_event_reactions();

do $$
begin
  if exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'reactions'
  ) then
    alter publication supabase_realtime drop table public.reactions;
  end if;
end;
$$;
