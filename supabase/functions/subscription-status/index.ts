import {
  adminClient,
  corsHeaders,
  jsonResponse,
  requireUser,
} from '../_shared/cors.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'GET' && req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const auth = await requireUser(req);
  if ('error' in auth && auth.error) return auth.error;

  const admin = adminClient();
  const { data: artist, error } = await admin
    .from('artists')
    .select(
      'id, email, role, subscription_status, subscription_current_period_end, stripe_customer_id, stripe_subscription_id, onboarding_completed_at',
    )
    .eq('id', auth.user!.id)
    .maybeSingle();

  if (error || !artist) {
    return jsonResponse({ error: 'Artist not found' }, 404);
  }

  const entitled =
    artist.role === 'admin' ||
    artist.subscription_status === 'active' ||
    artist.subscription_status === 'trialing';

  return jsonResponse({
    ...artist,
    entitled,
  });
});
