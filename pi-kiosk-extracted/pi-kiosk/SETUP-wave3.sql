-- ============================================================
-- Wave 3 additions. Run in Supabase SQL Editor AFTER Wave 2.
-- Safe to run once.
-- ============================================================

-- Recurring messages: day-of-week scheduling.
-- A message becomes recurring if 'days_of_week' is set (e.g. "1,3" = Mon,Wed).
-- Days: 0=Sun 1=Mon 2=Tue 3=Wed 4=Thu 5=Fri 6=Sat
alter table messages add column if not exists days_of_week text;   -- null = not recurring; else CSV like "1,3,5"
alter table messages add column if not exists time_start  text;    -- optional "HH:MM" 24h, show from this time on its days
alter table messages add column if not exists time_end    text;    -- optional "HH:MM" 24h, hide after this time on its days

-- Shoutouts: curated recognition panel (you post; approval flag stages them)
create table if not exists shoutouts (
  id uuid primary key default gen_random_uuid(),
  recipient   text not null,        -- who's being recognized
  message     text not null,        -- the kudos
  from_name   text,                 -- optional "from ___"
  approved    boolean default false,-- false = staged, true = shows on board
  active      boolean default true,
  created_at  timestamptz default now()
);
alter table shoutouts enable row level security;
create policy "anon shoutouts" on shoutouts for all using (true) with check (true);

-- Strip toggle for the shoutouts panel
alter table board_settings add column if not exists show_shoutouts boolean default false;
