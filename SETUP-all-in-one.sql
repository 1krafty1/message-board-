-- ============================================================
-- Message Board — complete schema in one paste
-- Base + Wave 1 + Wave 2 + Wave 3, in order.
-- Run once on a fresh Supabase project: SQL Editor → New query → paste → Run.
-- ============================================================

-- ---------- BASE ----------

-- Messages
create table messages (
  id uuid primary key default gen_random_uuid(),
  text text not null,
  type text default 'info',          -- info | success | notice | alert
  label text,
  priority int default 0,            -- 1 = high (sorts first)
  active boolean default true,
  created_at timestamptz default now()
);

-- Photos
create table photos (
  id uuid primary key default gen_random_uuid(),
  url text not null,
  caption text,
  active boolean default true,
  created_at timestamptz default now()
);

-- Welcomes
create table welcomes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  subtitle text,
  active boolean default true,
  created_at timestamptz default now()
);

-- Board settings (single row)
create table board_settings (
  id uuid primary key default gen_random_uuid(),
  layout text default 'messages',    -- messages | photo | split | photobg
  show_weather boolean default true,
  show_ticker boolean default true,
  show_welcomes boolean default true
);
insert into board_settings (layout, show_weather, show_ticker, show_welcomes)
values ('messages', true, true, true);

-- RLS + anon access (internal board)
alter table messages enable row level security;
alter table photos enable row level security;
alter table welcomes enable row level security;
alter table board_settings enable row level security;
create policy "anon messages" on messages      for all using (true) with check (true);
create policy "anon photos" on photos           for all using (true) with check (true);
create policy "anon welcomes" on welcomes       for all using (true) with check (true);
create policy "anon settings" on board_settings for all using (true) with check (true);

-- ---------- WAVE 1 — scheduling, QR, emergency, countdown, people ----------

alter table messages add column if not exists start_at   timestamptz;
alter table messages add column if not exists end_at     timestamptz;
alter table messages add column if not exists qr_url     text;
alter table welcomes add column if not exists expires_at timestamptz;
alter table board_settings add column if not exists emergency_on   boolean default false;
alter table board_settings add column if not exists emergency_text text;
alter table board_settings add column if not exists show_countdown boolean default false;
alter table board_settings add column if not exists countdown_label text;
alter table board_settings add column if not exists countdown_date  timestamptz;
alter table board_settings add column if not exists show_birthdays  boolean default false;
create table if not exists people (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  kind text default 'birthday',
  month int not null, day int not null, year int,
  active boolean default true,
  created_at timestamptz default now()
);
alter table people enable row level security;
create policy "anon people" on people for all using (true) with check (true);

-- ---------- WAVE 2 — radar + auto-rotate ----------

alter table board_settings add column if not exists show_radar boolean default false;
alter table board_settings add column if not exists autorotate_on      boolean default false;
alter table board_settings add column if not exists autorotate_layouts text default 'messages,photo';
alter table board_settings add column if not exists autorotate_seconds int default 30;

-- ---------- WAVE 3 — recurring messages + shoutouts ----------

alter table messages add column if not exists days_of_week text;
alter table messages add column if not exists time_start  text;
alter table messages add column if not exists time_end    text;
create table if not exists shoutouts (
  id uuid primary key default gen_random_uuid(),
  recipient text not null, message text not null, from_name text,
  approved boolean default false, active boolean default true,
  created_at timestamptz default now()
);
alter table shoutouts enable row level security;
create policy "anon shoutouts" on shoutouts for all using (true) with check (true);
alter table board_settings add column if not exists show_shoutouts boolean default false;
