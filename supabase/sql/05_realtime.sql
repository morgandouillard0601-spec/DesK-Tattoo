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
