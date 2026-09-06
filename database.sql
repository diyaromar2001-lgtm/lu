-- ============================================================
-- PreTalli Coiffure - Setup base de données Supabase
-- ------------------------------------------------------------
-- À exécuter une seule fois dans le SQL Editor de Supabase :
--   1. Créer un projet sur https://supabase.com
--   2. Menu "SQL Editor" -> New query
--   3. Coller tout ce fichier et cliquer sur "Run"
-- ============================================================

-- Table des réservations
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  service_name text not null,
  service_price text not null,
  date date not null,
  time text not null,
  client_name text not null,
  client_phone text not null,
  client_email text,
  client_notes text,
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

-- Index pour retrouver rapidement les créneaux pris par date
create index if not exists bookings_date_time_idx
  on public.bookings (date, time);

-- Sécurité au niveau des lignes (RLS)
-- Autorise la LECTURE des créneaux réservés à tout le monde
-- (nécessaire pour désactiver les horaires déjà pris sur le site public)
alter table public.bookings enable row level security;

drop policy if exists "Public can read booked slots" on public.bookings;
create policy "Public can read booked slots"
  on public.bookings
  for select
  using (true);

-- Autorise l'INSERTION de nouvelles réservations par tout visiteur
drop policy if exists "Public can insert bookings" on public.bookings;
create policy "Public can insert bookings"
  on public.bookings
  for insert
  with check (true);

-- Seul le propriétaire (via le dashboard Supabase / service key)
-- peut mettre à jour ou supprimer des réservations.
drop policy if exists "Owner can update bookings" on public.bookings;
create policy "Owner can update bookings"
  on public.bookings
  for update
  using (auth.role() = 'service_role');

drop policy if exists "Owner can delete bookings" on public.bookings;
create policy "Owner can delete bookings"
  on public.bookings
  for delete
  using (auth.role() = 'service_role');

-- ============================================================
-- NOTE POUR LA PROPRIÉTAIRE :
-- Pour consulter et gérer les réservations (marquer "done",
-- annuler, etc.), utilisez le "Table Editor" ou "Dashboard" de
-- Supabase. Vous pouvez aussi créer une vue "admin" plus tard.
-- ============================================================
