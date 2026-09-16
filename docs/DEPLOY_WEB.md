# Déployer DesK Tattoo Web sur Netlify

La webapp sert deux usages :
- le dashboard du tatoueur (mêmes écrans que l'app mobile) ;
- le **formulaire d'accueil client** ouvert par le QR code, sur `/intake/<token>`.

## Argent Stripe

Les paiements Checkout partent sur **ton compte Stripe** (celui de la
`STRIPE_SECRET_KEY` stockée dans les secrets Supabase).
- **Test** (`sk_test_` + `price_` Test) : argent fictif
- **Live** (`sk_live_` + `price_` Live) : tu encaisses réellement

## 1. Créer le site Netlify

1. [app.netlify.com](https://app.netlify.com) → **Add new site** → **Import an existing project**
2. Connecte GitHub et choisis **morgandouillard0601-spec/DesK-Tattoo**
3. Branche : `main`
4. Build command et publish directory sont lus depuis [`netlify.toml`](../netlify.toml) :
   - command : `bash scripts/web_build.sh`
   - publish : `build/web`
5. Ajoute les variables d'environnement (étape suivante) **avant** de déployer

Premier build : 4 à 8 minutes, le script clone le SDK Flutter.

## 2. Variables d'environnement

Site configuration → Environment variables :

| Name | Value |
|------|--------|
| `SUPABASE_URL` | `https://wklmcvrsizxohmiklocs.supabase.co` |
| `SUPABASE_ANON_KEY` | ta clé publishable Supabase |
| `STRIPE_PUBLISHABLE_KEY` | `pk_test_…` (puis `pk_live_…` en prod) |
| `STRIPE_PRODUCT_ID` | `prod_…` |
| `STRIPE_PRICE_ID` | `price_…` |
| `STRIPE_PRICE_LABEL` | `19,99 €` |
| `APP_ENV` | `prod` |

Les deux premières sont obligatoires : le build s'arrête sans elles.

`WEB_APP_URL` n'est pas nécessaire sur Netlify : le script reprend
automatiquement l'URL du site (`URL` / `DEPLOY_PRIME_URL`), et l'app web
détecte de toute façon l'origine réelle de la page.

## 3. Après le premier déploiement

Note l'URL `https://….netlify.app`, puis :

```bash
cd /Users/user/Documents/DesK-Tattoo-xcode

# Retour de paiement Stripe
supabase secrets set SITE_URL=https://TON-SITE.netlify.app
supabase functions deploy create-checkout-session
```

Et dans le `.env` **local** (utilisé pour les builds iOS / Android, afin que le
QR affiché dans l'app mobile pointe au bon endroit) :

```env
WEB_APP_URL=https://TON-SITE.netlify.app
```

## 4. Tester le QR d'accueil client

Prérequis : `supabase/sql/07_intake_consents.sql` exécuté, et les functions
`intake-artist` / `intake-submit` déployées.

1. Ouvre l'app (mobile ou web), onglet **Profil** → section **Accueil client**
2. Scanne le QR avec un autre téléphone, ou ouvre le lien copié
3. Remplis les trois étapes, coche les consentements, signe
4. Dans l'app, ouvre la fiche du client : le contrat signé apparaît dans
   **Contrats et consentements**

## 5. Tester le paiement web

1. Crée un compte depuis l'URL Netlify
2. Paywall → **S'abonner**
3. Carte test `4242 4242 4242 4242`
4. Retour automatique sur `/paywall?checkout=success` → accès au dashboard

## Notes

- Netlify sert les fichiers existants avant la règle de réécriture : les assets
  Flutter ne sont pas interceptés par le renvoi vers `index.html`.
- Le `.env` est généré au build et n'est jamais commité.
- La clé secrète Stripe et le secret de webhook restent uniquement dans les
  secrets Supabase.
