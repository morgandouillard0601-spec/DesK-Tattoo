import {
  adminClient,
  corsHeaders,
  jsonResponse,
  requireUser,
} from '../_shared/cors.ts';

function buildReturnUrls(siteUrl: string) {
  const trimmed = siteUrl.replace(/\/$/, '');
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return {
      success:
        `${trimmed}/paywall?checkout=success&session_id={CHECKOUT_SESSION_ID}`,
      cancel: `${trimmed}/paywall?checkout=cancel`,
    };
  }
  return {
    success: `${trimmed}/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel: `${trimmed}/cancel`,
  };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const auth = await requireUser(req);
  if ('error' in auth && auth.error) return auth.error;

  const stripeKey = Deno.env.get('STRIPE_SECRET_KEY');
  const priceId = Deno.env.get('STRIPE_PRICE_ID');
  const defaultSiteUrl = Deno.env.get('SITE_URL') ?? 'desktattoo://billing';

  if (!stripeKey || !priceId) {
    return jsonResponse(
      { error: 'Stripe is not configured on the server' },
      500,
    );
  }

  let returnBaseUrl = defaultSiteUrl;
  try {
    const body = await req.json();
    if (
      body &&
      typeof body.return_base_url === 'string' &&
      (body.return_base_url.startsWith('https://') ||
        body.return_base_url.startsWith('http://'))
    ) {
      returnBaseUrl = body.return_base_url;
    }
  } catch {
    // no body — keep SITE_URL
  }

  const user = auth.user!;
  const admin = adminClient();

  const { data: artist, error: artistError } = await admin
    .from('artists')
    .select(
      'id, email, first_name, last_name, studio_name, stripe_customer_id, role, subscription_status',
    )
    .eq('id', user.id)
    .maybeSingle();

  if (artistError || !artist) {
    return jsonResponse({ error: 'Artist profile not found' }, 404);
  }

  if (artist.role === 'admin' || artist.subscription_status === 'active') {
    return jsonResponse({
      already_entitled: true,
      subscription_status: artist.subscription_status,
    });
  }

  let customerId = artist.stripe_customer_id as string | null;

  if (!customerId) {
    const customerRes = await fetch('https://api.stripe.com/v1/customers', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${stripeKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        email: artist.email ?? user.email ?? '',
        name: `${artist.first_name ?? ''} ${artist.last_name ?? ''}`.trim(),
        'metadata[artist_id]': artist.id,
        'metadata[studio_name]': artist.studio_name ?? '',
      }),
    });
    const customer = await customerRes.json();
    if (!customerRes.ok) {
      return jsonResponse(
        { error: customer.error?.message ?? 'Stripe customer failed' },
        502,
      );
    }
    customerId = customer.id;
    await admin
      .from('artists')
      .update({
        stripe_customer_id: customerId,
        updated_at: new Date().toISOString(),
      })
      .eq('id', artist.id);
  }

  const { success, cancel } = buildReturnUrls(returnBaseUrl);

  const sessionRes = await fetch(
    'https://api.stripe.com/v1/checkout/sessions',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${stripeKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        mode: 'subscription',
        customer: customerId!,
        client_reference_id: artist.id,
        'line_items[0][price]': priceId,
        'line_items[0][quantity]': '1',
        success_url: success,
        cancel_url: cancel,
        'subscription_data[metadata][artist_id]': artist.id,
        'metadata[artist_id]': artist.id,
        allow_promotion_codes: 'true',
      }),
    },
  );

  const session = await sessionRes.json();
  if (!sessionRes.ok) {
    return jsonResponse(
      { error: session.error?.message ?? 'Checkout session failed' },
      502,
    );
  }

  return jsonResponse({ url: session.url, session_id: session.id });
});
