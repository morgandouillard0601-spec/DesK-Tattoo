import {
  adminClient,
  corsHeaders,
  jsonResponse,
  requireUser,
} from '../_shared/cors.ts';

const CONSENTS_BUCKET = 'consents';

/// Annule l'abonnement Stripe encore actif pour que la suppression du compte
/// n'entraîne pas de prélèvement supplémentaire.
async function cancelStripeSubscription(subscriptionId: string) {
  const stripeKey = Deno.env.get('STRIPE_SECRET_KEY');
  if (!stripeKey) return;
  try {
    await fetch(`https://api.stripe.com/v1/subscriptions/${subscriptionId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${stripeKey}` },
    });
  } catch {
    // La suppression du compte reste prioritaire sur l'annulation Stripe.
  }
}

/// Le bucket `consents` est organisé en `{artist_id}/{consent_id}/fichier`,
/// et `list` n'est pas récursif : on descend d'un niveau.
async function deleteConsentFiles(
  admin: ReturnType<typeof adminClient>,
  artistId: string,
) {
  const storage = admin.storage.from(CONSENTS_BUCKET);
  const { data: folders } = await storage.list(artistId);
  if (!folders) return;

  const paths: string[] = [];
  for (const entry of folders) {
    if (entry.id === null) {
      const { data: files } = await storage.list(`${artistId}/${entry.name}`);
      for (const file of files ?? []) {
        paths.push(`${artistId}/${entry.name}/${file.name}`);
      }
    } else {
      paths.push(`${artistId}/${entry.name}`);
    }
  }

  if (paths.length > 0) {
    await storage.remove(paths);
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST' && req.method !== 'DELETE') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const auth = await requireUser(req);
  if ('error' in auth && auth.error) return auth.error;

  const userId = auth.user!.id;
  const admin = adminClient();

  const { data: artist } = await admin
    .from('artists')
    .select('id, stripe_subscription_id')
    .eq('id', userId)
    .maybeSingle();

  if (artist?.stripe_subscription_id) {
    await cancelStripeSubscription(artist.stripe_subscription_id as string);
  }

  try {
    await deleteConsentFiles(admin, userId);
  } catch {
    // Fichiers orphelins tolérés : le compte doit disparaître quand même.
  }

  // `artists` cascade sur clients, appointments, stock_items, transactions
  // et client_consents (cf. 01_schema.sql / 07_intake_consents.sql).
  const { error } = await admin.auth.admin.deleteUser(userId);
  if (error) {
    return jsonResponse({ error: error.message }, 500);
  }

  return jsonResponse({ deleted: true });
});
