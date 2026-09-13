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
