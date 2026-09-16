-- =============================================================================
-- DesK Tattoo — 08_seed_demo.sql
-- OPTIONNEL : remplace les anciennes données de démo qui vivaient dans le code
-- Dart. À exécuter une seule fois sur un compte de test.
--
-- Avant de lancer : remplace l'email ci-dessous par celui du compte à peupler.
-- =============================================================================

do $$
declare
  v_email    text := 'morgandesk@gmail.com';
  v_artist   uuid;
  v_camille  uuid;
  v_lucas    uuid;
  v_ines     uuid;
  v_hugo     uuid;
  v_sofia    uuid;
  v_mathis   uuid;
  v_today    date := (timezone('utc', now()))::date;
  v_midnight timestamptz := date_trunc('day', now());
begin
  select id into v_artist
  from public.artists
  where lower(email) = lower(v_email);

  if v_artist is null then
    raise exception 'Aucun artiste pour l''email %. Crée le compte puis relance.', v_email;
  end if;

  if exists (select 1 from public.clients where artist_id = v_artist) then
    raise notice 'Des clients existent déjà pour %, seed ignoré.', v_email;
    return;
  end if;

  -- -------------------------------------------------------------------------
  -- Clients
  -- -------------------------------------------------------------------------
  insert into public.clients (
    artist_id, first_name, last_name, phone, email,
    created_at, last_visit, notes, total_sessions, total_spent
  ) values (
    v_artist, 'Camille', 'Moreau', '+33 6 12 34 56 78', 'camille.moreau@example.com',
    now() - interval '320 days', now() - interval '14 days',
    'Préfère le black & grey. Sensible à la douleur sur les côtes.', 4, 920
  ) returning id into v_camille;

  insert into public.clients (
    artist_id, first_name, last_name, phone, email,
    created_at, last_visit, total_sessions, total_spent
  ) values (
    v_artist, 'Lucas', 'Bernard', '+33 6 22 11 33 44', 'lucas.bernard@example.com',
    now() - interval '90 days', now() - interval '3 days', 2, 480
  ) returning id into v_lucas;

  insert into public.clients (
    artist_id, first_name, last_name, phone, email,
    created_at, last_visit, notes, total_sessions, total_spent
  ) values (
    v_artist, 'Inès', 'Garcia', '+33 7 88 99 12 34', 'ines.garcia@example.com',
    now() - interval '540 days', now() - interval '60 days',
    'Sleeve en cours, prochaine séance prévue.', 7, 2150
  ) returning id into v_ines;

  insert into public.clients (
    artist_id, first_name, last_name, phone, email,
    created_at, total_sessions, total_spent
  ) values (
    v_artist, 'Hugo', 'Petit', '+33 6 45 67 89 01', 'hugo.petit@example.com',
    now() - interval '30 days', 1, 180
  ) returning id into v_hugo;

  insert into public.clients (
    artist_id, first_name, last_name, phone, email,
    created_at, last_visit, total_sessions, total_spent
  ) values (
    v_artist, 'Sofia', 'Martins', '+33 7 11 22 33 44', 'sofia.martins@example.com',
    now() - interval '210 days', now() - interval '28 days', 3, 760
  ) returning id into v_sofia;

  insert into public.clients (
    artist_id, first_name, last_name, phone, email, created_at
  ) values (
    v_artist, 'Mathis', 'Lefevre', '+33 6 98 76 54 32', 'mathis.lefevre@example.com',
    now() - interval '7 days'
  ) returning id into v_mathis;

  -- -------------------------------------------------------------------------
  -- Rendez-vous (relatifs à aujourd'hui)
  -- -------------------------------------------------------------------------
  insert into public.appointments (
    artist_id, client_id, client_name, title, start_at,
    duration_minutes, price, status, notes
  ) values
    (v_artist, v_camille, 'Camille Moreau', 'Retouche rose épaule',
     v_midnight + interval '10 hours', 90, 150, 'confirmed',
     'Retouche couleurs + ombrage léger.'),
    (v_artist, v_lucas, 'Lucas Bernard', 'Lettrage avant-bras',
     v_midnight + interval '13 hours', 120, 280, 'scheduled', null),
    (v_artist, v_ines, 'Inès Garcia', 'Session sleeve 4/6',
     v_midnight + interval '16 hours', 180, 420, 'confirmed',
     'Apporter référence pivoines.'),
    (v_artist, v_sofia, 'Sofia Martins', 'Mini tatouage poignet',
     v_midnight + interval '1 day 11 hours', 45, 90, 'scheduled', null),
    (v_artist, v_hugo, 'Hugo Petit', 'Consultation projet dos',
     v_midnight + interval '1 day 15 hours', 30, 0, 'scheduled', null),
    (v_artist, v_mathis, 'Mathis Lefevre', 'Black work mollet',
     v_midnight + interval '2 days 10 hours', 150, 350, 'confirmed', null),
    (v_artist, v_camille, 'Camille Moreau', 'Suivi cicatrisation',
     v_midnight + interval '3 days 17 hours', 20, 0, 'scheduled', null),
    (v_artist, v_lucas, 'Lucas Bernard', 'Session géométrique',
     v_midnight - interval '1 day' + interval '14 hours', 120, 320, 'completed', null);

  -- -------------------------------------------------------------------------
  -- Stock
  -- -------------------------------------------------------------------------
  insert into public.stock_items (
    artist_id, name, category, sub_category, brand,
    quantity, threshold, unit, unit_price, last_restock_at
  ) values
    (v_artist, 'Cartouches 3RL', 'cartridges', 'Round Liner', null,
     32, 20, 'pcs', 1.85, now() - interval '12 days'),
    (v_artist, 'Cartouches 7M1', 'cartridges', 'Magnum', null,
     8, 15, 'pcs', 1.95, now() - interval '30 days'),
    (v_artist, 'Encre Noire Dynamic', 'ink', 'Dynamic', null,
     4, 3, 'flacons', 18.50, now() - interval '45 days'),
    (v_artist, 'Encre Rouge World Famous', 'ink', 'World Famous', null,
     2, 2, 'flacons', 14.90, now() - interval '60 days'),
    (v_artist, 'Gants nitrile noirs M', 'gloves', 'Nitrile noir · Taille M', null,
     320, 100, 'pcs', 0.18, now() - interval '10 days'),
    (v_artist, 'Film de protection', 'hygiene', 'Film protection', null,
     1, 2, 'rouleaux', 22.00, now() - interval '90 days'),
    (v_artist, 'Savon vert 1L', 'hygiene', 'Savon vert', null,
     3, 2, 'bidons', 12.40, null),
    (v_artist, 'Aiguilles Magnum 13', 'needles', 'Magnum', 'Kwadron',
     50, 30, 'pcs', 0.85, null),
    (v_artist, 'Machine rotative Cheyenne', 'machines', 'Rotative', null,
     2, 1, 'pcs', 950, null);

  -- -------------------------------------------------------------------------
  -- Transactions
  -- -------------------------------------------------------------------------
  insert into public.transactions (
    artist_id, type, label, amount, date, method, client_id, client_name, category
  ) values
    (v_artist, 'income',  'Session sleeve 3/6',    420,   v_today - 1,  'card',     v_ines,    'Inès Garcia',    'Tatouage'),
    (v_artist, 'income',  'Lettrage avant-bras',   280,   v_today - 2,  'cash',     v_lucas,   'Lucas Bernard',  'Tatouage'),
    (v_artist, 'expense', 'Commande cartouches',   94.50, v_today - 3,  'card',     null,      null,             'Fournitures'),
    (v_artist, 'income',  'Acompte Hugo Petit',    80,    v_today - 4,  'deposit',  v_hugo,    'Hugo Petit',     'Acompte'),
    (v_artist, 'income',  'Retouche rose',         150,   v_today - 5,  'card',     v_camille, 'Camille Moreau', 'Tatouage'),
    (v_artist, 'expense', 'Loyer atelier',         850,   v_today - 7,  'transfer', null,      null,             'Loyer'),
    (v_artist, 'income',  'Mini tatouage poignet', 90,    v_today - 8,  'cash',     v_sofia,   'Sofia Martins',  'Tatouage'),
    (v_artist, 'expense', 'Encres World Famous',   78.40, v_today - 12, 'card',     null,      null,             'Fournitures'),
    (v_artist, 'income',  'Black work mollet',     350,   v_today - 14, 'card',     v_mathis,  'Mathis Lefevre', 'Tatouage'),
    (v_artist, 'expense', 'Assurance pro',         65,    v_today - 20, 'transfer', null,      null,             'Assurance');

  raise notice 'Seed démo installé pour % (artist_id %).', v_email, v_artist;
end $$;
