-- =============================================================================
-- DesK Tattoo — 09_account_deletion.sql
-- À coller dans Supabase → SQL Editor → Run
-- Suppression du compte par le tatoueur lui-même (App Store 5.1.1(v)).
--
-- Filet de sécurité utilisé par l'app si l'Edge Function `delete-account`
-- n'est pas joignable. L'Edge Function reste la voie principale : elle annule
-- aussi l'abonnement Stripe et purge les fichiers du bucket `consents`.
-- =============================================================================

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Non authentifié';
  end if;

  -- Les cascades de `artists` couvrent déjà ces tables ; on reste explicite
  -- pour que la fonction marche même si un FK a été relâché.
  delete from public.client_consents where artist_id = uid;
  delete from public.transactions where artist_id = uid;
  delete from public.appointments where artist_id = uid;
  delete from public.stock_items where artist_id = uid;
  delete from public.clients where artist_id = uid;
  delete from public.artists where id = uid;

  delete from storage.objects
  where bucket_id = 'consents'
    and (storage.foldername(name))[1] = uid::text;

  -- Supprime l'identité Auth : le compte ne peut plus se reconnecter.
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_own_account() from public;
grant execute on function public.delete_own_account() to authenticated;
