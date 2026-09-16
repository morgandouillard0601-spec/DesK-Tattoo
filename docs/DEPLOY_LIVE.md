# Déploiement LIVE — DesK Tattoo (Stripe + Supabase + Netlify)

Objectif : paiements **réels** → l’argent arrive sur **ton compte Stripe**.

> Ne colle jamais `sk_live_…` ni `whsec_…` dans le repo / Flutter / chat.  
> Uniquement dans **Supabase Secrets** (et `pk_live_…` dans Netlify / `.env` local).

---

## A. Activer Stripe Live

1. [dashboard.stripe.com](https://dashboard.stripe.com) → désactive **Test mode** (passe en **Live**)
2. Complète l’activation du compte (identité, IBAN) si Stripe le demande  
   → sans ça, tu ne pourras pas encaisser
3. **Developers → API keys (Live)**  
   - copie `pk_live_…` (publique)  
   - copie `sk_live_…` (secrète → Supabase seulement)

## B. Produit + prix Live 19,99 € / mois

1. Toujours en **Live** → **Products**
2. Ouvre (ou recrée) le produit DesK Tattoo
3. Ajoute un prix :
   - **19,99 EUR**
   - **Recurring → Monthly**
4. Copie le **Price ID** `price_…` (**Live**, pas Test)
5. Note aussi le **Product ID** `prod_…` si besoin

## C. Webhook Live

1. **Workbench → Webhooks** (mode **Live**)  
   ou https://dashboard.stripe.com/workbench/webhooks
2. **Create destination**
3. URL :
   ```
   https://wklmcvrsizxohmiklocs.supabase.co/functions/v1/stripe-webhook
   ```
4. Events :
   - `checkout.session.completed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
5. Reveal **Signing secret** `whsec_…` (Live)

## D. Secrets Supabase (Live)

Dans ton terminal :

```bash
cd /Users/user/Documents/DesK-Tattoo-xcode

supabase secrets set STRIPE_SECRET_KEY=sk_live_XXXX
supabase secrets set STRIPE_PRICE_ID=price_XXXX_LIVE
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_XXXX_LIVE
# Après le 1er deploy Netlify, remplace par ton URL réelle :
supabase secrets set SITE_URL=https://TON-SITE.netlify.app

supabase functions deploy create-checkout-session
supabase functions deploy subscription-status
supabase functions deploy stripe-webhook --no-verify-jwt
```

## E. `.env` local (optionnel, pour `flutter run -d chrome`)

Remplace les clés test par :

```env
APP_ENV=prod
STRIPE_PUBLISHABLE_KEY=pk_live_XXXX
STRIPE_PRODUCT_ID=prod_XXXX
STRIPE_PRICE_ID=price_XXXX_LIVE
STRIPE_PRICE_LABEL=19,99 €
```

`sk_live_` **ne va pas** dans `.env`.

## F. Push GitHub + Deploy Netlify

```bash
cd /Users/user/Documents/DesK-Tattoo-xcode
git status
# commit + push sur ton remote GitHub
```

1. [app.netlify.com](https://app.netlify.com) → **Add new site** → **Import an existing project**
2. Build command et publish directory sont lus depuis `netlify.toml`
3. **Environment Variables** (Production) :

| Name | Value |
|------|--------|
| `SUPABASE_URL` | `https://wklmcvrsizxohmiklocs.supabase.co` |
| `SUPABASE_ANON_KEY` | ta clé publishable Supabase |
| `STRIPE_PUBLISHABLE_KEY` | `pk_live_…` |
| `STRIPE_PRODUCT_ID` | `prod_…` Live |
| `STRIPE_PRICE_ID` | `price_…` Live |
| `STRIPE_PRICE_LABEL` | `19,99 €` |
| `APP_ENV` | `prod` |

4. **Deploy** (build ~3–6 min)
5. Copie l’URL `https://….netlify.app`
6. Mets à jour :
   ```bash
   supabase secrets set SITE_URL=https://….netlify.app
   ```

## G. Test de bout en bout (argent réel)

1. Ouvre l’URL Netlify
2. Crée un vrai compte studio (onboarding)
3. Paywall → **S’abonner** → paie avec une **vraie carte**
4. Retour `/paywall?checkout=success` → accès dashboard
5. Vérifie dans Stripe Live → **Payments / Subscriptions** que le paiement apparaît
6. L’argent sera versé sur ton IBAN selon le calendrier Stripe (Payouts)

## H. Checklist rapide

- [ ] Compte Stripe Live activé (IBAN OK)
- [ ] `pk_live_` + `sk_live_` récupérés
- [ ] Prix Live `price_…` 19,99 €/mois créé
- [ ] Webhook Live + `whsec_…` Live
- [ ] Secrets Supabase à jour (Live)
- [ ] Functions redéployées
- [ ] Netlify env vars Live + deploy OK
- [ ] `SITE_URL` = URL Netlify
- [ ] Paiement réel testé
