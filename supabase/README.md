# Supabase SQL — DesK Tattoo

Fichiers à exécuter dans **Supabase → SQL Editor**.

## Le plus simple

Ouvre **`sql/00_all_in_one.sql`**, sélectionne **tout** le contenu (~500 lignes), colle dans le SQL Editor, **Run**.

> Pas de `\i` : ça ne marche pas dans le dashboard web.

## Ou fichier par fichier

| # | Fichier | Contenu |
|---|---------|---------|
| 1 | `sql/01_schema.sql` | Tables |
| 2 | `sql/02_auth_trigger.sql` | Trigger Auth → `artists` |
| 3 | `sql/03_rls.sql` | RLS |
| 4 | `sql/04_storage.sql` | Buckets storage |
| 5 | `sql/05_realtime.sql` | Realtime |

## Avant / après

1. Active **Email** dans Authentication  
2. Après le SQL : copie `SUPABASE_URL` + `anon key` dans `.env`  
3. Crée le user `morgandesk@gmail.com`, puis mets à jour le profil (bloc commenté dans `02_auth_trigger.sql`)
