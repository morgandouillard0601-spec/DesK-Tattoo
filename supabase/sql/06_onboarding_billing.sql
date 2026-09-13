-- =============================================================================
-- DesK Tattoo — 06_onboarding_billing.sql
-- Onboarding salon (adresse / ville / SIRET) + abonnement Stripe + rôle admin
-- À coller dans Supabase → SQL Editor → Run (après 00_all_in_one.sql)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Colonnes onboarding + billing sur artists
-- ---------------------------------------------------------------------------
alter table public.artists
  add column if not exists address text not null default '',
  add column if not exists city text not null default '',
  add column if not exists siret text not null default '',
  add column if not exists role text not null default 'artist'
    check (role in ('artist', 'admin')),
  add column if not exists stripe_customer_id text,
  add column if not exists stripe_subscription_id text,
  add column if not exists subscription_status text not null default 'none'
    check (subscription_status in (
      'none',
      'active',
      'past_due',
      'canceled',
      'incomplete',
      'trialing'
    )),
  add column if not exists subscription_current_period_end timestamptz,
  add column if not exists onboarding_completed_at timestamptz;

create index if not exists artists_subscription_status_idx
  on public.artists (subscription_status);

create index if not exists artists_siret_idx
  on public.artists (lower(siret));

create index if not exists artists_role_idx
  on public.artists (role);

-- ---------------------------------------------------------------------------
-- Trigger Auth → artists (meta onboarding étendue)
-- ---------------------------------------------------------------------------
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
    address,
    city,
    siret,
    specialties,
    experience_years,
    bio,
    instagram,
    role,
    subscription_status
  )
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(meta ->> 'first_name', ''),
    coalesce(meta ->> 'last_name', ''),
    coalesce(meta ->> 'phone', ''),
    coalesce(meta ->> 'studio_name', ''),
    coalesce(meta ->> 'address', ''),
    coalesce(meta ->> 'city', ''),
    coalesce(meta ->> 'siret', ''),
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
    meta ->> 'instagram',
    case
      when lower(coalesce(new.email, '')) = 'morgandesk@gmail.com' then 'admin'
      else 'artist'
    end,
    case
      when lower(coalesce(new.email, '')) = 'morgandesk@gmail.com' then 'active'
      else 'none'
    end
  )
  on conflict (id) do update
    set email = excluded.email,
        updated_at = now();

  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Helper : l'utilisateur courant est-il admin ?
-- ---------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.artists a
    where a.id = auth.uid()
      and a.role = 'admin'
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

-- ---------------------------------------------------------------------------
-- RLS : admin peut lire tous les dossiers studios
-- ---------------------------------------------------------------------------
drop policy if exists "artists_select_all_if_admin" on public.artists;
create policy "artists_select_all_if_admin"
  on public.artists for select
  to authenticated
  using (public.is_admin());

-- Admin peut mettre à jour le legacy / support (lecture seule côté app pour le reste)
drop policy if exists "artists_update_all_if_admin" on public.artists;
create policy "artists_update_all_if_admin"
  on public.artists for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ---------------------------------------------------------------------------
-- Seed / grandfather legacy
-- ---------------------------------------------------------------------------
update public.artists
set
  role = 'admin',
  subscription_status = 'active',
  studio_name = coalesce(nullif(studio_name, ''), 'DesK Tattoo Studio'),
  first_name = coalesce(nullif(first_name, ''), 'Morgan'),
  last_name = coalesce(nullif(last_name, ''), 'Desk'),
  updated_at = now()
where lower(email) = 'morgandesk@gmail.com';
