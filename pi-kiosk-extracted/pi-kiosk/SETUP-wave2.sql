-- ============================================================
-- Wave 2 additions. Run in Supabase SQL Editor AFTER Wave 1.
-- Safe to run once.
-- ============================================================

-- Radar strip panel toggle
alter table board_settings add column if not exists show_radar boolean default false;

-- Auto-rotate layouts: master toggle + which layouts to include + seconds each
alter table board_settings add column if not exists autorotate_on      boolean default false;
alter table board_settings add column if not exists autorotate_layouts text default 'messages,photo';  -- comma list: messages,photo,split,photobg
alter table board_settings add column if not exists autorotate_seconds int default 30;
