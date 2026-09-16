# Checklist déploiement Stripe / Supabase (DesK Tattoo) — LIVE

Voir le guide complet : [`docs/DEPLOY_LIVE.md`](../docs/DEPLOY_LIVE.md)

```bash
supabase secrets set STRIPE_SECRET_KEY=sk_live_...
supabase secrets set STRIPE_PRICE_ID=price_...   # Price ID mode LIVE
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...  # Webhook mode LIVE
supabase secrets set SITE_URL=https://TON-PROJET.vercel.app

supabase functions deploy create-checkout-session
supabase functions deploy subscription-status
supabase functions deploy stripe-webhook --no-verify-jwt

# Accueil client par QR (functions publiques)
supabase functions deploy intake-artist --no-verify-jwt
supabase functions deploy intake-submit --no-verify-jwt
```

Webhook URL :
`https://wklmcvrsizxohmiklocs.supabase.co/functions/v1/stripe-webhook`
