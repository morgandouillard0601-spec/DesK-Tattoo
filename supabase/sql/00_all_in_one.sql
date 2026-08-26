-- =============================================================================
-- DesK Tattoo — TOUT-EN-UN pour SQL Editor web Supabase
-- Copie-colle TOUT ce fichier → SQL Editor → Run
-- =============================================================================

-- =============================================================================
-- DesK Tattoo — 01_schema.sql
-- À coller dans Supabase → SQL Editor → New query → Run
-- Crée les tables métier + enums / checks
-- =============================================================================

-- Extensions utiles
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- artists (1 profil par compte Auth)
-- id = auth.users.id
-- ---------------------------------------------------------------------------
create table if not exists public.artists (
  id uuid primary key references auth.users (id) on delete cascade,
  first_name text not null default '',
  last_name text not null default '',
  email text not null,
  phone text not null default '',
  studio_name text not null default '',
  specialties text[] not null default '{}',
  experience_years integer not null default 0 check (experience_years >= 0),
  bio text,
  instagram text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists artists_email_idx on public.artists (lower(email));

-- ---------------------------------------------------------------------------
-- clients
-- ---------------------------------------------------------------------------
create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid not null references public.artists (id) on delete cascade,
  first_name text not null,
  last_name text not null,
  phone text not null default '',
  email text not null default '',
  created_at timestamptz not null default now(),
  last_visit timestamptz,
  notes text,
  total_sessions integer not null default 0 check (total_sessions >= 0),
  total_spent numeric(12, 2) not null default 0 check (total_spent >= 0)
);

create index if not exists clients_artist_id_idx on public.clients (artist_id);
create index if not exists clients_artist_name_idx
  on public.clients (artist_id, lower(last_name), lower(first_name));

-- ---------------------------------------------------------------------------
-- appointments (planning)
-- ---------------------------------------------------------------------------
create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid not null references public.artists (id) on delete cascade,
  client_id uuid references public.clients (id) on delete set null,
  client_name text not null,
  title text not null,
  start_at timestamptz not null,
  duration_minutes integer not null check (duration_minutes > 0),
  price numeric(12, 2) not null default 0 check (price >= 0),
  status text not null default 'scheduled'
    check (status in (
      'scheduled',
      'confirmed',
      'in_progress',
      'completed',
      'cancelled'
    )),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists appointments_artist_start_idx
  on public.appointments (artist_id, start_at);
create index if not exists appointments_client_id_idx
  on public.appointments (client_id);

-- ---------------------------------------------------------------------------
-- stock_items
-- ---------------------------------------------------------------------------
create table if not exists public.stock_items (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid not null references public.artists (id) on delete cascade,
  name text not null,
  category text not null
    check (category in (
      'needles',
      'ink',
      'cartridges',
      'gloves',
      'hygiene',
      'machines',
      'other'
    )),
  sub_category text,
  brand text,
  quantity integer not null default 0,
  threshold integer not null default 0,
  unit text not null default 'pcs',
  unit_price numeric(12, 2) not null default 0 check (unit_price >= 0),
  last_restock_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists stock_items_artist_id_idx on public.stock_items (artist_id);
create index if not exists stock_items_artist_category_idx
  on public.stock_items (artist_id, category);

-- ---------------------------------------------------------------------------
-- transactions (compta)
-- ---------------------------------------------------------------------------
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid not null references public.artists (id) on delete cascade,
  type text not null check (type in ('income', 'expense')),
  label text not null,
  amount numeric(12, 2) not null check (amount >= 0),
  date date not null default (timezone('utc', now()))::date,
  method text not null default 'cash'
    check (method in ('cash', 'card', 'transfer', 'deposit')),
  client_id uuid references public.clients (id) on delete set null,
  client_name text,
  category text,
  created_at timestamptz not null default now()
);

create index if not exists transactions_artist_date_idx
  on public.transactions (artist_id, date desc);
create index if not exists transactions_client_id_idx
  on public.transactions (client_id);

-- ---------------------------------------------------------------------------
-- updated_at helper
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists artists_set_updated_at on public.artists;
create trigger artists_set_updated_at
  before update on public.artists
  for each row execute function public.set_updated_at();

drop trigger if exists appointments_set_updated_at on public.appointments;
create trigger appointments_set_updated_at
  before update on public.appointments
  for each row execute function public.set_updated_at();

drop trigger if exists stock_items_set_updated_at on public.stock_items;
create trigger stock_items_set_updated_at
  before update on public.stock_items
  for each row execute function public.set_updated_at();

-- =============================================================================
-- DesK Tattoo — 02_auth_trigger.sql
-- À coller dans Supabase → SQL Editor → Run
-- Crée automatiquement une ligne artists à chaque nouvel utilisateur Auth
-- =============================================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
begin
  insert into public.artists (
    id,
    email,
    first_name,
    last_name,
    phone,
    studio_name,
    specialties,
    experience_years,
    bio,
    instagram
  )
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(meta ->> 'first_name', ''),
    coalesce(meta ->> 'last_name', ''),
    coalesce(meta ->> 'phone', ''),
    coalesce(meta ->> 'studio_name', ''),
    case
      when jsonb_typeof(meta -> 'specialties') = 'array' then
        coalesce(
          array(select jsonb_array_elements_text(meta -> 'specialties')),
          '{}'::text[]
        )
      else '{}'::text[]
    end,
    coalesce(nullif(meta ->> 'experience_years', '')::integer, 0),
    meta ->> 'bio',
    meta ->> 'instagram'
  )
  on conflict (id) do update
    set email = excluded.email,
        updated_at = now();

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Migration compte legacy (optionnel)
-- Après avoir créé le user morgandesk@gmail.com dans Authentication → Users
-- (ou via signUp dans l'app), récupère son UUID puis décommente / adapte :
--
-- update public.artists set
--   first_name = 'Morgan',
--   last_name = 'Desk',
--   phone = '+33 6 00 00 00 00',
--   studio_name = 'DesK Tattoo Studio',
--   specialties = array['Black & Grey', 'Réalisme', 'Géométrique'],
--   experience_years = 6,
--   bio = 'Tatoueur depuis 2020, spécialisé dans le réalisme et le black & grey. Studio basé à Paris.',
--   instagram = '@desk.tattoo',
--   updated_at = now()
-- where email = 'morgandesk@gmail.com';
-- ---------------------------------------------------------------------------

-- =============================================================================
-- DesK Tattoo — 03_rls.sql
-- À coller dans Supabase → SQL Editor → Run
-- Active RLS : chaque artiste ne voit / modifie QUE ses données
-- =============================================================================

alter table public.artists enable row level security;
alter table public.clients enable row level security;
alter table public.appointments enable row level security;
alter table public.stock_items enable row level security;
alter table public.transactions enable row level security;

-- ---------------------------------------------------------------------------
-- artists : id = auth.uid()
-- ---------------------------------------------------------------------------
drop policy if exists "artists_select_own" on public.artists;
create policy "artists_select_own"
  on public.artists for select
  to authenticated
  using (id = auth.uid());

drop policy if exists "artists_update_own" on public.artists;
create policy "artists_update_own"
  on public.artists for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Insert géré par le trigger security definer (pas besoin d'insert côté client)
drop policy if exists "artists_insert_own" on public.artists;
create policy "artists_insert_own"
  on public.artists for insert
  to authenticated
  with check (id = auth.uid());

-- ---------------------------------------------------------------------------
-- clients
-- ---------------------------------------------------------------------------
drop policy if exists "clients_select_own" on public.clients;
create policy "clients_select_own"
  on public.clients for select
  to authenticated
  using (artist_id = auth.uid());

drop policy if exists "clients_insert_own" on public.clients;
create policy "clients_insert_own"
  on public.clients for insert
  to authenticated
  with check (artist_id = auth.uid());

drop policy if exists "clients_update_own" on public.clients;
create policy "clients_update_own"
  on public.clients for update
  to authenticated
  using (artist_id = auth.uid())
  with check (artist_id = auth.uid());

drop policy if exists "clients_delete_own" on public.clients;
create policy "clients_delete_own"
  on public.clients for delete
  to authenticated
  using (artist_id = auth.uid());

-- ---------------------------------------------------------------------------
-- appointments
-- ---------------------------------------------------------------------------
drop policy if exists "appointments_select_own" on public.appointments;
create policy "appointments_select_own"
  on public.appointments for select
  to authenticated
  using (artist_id = auth.uid());

drop policy if exists "appointments_insert_own" on public.appointments;
create policy "appointments_insert_own"
  on public.appointments for insert
  to authenticated
  with check (artist_id = auth.uid());

drop policy if exists "appointments_update_own" on public.appointments;
create policy "appointments_update_own"
  on public.appointments for update
  to authenticated
  using (artist_id = auth.uid())
  with check (artist_id = auth.uid());

drop policy if exists "appointments_delete_own" on public.appointments;
create policy "appointments_delete_own"
  on public.appointments for delete
  to authenticated
  using (artist_id = auth.uid());

-- ---------------------------------------------------------------------------
-- stock_items
-- ---------------------------------------------------------------------------
drop policy if exists "stock_items_select_own" on public.stock_items;
create policy "stock_items_select_own"
  on public.stock_items for select
  to authenticated
  using (artist_id = auth.uid());

drop policy if exists "stock_items_insert_own" on public.stock_items;
create policy "stock_items_insert_own"
  on public.stock_items for insert
  to authenticated
  with check (artist_id = auth.uid());

drop policy if exists "stock_items_update_own" on public.stock_items;
create policy "stock_items_update_own"
  on public.stock_items for update
  to authenticated
  using (artist_id = auth.uid())
  with check (artist_id = auth.uid());

drop policy if exists "stock_items_delete_own" on public.stock_items;
create policy "stock_items_delete_own"
  on public.stock_items for delete
  to authenticated
  using (artist_id = auth.uid());

-- ---------------------------------------------------------------------------
-- transactions
-- ---------------------------------------------------------------------------
drop policy if exists "transactions_select_own" on public.transactions;
create policy "transactions_select_own"
  on public.transactions for select
  to authenticated
  using (artist_id = auth.uid());

drop policy if exists "transactions_insert_own" on public.transactions;
create policy "transactions_insert_own"
  on public.transactions for insert
  to authenticated
  with check (artist_id = auth.uid());

drop policy if exists "transactions_update_own" on public.transactions;
create policy "transactions_update_own"
  on public.transactions for update
  to authenticated
  using (artist_id = auth.uid())
  with check (artist_id = auth.uid());

drop policy if exists "transactions_delete_own" on public.transactions;
create policy "transactions_delete_own"
  on public.transactions for delete
  to authenticated
  using (artist_id = auth.uid());

-- =============================================================================
-- DesK Tattoo — 04_storage.sql
-- À coller dans Supabase → SQL Editor → Run
-- Buckets : avatars (profil) + exports (PDF compta, optionnel)
-- =============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'avatars',
    'avatars',
    true,
    5242880, -- 5 MB
    array['image/jpeg', 'image/png', 'image/webp', 'image/heic']
  ),
  (
    'exports',
    'exports',
    false,
    20971520, -- 20 MB
    array['application/pdf']
  )
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- ---------------------------------------------------------------------------
-- avatars : path = {user_id}/avatar.*
-- ---------------------------------------------------------------------------
drop policy if exists "avatars_public_read" on storage.objects;
create policy "avatars_public_read"
  on storage.objects for select
  to public
  using (bucket_id = 'avatars');

drop policy if exists "avatars_insert_own" on storage.objects;
create policy "avatars_insert_own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "avatars_update_own" on storage.objects;
create policy "avatars_update_own"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "avatars_delete_own" on storage.objects;
create policy "avatars_delete_own"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------------------------------------------------------------------------
-- exports : path = {user_id}/fichier.pdf
-- ---------------------------------------------------------------------------
drop policy if exists "exports_select_own" on storage.objects;
create policy "exports_select_own"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'exports'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "exports_insert_own" on storage.objects;
create policy "exports_insert_own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'exports'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "exports_update_own" on storage.objects;
create policy "exports_update_own"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'exports'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'exports'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "exports_delete_own" on storage.objects;
create policy "exports_delete_own"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'exports'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- =============================================================================
-- DesK Tattoo — 05_realtime.sql
-- À coller dans Supabase → SQL Editor → Run
-- Active Realtime sur planning + stock
-- =============================================================================

-- Ajoute les tables à la publication supabase_realtime (ignore si déjà présentes)
do $$
begin
  begin
    alter publication supabase_realtime add table public.appointments;
  exception
    when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime add table public.stock_items;
  exception
    when duplicate_object then null;
  end;
end $$;

-- Optionnel plus tard :
-- alter publication supabase_realtime add table public.clients;
-- alter publication supabase_realtime add table public.transactions;
