-- =============================================================================
-- Wyrd · live reaction updates without exposing who reacted; Realtime
-- publishes only the guild hall
--
-- Realtime cannot apply RLS to DELETE events. With public.reactions in the
-- supabase_realtime publication, anyone subscribed to it received the
-- primary key (event_id, user_id, kind) of every removed reaction, in every
-- guild. Reactions leave the publication. Instead, adding or removing a
-- reaction touches its feed event (reactions_changed_at); Realtime filters
-- those UPDATE events through the members-only policy, and the guild hall
-- refetches on them (guild_api.dart, ADR-003).
--
-- The personal tables leave it too. …_rls.sql published quests, subtasks,
-- completions, ledger_entries, characters, day_stats, achievements and
-- chronicles as pull signals, but clients may not SELECT them since
-- …_data_api_grants.sql (personal data comes only through sync_pull), so
-- Realtime delivered none of their changes and only spent work decoding
-- them from the WAL. What stays is what the app watches (guild_api.dart,
-- watchGuild): feed_events, comments and challenges. Where the publication
-- does not exist, nothing changes.
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
declare
  v_table text;
begin
  foreach v_table in array array[
    'reactions',
    'quests', 'subtasks', 'completions', 'ledger_entries', 'characters', 'day_stats',
    'achievements', 'chronicles'
  ] loop
    if exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = v_table
    ) then
      execute format('alter publication supabase_realtime drop table public.%I', v_table);
    end if;
  end loop;
end;
$$;
