# Déployer DesK Tattoo Web sur Vercel + Stripe

## Argent Stripe

Les paiements Checkout partent sur **ton compte Stripe** (celui de la `STRIPE_SECRET_KEY` dans Supabase).
- **Test** (`sk_test_` + `price_` Test) : argent fictif
- **Live** (`sk_live_` + `price_` Live) : tu reçois vraiment l’argent (après activation du compte Stripe)

## 1. Redéployer la function Checkout (retours web)

```bash
cd /Users/user/Documents/DesK-Tattoo-xcode
supabase functions deploy create-checkout-session
```

Optionnel — URL de secours (remplace par ton domaine Vercel une fois connu) :

```bash
supabase secrets set SITE_URL=https://TON-PROJET.vercel.app
```

Sur le web, l’app envoie aussi automatiquement l’origine Vercel (`return_base_url`).

## 2. Variables d’environnement Vercel

Project Settings → Environment Variables :

| Name | Value |
|------|--------|
| `SUPABASE_URL` | `https://wklmcvrsizxohmiklocs.supabase.co` |
| `SUPABASE_ANON_KEY` | ta clé publishable Supabase |
| `STRIPE_PUBLISHABLE_KEY` | `pk_test_…` (puis `pk_live_…` en prod) |
| `STRIPE_PRODUCT_ID` | `prod_…` |
| `STRIPE_PRICE_ID` | `price_…` **mode Test** pour la v1 |
| `STRIPE_PRICE_LABEL` | `19,99 €` |
| `APP_ENV` | `prod` |

## 3. Connecter Vercel

1. Push le repo sur GitHub
2. [vercel.com](https://vercel.com) → New Project → importe le repo
3. Framework preset : **Other**
4. Build Command / Output : lus depuis `vercel.json`
5. Deploy

Build time ~3–6 min (clone Flutter SDK).

## 4. Tester le paiement web

1. Ouvre `https://TON-PROJET.vercel.app`
2. Crée un compte → paywall → **S’abonner**
3. Carte test `4242…`
4. Retour automatique sur `/paywall?checkout=success` → refresh abo → dashboard

## 5. Recevoir l’argent réel

1. Stripe → activer le compte (IBAN, identité)
2. Créer le prix **Live** 19,99 €/mois
3. Secrets Supabase : `STRIPE_SECRET_KEY=sk_live_…`, `STRIPE_PRICE_ID=price_LIVE_…`
4. Webhook **Live** vers la même URL function
5. Vercel : `STRIPE_PUBLISHABLE_KEY=pk_live_…`
