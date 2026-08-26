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
