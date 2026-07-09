---
name: integration-supabase
description: >-
  Supabase integration skill. Auto-activates whenever working with Supabase —
  database queries, tables, RLS policies, auth, storage, edge functions,
  real-time subscriptions, migrations, or the Supabase dashboard. Also
  activates on: postgres, postgresql, supabase, RLS, row level security,
  supabase auth, supabase storage, edge function, supabase CLI, supabase
  migration, pooler, pgvector, realtime, supabase URL, anon key, service role,
  SENSEI cloud sync, 07_API_SYNC, online features, user accounts.
---

# Supabase Integration Guide

## You have Supabase connected to Claude
The Supabase integration gives Claude direct access to your project(s) —
Claude can read schema, query tables, and help debug SQL without copy-pasting.

## How Claude uses this integration
Claude can:
- Browse your tables and schema directly
- Write and validate SQL queries against your real schema
- Help configure RLS (Row Level Security) policies
- Debug edge functions
- Check migration state

## SENSEI — Supabase role
Per `docs/07_API_SYNC.md`, Supabase is the **optional cloud sync backend**:
- Core app works OFFLINE-FIRST — Supabase is never required
- Used for: cross-device sync, cloud backup, anonymous leaderboards (opt-in only)
- Data exported locally before any cloud sync (data autonomy — NON-NEGOTIABLE #5)

## SENSEI cloud sync schema (planned)
```sql
-- User progress sync (opt-in only)
CREATE TABLE sync_progress (
  user_id     UUID REFERENCES auth.users(id),
  word_id     TEXT NOT NULL,
  due         BIGINT,        -- Unix ms
  stability   FLOAT,
  difficulty  FLOAT,
  reps        INT,
  lapses      INT,
  state       INT,
  updated_at  TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, word_id)
);

-- RLS: users can only read/write their own data
ALTER TABLE sync_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own data only" ON sync_progress
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

## Security rules (always apply)
- **RLS on every table** — no exceptions
- **Service role key** never in client code (server/edge-function only)
- **Anon key** is public-safe but still scope with RLS
- User data export: must work independently of Supabase (offline ZIP export)

## Common commands
```bash
# Supabase CLI
supabase login
supabase link --project-ref <ref>
supabase db diff            # see what changed
supabase db push            # apply local migrations to remote
supabase functions deploy   # deploy edge functions
```
