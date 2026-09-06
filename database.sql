-- ============================================================
-- PreTalli Coiffure - Setup base de données Supabase
-- ------------------------------------------------------------
-- À exécuter UNE SEULE FOIS dans le SQL Editor de Supabase :
--   1. Sur https://supabase.com, ouvre ton projet
--   2. Menu "SQL Editor" -> New query
--   3. Colle tout ce fichier puis clique sur "Run"
-- ============================================================

-- ------------------------------------------------------------
-- 1. Table des réservations
-- ------------------------------------------------------------
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

create index if not exists bookings_date_time_idx
  on public.bookings (date, time);

-- ------------------------------------------------------------
-- 2. Table des administrateurs (emails qui ont accès à l'admin)
-- ------------------------------------------------------------
create table if not exists public.admins (
  email text primary key
);

-- ⬇️ IMPORTANT : remplace ceci par TON email (celui avec lequel
--    tu te connecteras à la page admin) puis exécute le script.
insert into public.admins (email)
values ('CHANGE-MOI@exemple.com')
on conflict (email) do nothing;

-- ------------------------------------------------------------
-- 3. Sécurité au niveau des lignes (RLS)
-- ------------------------------------------------------------
alter table public.bookings enable row level security;

-- ---- PUBLIC (visiteurs du site) ----
-- Le public peut seulement : créer une réservation
drop policy if exists "Public can insert bookings" on public.bookings;
create policy "Public can insert bookings"
  on public.bookings
  for insert
  with check (true);

-- Le public ne peut PLUS lire la table directement
-- (les créneaux occupés passent par la vue public_slots ci-dessous)
drop policy if exists "Public can read booked slots" on public.bookings;

-- ---- ADMIN (personnes inscrites dans la table admins) ----
drop policy if exists "Admin can read bookings" on public.bookings;
create policy "Admin can read bookings"
  on public.bookings
  for select
  using (auth.jwt() ->> 'email' in (select email from public.admins));

drop policy if exists "Admin can update bookings" on public.bookings;
create policy "Admin can update bookings"
  on public.bookings
  for update
  using (auth.jwt() ->> 'email' in (select email from public.admins));

drop policy if exists "Admin can delete bookings" on public.bookings;
create policy "Admin can delete bookings"
  on public.bookings
  for delete
  using (auth.jwt() ->> 'email' in (select email from public.admins));

-- ------------------------------------------------------------
-- 4. Vue publique : créneaux déjà réservés (sans données clients)
--    Le site l'interroge pour griser les heures prises.
-- ------------------------------------------------------------
create or replace view public.public_slots as
  select date, time
  from public.bookings
  where status <> 'cancelled';

grant select on public.public_slots to anon, authenticated;
grant select on public.bookings to authenticated;

-- La table admins n'est pas lisible par le public
revoke all on public.admins from anon;

-- ============================================================
-- NOTE : pour que le site public ECRIVE et l'admin LISE,
-- l'API Supabase a besoin de droits sur les tables.
-- Les clés "publishable/anon" ont déjà ces droits par défaut
-- via "Automatically expose new tables".
-- ============================================================