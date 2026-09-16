-- =============================================================================
-- DesK Tattoo — 07_intake_consents.sql
-- À coller dans Supabase → SQL Editor → Run (après 06_onboarding_billing.sql)
-- QR d'accueil par tatoueur + fiche client remplie par le client + contrat signé
-- =============================================================================

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- artists : token public encodé dans le QR code du tatoueur
-- ---------------------------------------------------------------------------
alter table public.artists
  add column if not exists public_intake_token text;

update public.artists
set public_intake_token = encode(gen_random_bytes(16), 'hex')
where public_intake_token is null;

alter table public.artists
  alter column public_intake_token set default encode(gen_random_bytes(16), 'hex');

alter table public.artists
  alter column public_intake_token set not null;

create unique index if not exists artists_public_intake_token_idx
  on public.artists (public_intake_token);

-- ---------------------------------------------------------------------------
-- clients : provenance + informations collectées via le formulaire public
-- ---------------------------------------------------------------------------
alter table public.clients
  add column if not exists source text not null default 'manual'
    check (source in ('manual', 'intake')),
  add column if not exists birth_date date,
  add column if not exists address text not null default '',
  add column if not exists city text not null default '',
  add column if not exists postal_code text not null default '';

create index if not exists clients_artist_source_idx
  on public.clients (artist_id, source);

create index if not exists clients_artist_phone_idx
  on public.clients (artist_id, phone);

-- ---------------------------------------------------------------------------
-- client_consents : un contrat signé par passage du client
-- ---------------------------------------------------------------------------
create table if not exists public.client_consents (
  id uuid primary key default gen_random_uuid(),
  artist_id uuid not null references public.artists (id) on delete cascade,
  client_id uuid not null references public.clients (id) on delete cascade,
  full_name text not null,
  email text not null default '',
  phone text not null default '',
  birth_date date,
  health_answers jsonb not null default '{}'::jsonb,
  accepted_terms boolean not null default false,
  accepted_health boolean not null default false,
  accepted_aftercare boolean not null default false,
  accepted_image_rights boolean not null default false,
  signature_path text,
  pdf_path text,
  signed_at timestamptz not null default now(),
  ip_hash text,
  user_agent text,
  created_at timestamptz not null default now()
);

create index if not exists client_consents_artist_idx
  on public.client_consents (artist_id, signed_at desc);

create index if not exists client_consents_client_idx
  on public.client_consents (client_id, signed_at desc);

-- ---------------------------------------------------------------------------
-- RLS : chaque tatoueur ne voit que ses propres contrats
-- ---------------------------------------------------------------------------
alter table public.client_consents enable row level security;

drop policy if exists "client_consents_select_own" on public.client_consents;
create policy "client_consents_select_own"
  on public.client_consents for select
  to authenticated
  using (artist_id = auth.uid());

drop policy if exists "client_consents_insert_own" on public.client_consents;
create policy "client_consents_insert_own"
  on public.client_consents for insert
  to authenticated
  with check (artist_id = auth.uid());

drop policy if exists "client_consents_update_own" on public.client_consents;
create policy "client_consents_update_own"
  on public.client_consents for update
  to authenticated
  using (artist_id = auth.uid())
  with check (artist_id = auth.uid());

drop policy if exists "client_consents_delete_own" on public.client_consents;
create policy "client_consents_delete_own"
  on public.client_consents for delete
  to authenticated
  using (artist_id = auth.uid());

drop policy if exists "client_consents_select_all_if_admin" on public.client_consents;
create policy "client_consents_select_all_if_admin"
  on public.client_consents for select
  to authenticated
  using (public.is_admin());

-- ---------------------------------------------------------------------------
-- Rotation du lien public (invalide les QR déjà imprimés)
-- ---------------------------------------------------------------------------
create or replace function public.rotate_intake_token()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  new_token text := encode(gen_random_bytes(16), 'hex');
begin
  update public.artists
  set public_intake_token = new_token,
      updated_at = now()
  where id = auth.uid();

  if not found then
    raise exception 'Aucun profil artiste pour cet utilisateur';
  end if;

  return new_token;
end;
$$;

revoke all on function public.rotate_intake_token() from public;
grant execute on function public.rotate_intake_token() to authenticated;

-- ---------------------------------------------------------------------------
-- Storage : bucket privé pour les contrats signés et les signatures
-- path = {artist_id}/{consent_id}/contrat.pdf | signature.png
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'consents',
  'consents',
  false,
  10485760, -- 10 MB
  array['application/pdf', 'image/png']
)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "consents_select_own" on storage.objects;
create policy "consents_select_own"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'consents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "consents_insert_own" on storage.objects;
create policy "consents_insert_own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'consents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "consents_update_own" on storage.objects;
create policy "consents_update_own"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'consents'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'consents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "consents_delete_own" on storage.objects;
create policy "consents_delete_own"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'consents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
