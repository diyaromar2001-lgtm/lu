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

-- L'admin a besoin de lire la table admins pour vérifier son accès
grant select on public.admins to authenticated;

-- La table admins n'est pas lisible par le public
revoke all on public.admins from anon;

-- ============================================================
-- NOTE : pour que le site public ECRIVE et l'admin LISE,
-- l'API Supabase a besoin de droits sur les tables.
-- Les clés "publishable/anon" ont déjà ces droits par défaut
-- via "Automatically expose new tables".
-- ============================================================

-- ------------------------------------------------------------
-- 5. Galerie photos (vitrine)
-- ------------------------------------------------------------
create table if not exists public.gallery (
  id uuid primary key default gen_random_uuid(),
  url text not null,
  caption text default '',
  sort_order int default 0,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 6. Réglages du site vitrine (couleurs, textes, horaires, image)
-- ------------------------------------------------------------
create table if not exists public.settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 7. Créneaux bloqués (masqués aux clients)
-- ------------------------------------------------------------
create table if not exists public.blocked_slots (
  id uuid primary key default gen_random_uuid(),
  date date not null,
  time text not null,
  note text default '',
  created_at timestamptz not null default now(),
  unique (date, time)
);

-- Vue publique : crée aussi la liste des créneaux à masquer aux clients
-- (réservés + bloqués). public_slots ne contient que date/heure.
create or replace view public.public_slots as
  select date, time from public.bookings where status <> 'cancelled'
  union
  select date, time from public.blocked_slots;

-- ------------------------------------------------------------
-- Sécurité (RLS) des nouvelles tables
-- ------------------------------------------------------------
alter table public.gallery enable row level security;
alter table public.settings enable row level security;
alter table public.blocked_slots enable row level security;

-- Galerie : tout le monde lit, seul un utilisateur connecté écrit
drop policy if exists "gallery public read" on public.gallery;
create policy "gallery public read" on public.gallery for select using (true);
drop policy if exists "gallery auth insert" on public.gallery;
create policy "gallery auth insert" on public.gallery for insert with check (auth.role() = 'authenticated');
drop policy if exists "gallery auth update" on public.gallery;
create policy "gallery auth update" on public.gallery for update using (auth.role() = 'authenticated');
drop policy if exists "gallery auth delete" on public.gallery;
create policy "gallery auth delete" on public.gallery for delete using (auth.role() = 'authenticated');

-- Réglages : tout le monde lit, seul un utilisateur connecté écrit
drop policy if exists "settings public read" on public.settings;
create policy "settings public read" on public.settings for select using (true);
drop policy if exists "settings auth insert" on public.settings;
create policy "settings auth insert" on public.settings for insert with check (auth.role() = 'authenticated');
drop policy if exists "settings auth update" on public.settings;
create policy "settings auth update" on public.settings for update using (auth.role() = 'authenticated');
drop policy if exists "settings auth delete" on public.settings;
create policy "settings auth delete" on public.settings for delete using (auth.role() = 'authenticated');

-- Créneaux bloqués : tout le monde lit (pour la vue), seul un connecté ajoute/supprime
drop policy if exists "blocked public read" on public.blocked_slots;
create policy "blocked public read" on public.blocked_slots for select using (true);
drop policy if exists "blocked auth insert" on public.blocked_slots;
create policy "blocked auth insert" on public.blocked_slots for insert with check (auth.role() = 'authenticated');
drop policy if exists "blocked auth delete" on public.blocked_slots;
create policy "blocked auth delete" on public.blocked_slots for delete using (auth.role() = 'authenticated');

grant select on public.gallery to anon, authenticated;
grant select on public.settings to anon, authenticated;
grant select on public.blocked_slots to anon, authenticated;
grant select, insert, update, delete on public.gallery to authenticated;
grant select, insert, update, delete on public.settings to authenticated;
grant select, insert, delete on public.blocked_slots to authenticated;

-- ------------------------------------------------------------
-- 8. Stockage photos (bucket "photos", public)
-- ------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict (id) do nothing;

drop policy if exists "photos public read" on storage.objects;
create policy "photos public read" on storage.objects
  for select using (bucket_id = 'photos');
drop policy if exists "photos auth insert" on storage.objects;
create policy "photos auth insert" on storage.objects
  for insert with check (bucket_id = 'photos' and auth.role() = 'authenticated');
drop policy if exists "photos auth update" on storage.objects;
create policy "photos auth update" on storage.objects
  for update using (bucket_id = 'photos' and auth.role() = 'authenticated');
drop policy if exists "photos auth delete" on storage.objects;
create policy "photos auth delete" on storage.objects
  for delete using (bucket_id = 'photos' and auth.role() = 'authenticated');

-- ------------------------------------------------------------
-- 9. Réglages par défaut (optionnel)
-- ------------------------------------------------------------
insert into public.settings (key, value) values
('site_content', '{
  "hero_image": "",
  "logo_url": "",
  "colors": {
    "accent": "#c9a87c",
    "accent_dark": "#b8935f",
    "bg": "#faf8f5",
    "dark": "#1a1512",
    "about": "",
    "services": "",
    "gallery": "",
    "booking": "",
    "reviews": "",
    "contact": "",
    "cta": "",
    "footer": ""
  },
  "texts": {
    "hero_badge": "",
    "hero_title": "",
    "hero_subtitle": "",
    "about_label": "",
    "about_title": "",
    "about_text": "",
    "services_label": "",
    "services_title": "",
    "services_subtitle": "",
    "gallery_label": "",
    "gallery_title": "",
    "booking_label": "",
    "booking_title": "",
    "booking_subtitle": "",
    "reviews_label": "",
    "reviews_title": "",
    "contact_label": "",
    "contact_title": "",
    "cta_title": "",
    "cta_text": ""
  },
  "hours": {
    "0": null,
    "1": null,
    "2": ["09:00", "19:00"],
    "3": ["09:00", "19:00"],
    "4": ["09:00", "19:00"],
    "5": ["09:00", "19:00"],
    "6": ["08:00", "14:00"]
  },
  "promo": {
    "enabled": false,
    "text": "",
    "link": "",
    "color": "",
    "text_color": ""
  }
}'::jsonb)
on conflict (key) do nothing;

-- ------------------------------------------------------------
-- 10. Prestations & prix (gérés depuis l'admin)
-- ------------------------------------------------------------
create table if not exists public.services (
  id text primary key,
  name text not null,
  cat text not null,
  price text not null,
  duration int not null,
  sort_order int default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.services enable row level security;

-- Tout le monde lit les prestations, un connecté les modifie
drop policy if exists "services public read" on public.services;
create policy "services public read" on public.services for select using (true);
drop policy if exists "services auth insert" on public.services;
create policy "services auth insert" on public.services for insert with check (auth.role() = 'authenticated');
drop policy if exists "services auth update" on public.services;
create policy "services auth update" on public.services for update using (auth.role() = 'authenticated');
drop policy if exists "services auth delete" on public.services;
create policy "services auth delete" on public.services for delete using (auth.role() = 'authenticated');

grant select on public.services to anon, authenticated;
grant select, insert, update, delete on public.services to authenticated;

-- Prestations par défaut (modifiables ensuite depuis l'admin)
insert into public.services (id, name, cat, price, duration, sort_order) values
('balayage', 'Forfait Balayage', 'Balayage', '220 CHF', 180, 1),
('refresh', 'Forfait Refresh Balayage', 'Balayage', '170 CHF', 150, 2),
('patine', 'Forfait Patine', 'Balayage', '118 CHF', 120, 3),
('meche-court', 'Forfait Mèche cheveux court', 'Balayage', '105 CHF', 90, 4),
('racine', 'Coloration Racine', 'Coloration', '48 CHF', 90, 5),
('color-total', 'Coloration totale', 'Coloration', '58 CHF', 120, 6),
('coupe-brushing', 'Coupe & Brushing', 'Coupe & Brushing', 'À partir de 55 CHF', 60, 7),
('brushing', 'Brushing', 'Coupe & Brushing', 'À partir de 49 CHF', 45, 8),
('cut-go', 'Cut and Go', 'Coupe & Brushing', '20 CHF', 20, 9)
on conflict (id) do nothing;

-- ------------------------------------------------------------
-- 11. Fiches clientes (historique & suivi)
-- ------------------------------------------------------------
-- Chaque réservation est rattachée à une fiche (créée automatiquement
-- par numéro de téléphone). Vous pouvez noter la formule de chaque
-- cliente (coloration, soin...) et voir son historique.
create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text not null unique,
  email text,
  notes text default '',
  visit_count int not null default 0,
  last_service text,
  last_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Lien vers la fiche cliente sur les réservations existantes
alter table public.bookings add column if not exists client_id uuid references public.clients(id) on delete set null;

-- Remplit les fiches à partir des réservations déjà enregistrées
insert into public.clients (name, phone, email, visit_count, last_service, last_date)
select
  (array_agg(b.client_name order by b.date desc, b.time desc))[1] as name,
  b.client_phone as phone,
  (array_agg(b.client_email order by b.date desc, b.time desc) filter (where b.client_email is not null))[1] as email,
  count(*) as visit_count,
  (array_agg(b.service_name order by b.date desc, b.time desc))[1] as last_service,
  (array_agg(b.date order by b.date desc, b.time desc))[1] as last_date
from public.bookings b
where b.status <> 'cancelled'
group by b.client_phone
on conflict (phone) do nothing;

-- Lie les réservations existantes à leur fiche cliente
update public.bookings b
set client_id = c.id
from public.clients c
where b.client_phone = c.phone and b.client_id is null;

alter table public.clients enable row level security;

-- Seul l'administrateur (connecté) voit et modifie les fiches clientes
drop policy if exists "clients auth select" on public.clients;
create policy "clients auth select" on public.clients for select using (auth.role() = 'authenticated');
drop policy if exists "clients auth insert" on public.clients;
create policy "clients auth insert" on public.clients for insert with check (auth.role() = 'authenticated');
drop policy if exists "clients auth update" on public.clients;
create policy "clients auth update" on public.clients for update using (auth.role() = 'authenticated');
drop policy if exists "clients auth delete" on public.clients;
create policy "clients auth delete" on public.clients for delete using (auth.role() = 'authenticated');

grant select, insert, update, delete on public.clients to authenticated;

-- ------------------------------------------------------------
-- 12. Avis clients (affichés sur la page d'accueil)
-- ------------------------------------------------------------
-- Gérez les témoignages depuis l'admin : auteur, note sur 5,
-- texte, date d'affichage et activation.
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  author text not null,
  rating int not null default 5 check (rating between 1 and 5),
  text text not null,
  created_at timestamptz not null default now(),
  active boolean not null default true,
  sort_order int default 0
);

alter table public.reviews enable row level security;

-- Tout le monde lit les avis actifs, un connecté les modifie
drop policy if exists "reviews public read" on public.reviews;
create policy "reviews public read" on public.reviews for select using (true);
drop policy if exists "reviews auth insert" on public.reviews;
create policy "reviews auth insert" on public.reviews for insert with check (auth.role() = 'authenticated');
drop policy if exists "reviews auth update" on public.reviews;
create policy "reviews auth update" on public.reviews for update using (auth.role() = 'authenticated');
drop policy if exists "reviews auth delete" on public.reviews;
create policy "reviews auth delete" on public.reviews for delete using (auth.role() = 'authenticated');

grant select on public.reviews to anon, authenticated;
grant select, insert, update, delete on public.reviews to authenticated;