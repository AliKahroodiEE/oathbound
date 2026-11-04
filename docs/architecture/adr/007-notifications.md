# ADR-007 — Notifications

Status: Accepted · 2026-11-04

## Decision
- **Reminders** are scheduled locally on each device (`flutter_local_notifications`) from the
  synced quest data, so they work offline and need no server. On the web, reminders fire only
  while a tab is open (Notification API); the settings screen says so.
- **Social and summary notifications** (reactions, comments, milestones, weekly summary,
  briefing) are sent by the `notify` Edge Function through FCM (Android, iOS via APNs, Web
  Push). Desktop users run the web app, which shows these while it is open.
- The server enforces, per user: category toggles, per-guild mute, block list, quiet hours
  in the user's time zone (default 22:00–08:00), and a daily cap on non-reminder
  notifications (default 5). Reactions are batched ("Arin and 3 others honoured your deed").
- No notification is ever sent to re-engage an inactive user more than once per 7 days, and
  never with loss framing.
