-- ============================================================
-- Wave 1 additions. Run this in Supabase SQL Editor AFTER the
-- original setup SQL. Safe to run once.
-- ============================================================

-- --- Messages: scheduling + QR ---
alter table messages add column if not exists start_at   timestamptz;  -- null = show immediately
alter table messages add column if not exists end_at     timestamptz;  -- null = never expires
alter table messages add column if not exists qr_url     text;         -- optional: show a QR code for this link

-- --- Welcomes: auto-expire ---
alter table welcomes add column if not exists expires_at timestamptz;  -- null = stays until hidden/deleted

-- --- Board settings: emergency banner + countdown config ---
alter table board_settings add column if not exists emergency_on   boolean default false;
alter table board_settings add column if not exists emergency_text text;
alter table board_settings add column if not exists show_countdown boolean default false;
alter table board_settings add column if not exists countdown_label text;
alter table board_settings add column if not exists countdown_date  timestamptz;
alter table board_settings add column if not exists show_birthdays  boolean default false;

-- --- People table: birthdays + anniversaries ---
create table if not exists people (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  kind text default 'birthday',   -- birthday | anniversary
  month int not null,             -- 1-12
  day int not null,               -- 1-31
  year int,                       -- optional, for "X years" on anniversaries
  active boolean default true,
  created_at timestamptz default now()
);
alter table people enable row level security;
create policy "anon people" on people for all using (true) with check (true);
