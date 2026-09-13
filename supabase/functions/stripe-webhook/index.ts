import {
  adminClient,
  corsHeaders,
  jsonResponse,
  mapStripeStatus,
} from '../_shared/cors.ts';

async function readStripeEvent(req: Request): Promise<{
  event: Record<string, unknown> | null;
  error?: Response;
}> {
  const secret = Deno.env.get('STRIPE_WEBHOOK_SECRET');
  const stripeKey = Deno.env.get('STRIPE_SECRET_KEY');
  if (!secret || !stripeKey) {
    return {
      error: jsonResponse({ error: 'Webhook not configured' }, 500),
    };
  }

  const signature = req.headers.get('stripe-signature');
  if (!signature) {
    return { error: jsonResponse({ error: 'Missing stripe-signature' }, 400) };
  }

  const body = await req.text();

  // Verify via Stripe API (constructEvent alternative for Deno without SDK crypto pain)
  // Prefer stripe.webhooks.constructEvent when available; here we use the
  // Stripe signature verification endpoint pattern via manual HMAC.
  const encoder = new TextEncoder();
  const parts = Object.fromEntries(
    signature.split(',').map((p) => {
      const [k, v] = p.split('=');
      return [k, v];
    }),
  );
  const timestamp = parts['t'];
  const v1 = parts['v1'];
  if (!timestamp || !v1) {
    return { error: jsonResponse({ error: 'Invalid signature header' }, 400) };
  }

  const signedPayload = `${timestamp}.${body}`;
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const mac = await crypto.subtle.sign('HMAC', key, encoder.encode(signedPayload));
  const expected = Array.from(new Uint8Array(mac))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');

  if (expected !== v1) {
    // Stripe may send multiple v1 signatures; accept if any matches
    const allV1 = signature
      .split(',')
      .filter((p) => p.startsWith('v1='))
      .map((p) => p.slice(3));
    if (!allV1.includes(expected)) {
      return { error: jsonResponse({ error: 'Invalid signature' }, 400) };
    }
  }

  try {
    return { event: JSON.parse(body) as Record<string, unknown> };
  } catch {
    return { error: jsonResponse({ error: 'Invalid JSON' }, 400) };
  }
}

async function updateArtistById(
  artistId: string,
  patch: Record<string, unknown>,
) {
  const admin = adminClient();
  await admin
    .from('artists')
    .update({ ...patch, updated_at: new Date().toISOString() })
    .eq('id', artistId);
}

async function updateArtistByCustomer(
  customerId: string,
  patch: Record<string, unknown>,
) {
  const admin = adminClient();
  await admin
    .from('artists')
    .update({ ...patch, updated_at: new Date().toISOString() })
    .eq('stripe_customer_id', customerId);
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const verified = await readStripeEvent(req);
  if (verified.error) return verified.error;
  const event = verified.event!;
  const type = event.type as string;
  const dataObject = (event.data as { object: Record<string, unknown> }).object;

  try {
    switch (type) {
      case 'checkout.session.completed': {
        const artistId =
          (dataObject.client_reference_id as string) ||
          ((dataObject.metadata as Record<string, string> | undefined)
            ?.artist_id ?? '');
        const customerId = dataObject.customer as string | undefined;
        const subscriptionId = dataObject.subscription as string | undefined;
        if (artistId) {
          await updateArtistById(artistId, {
            stripe_customer_id: customerId ?? null,
            stripe_subscription_id: subscriptionId ?? null,
            subscription_status: 'active',
            onboarding_completed_at: new Date().toISOString(),
          });
        }
        break;
      }
      case 'customer.subscription.updated':
      case 'customer.subscription.deleted': {
        const customerId = dataObject.customer as string;
        const status = mapStripeStatus(dataObject.status as string);
        const periodEnd = dataObject.current_period_end
          ? new Date((dataObject.current_period_end as number) * 1000)
              .toISOString()
          : null;
        await updateArtistByCustomer(customerId, {
          stripe_subscription_id: dataObject.id,
          subscription_status: type.endsWith('deleted') ? 'canceled' : status,
          subscription_current_period_end: periodEnd,
        });
        break;
      }
      case 'invoice.payment_succeeded': {
        const customerId = dataObject.customer as string;
        const subscriptionId = dataObject.subscription as string | undefined;
        await updateArtistByCustomer(customerId, {
          subscription_status: 'active',
          ...(subscriptionId
            ? { stripe_subscription_id: subscriptionId }
            : {}),
        });
        break;
      }
      case 'invoice.payment_failed': {
        const customerId = dataObject.customer as string;
        await updateArtistByCustomer(customerId, {
          subscription_status: 'past_due',
        });
        break;
      }
      default:
        break;
    }
  } catch (e) {
    console.error('webhook handler error', e);
    return jsonResponse({ error: 'Handler failed' }, 500);
  }

  return jsonResponse({ received: true });
});
