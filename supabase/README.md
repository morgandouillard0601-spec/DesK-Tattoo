# Supabase SQL — DesK Tattoo

Fichiers à exécuter dans **Supabase → SQL Editor**.

## Le plus simple

1. Ouvre **`sql/00_all_in_one.sql`**, colle tout dans le SQL Editor, **Run**.
2. Ouvre **`sql/06_onboarding_billing.sql`**, colle tout, **Run**.

> Pas de `\i` : ça ne marche pas dans le dashboard web.

## Ou fichier par fichier

| # | Fichier | Contenu |
|---|---------|---------|
| 1 | `sql/01_schema.sql` | Tables |
| 2 | `sql/02_auth_trigger.sql` | Trigger Auth → `artists` |
| 3 | `sql/03_rls.sql` | RLS |
| 4 | `sql/04_storage.sql` | Buckets storage |
| 5 | `sql/05_realtime.sql` | Realtime |
| 6 | `sql/06_onboarding_billing.sql` | Adresse / SIRET / Stripe / admin |

## Edge Functions (Stripe)

Voir aussi [`DEPLOY_CHECKLIST.md`](DEPLOY_CHECKLIST.md) et [`docs/DEPLOY_LIVE.md`](../docs/DEPLOY_LIVE.md).

```bash
supabase secrets set STRIPE_SECRET_KEY=sk_live_...
supabase secrets set STRIPE_PRICE_ID=price_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
supabase secrets set SITE_URL=https://TON-PROJET.vercel.app

supabase functions deploy create-checkout-session
supabase functions deploy stripe-webhook --no-verify-jwt
supabase functions deploy subscription-status
```

Dans Stripe Dashboard → Webhooks → endpoint :
`https://<project-ref>.supabase.co/functions/v1/stripe-webhook`

Events : `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`, `invoice.payment_succeeded`, `invoice.payment_failed`.

## Avant / après

1. Active **Email** dans Authentication
2. Après le SQL : copie `SUPABASE_URL` + `anon key` dans `.env`
3. Crée le user `morgandesk@gmail.com` (admin + bypass paywall via migration 06)
