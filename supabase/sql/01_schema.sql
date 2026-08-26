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
