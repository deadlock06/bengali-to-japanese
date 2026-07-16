-- SENSEI cloud sync schema (Supabase Postgres) — v1, 2026-07-16 (D-018).
-- Mirrors docs/07_API_SYNC: OPTIONAL delta sync of learner progress; the app
-- is offline-first and fully degrades without this. Device-wins conflicts
-- (client merges: SRS keeps higher stability). 30-day retention after last
-- sync; deletion = instant on request (7-day grace handled client-side).
-- SECURITY: RLS ON EVERY TABLE — a user can only ever touch their own rows
-- (auth.uid() = user_id). No service keys ship in the client.
-- Apply: psql "$SUPABASE_DB_URL" -f supabase/schema.sql   (idempotent)

create table if not exists public.profiles (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  created_at  timestamptz not null default now(),
  last_sync   timestamptz,
  app_version text,
  device_id   text,          -- last device that synced (device-wins hint)
  locale      text default 'bn'
);

-- FSRS card state (06 srs_cards ⊂ cloud mirror; content itself never syncs —
-- it is bundled+verified on device).
create table if not exists public.srs_cards (
  user_id    uuid not null references auth.users (id) on delete cascade,
  card_id    text not null,           -- lesson item id / kana id
  word       text not null default '',
  reading    text not null default '',
  meaning_bn text not null default '',
  stability  double precision not null default 0,
  difficulty double precision not null default 0,
  due_at     timestamptz,
  state      text not null default 'new',   -- new/learning/review/relearning
  updated_at timestamptz not null default now(),
  primary key (user_id, card_id)
);

create table if not exists public.lesson_completions (
  id           bigint generated always as identity primary key,
  user_id      uuid not null references auth.users (id) on delete cascade,
  lesson_id    text not null,
  items        int  not null default 0,
  correct      int  not null default 0,
  hints        int  not null default 0,
  skips        int  not null default 0,
  completed_at timestamptz not null default now()
);
create index if not exists lesson_completions_user_idx
  on public.lesson_completions (user_id, completed_at desc);

create table if not exists public.daily_stats (
  user_id  uuid not null references auth.users (id) on delete cascade,
  day      date not null,
  xp       int not null default 0,
  reviews  int not null default 0,
  minutes  int not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, day)
);

-- Deletion contract (07): request logged, then wiped after grace.
create table if not exists public.deletion_requests (
  user_id      uuid primary key references auth.users (id) on delete cascade,
  requested_at timestamptz not null default now(),
  grace_until  timestamptz not null default now() + interval '7 days'
);

-- updated_at maintenance
create or replace function public.touch_updated_at() returns trigger
language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists srs_cards_touch on public.srs_cards;
create trigger srs_cards_touch before update on public.srs_cards
  for each row execute function public.touch_updated_at();
drop trigger if exists daily_stats_touch on public.daily_stats;
create trigger daily_stats_touch before update on public.daily_stats
  for each row execute function public.touch_updated_at();

-- ── RLS: own-rows-only, everywhere ──────────────────────────────────────────
alter table public.profiles           enable row level security;
alter table public.srs_cards          enable row level security;
alter table public.lesson_completions enable row level security;
alter table public.daily_stats        enable row level security;
alter table public.deletion_requests  enable row level security;

do $$
declare t text;
begin
  foreach t in array array['profiles','srs_cards','lesson_completions',
                           'daily_stats','deletion_requests'] loop
    execute format('drop policy if exists own_rows on public.%I', t);
    execute format(
      'create policy own_rows on public.%I for all
         using (auth.uid() = user_id) with check (auth.uid() = user_id)', t);
  end loop;
end $$;
