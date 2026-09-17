import { adminClient, corsHeaders, jsonResponse } from '../_shared/cors.ts';
import {
  asTrimmedString,
  isArtistEntitled,
  resolveIntakeArtist,
} from '../_shared/intake.ts';

/// Function PUBLIQUE (verify_jwt = false).
/// Le client qui scanne le QR n'a pas de compte : on renvoie juste de quoi
/// personnaliser l'en-tête du formulaire, rien de sensible.
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  let token = '';
  try {
    const body = await req.json();
    token = asTrimmedString(body?.token, 128);
  } catch {
    return jsonResponse({ error: 'Corps de requête invalide' }, 400);
  }

  if (token.length < 8) {
    return jsonResponse({ error: 'Lien invalide' }, 400);
  }

  const admin = adminClient();
  const artist = await resolveIntakeArtist(admin, token);

  if (!artist) {
    return jsonResponse({ error: 'Ce lien n\'est plus valide' }, 404);
  }

  if (!isArtistEntitled(artist)) {
    return jsonResponse(
      { error: 'Ce studio n\'accepte pas de nouvelles fiches pour le moment' },
      403,
    );
  }

  return jsonResponse({
    studio_name: artist.studio_name ?? '',
    first_name: artist.first_name ?? '',
    last_name: artist.last_name ?? '',
    city: artist.city ?? '',
  });
});
