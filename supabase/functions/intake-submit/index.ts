import { adminClient, corsHeaders, jsonResponse } from '../_shared/cors.ts';
import {
  ageFromBirthDate,
  asTrimmedString,
  clientIpFrom,
  decodeBase64,
  isArtistEntitled,
  sha256Hex,
} from '../_shared/intake.ts';

const MAX_PDF_BASE64 = 12_000_000; // ~9 MB
const MAX_PNG_BASE64 = 3_000_000; // ~2.2 MB
const MIN_AGE = 18;

/// Function PUBLIQUE (verify_jwt = false).
/// Le client anonyme n'écrit jamais en base directement : cette function est
/// le seul point d'entrée, en service role, avec validation complète.
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'Corps de requête invalide' }, 400);
  }

  const token = asTrimmedString(body.token, 128);
  if (token.length < 8) {
    return jsonResponse({ error: 'Lien invalide' }, 400);
  }

  const firstName = asTrimmedString(body.first_name, 80);
  const lastName = asTrimmedString(body.last_name, 80);
  const phone = asTrimmedString(body.phone, 40);
  const email = asTrimmedString(body.email, 160).toLowerCase();
  const address = asTrimmedString(body.address, 200);
  const city = asTrimmedString(body.city, 100);
  const postalCode = asTrimmedString(body.postal_code, 20);
  const birthDate = asTrimmedString(body.birth_date, 20);

  if (firstName.length === 0 || lastName.length === 0) {
    return jsonResponse({ error: 'Nom et prénom obligatoires' }, 400);
  }
  if (phone.length === 0 && email.length === 0) {
    return jsonResponse(
      { error: 'Un téléphone ou un email est obligatoire' },
      400,
    );
  }

  const age = ageFromBirthDate(birthDate);
  if (age === null) {
    return jsonResponse({ error: 'Date de naissance invalide' }, 400);
  }
  if (age < MIN_AGE) {
    return jsonResponse(
      {
        error:
          'Le tatouage des mineurs nécessite la présence et l\'autorisation du représentant légal. Rapproche-toi du studio.',
      },
      422,
    );
  }

  const acceptedTerms = body.accepted_terms === true;
  const acceptedHealth = body.accepted_health === true;
  const acceptedAftercare = body.accepted_aftercare === true;
  const acceptedImageRights = body.accepted_image_rights === true;

  if (!acceptedTerms || !acceptedHealth || !acceptedAftercare) {
    return jsonResponse(
      { error: 'Les consentements obligatoires ne sont pas tous acceptés' },
      400,
    );
  }

  const signatureBase64 = typeof body.signature_png === 'string'
    ? body.signature_png
    : '';
  const pdfBase64 = typeof body.pdf === 'string' ? body.pdf : '';

  if (signatureBase64.length === 0) {
    return jsonResponse({ error: 'Signature manquante' }, 400);
  }
  if (signatureBase64.length > MAX_PNG_BASE64) {
    return jsonResponse({ error: 'Signature trop volumineuse' }, 413);
  }
  if (pdfBase64.length > MAX_PDF_BASE64) {
    return jsonResponse({ error: 'Contrat trop volumineux' }, 413);
  }

  let signatureBytes: Uint8Array;
  let pdfBytes: Uint8Array | null = null;
  try {
    signatureBytes = decodeBase64(signatureBase64);
    if (pdfBase64.length > 0) {
      pdfBytes = decodeBase64(pdfBase64);
    }
  } catch {
    return jsonResponse({ error: 'Fichiers illisibles' }, 400);
  }

  const healthAnswers = body.health_answers && typeof body.health_answers === 'object'
    ? body.health_answers
    : {};

  const admin = adminClient();

  // -------------------------------------------------------------------------
  // Artiste ciblé par le QR
  // -------------------------------------------------------------------------
  const { data: artist, error: artistError } = await admin
    .from('artists')
    .select('id, studio_name, role, subscription_status')
    .eq('public_intake_token', token)
    .maybeSingle();

  if (artistError || !artist) {
    return jsonResponse({ error: 'Ce lien n\'est plus valide' }, 404);
  }
  if (!isArtistEntitled(artist)) {
    return jsonResponse(
      { error: 'Ce studio n\'accepte pas de nouvelles fiches pour le moment' },
      403,
    );
  }

  // -------------------------------------------------------------------------
  // Client existant (même email ou même téléphone chez cet artiste) ou création
  // -------------------------------------------------------------------------
  let clientId: string | null = null;

  if (email.length > 0) {
    const { data: byEmail } = await admin
      .from('clients')
      .select('id')
      .eq('artist_id', artist.id)
      .eq('email', email)
      .maybeSingle();
    clientId = byEmail?.id ?? null;
  }

  if (!clientId && phone.length > 0) {
    const { data: byPhone } = await admin
      .from('clients')
      .select('id')
      .eq('artist_id', artist.id)
      .eq('phone', phone)
      .maybeSingle();
    clientId = byPhone?.id ?? null;
  }

  const clientPayload = {
    artist_id: artist.id,
    first_name: firstName,
    last_name: lastName,
    phone,
    email,
    address,
    city,
    postal_code: postalCode,
    birth_date: birthDate,
    source: 'intake',
  };

  if (clientId) {
    const { error: updateError } = await admin
      .from('clients')
      .update(clientPayload)
      .eq('id', clientId);
    if (updateError) {
      return jsonResponse({ error: 'Mise à jour de la fiche impossible' }, 502);
    }
  } else {
    const { data: created, error: insertError } = await admin
      .from('clients')
      .insert(clientPayload)
      .select('id')
      .single();
    if (insertError || !created) {
      return jsonResponse({ error: 'Création de la fiche impossible' }, 502);
    }
    clientId = created.id;
  }

  // -------------------------------------------------------------------------
  // Contrat signé
  // -------------------------------------------------------------------------
  const ipHash = await sha256Hex(clientIpFrom(req));
  const userAgent = asTrimmedString(req.headers.get('user-agent') ?? '', 300);

  const { data: consent, error: consentError } = await admin
    .from('client_consents')
    .insert({
      artist_id: artist.id,
      client_id: clientId,
      full_name: `${firstName} ${lastName}`,
      email,
      phone,
      birth_date: birthDate,
      health_answers: healthAnswers,
      accepted_terms: acceptedTerms,
      accepted_health: acceptedHealth,
      accepted_aftercare: acceptedAftercare,
      accepted_image_rights: acceptedImageRights,
      signed_at: new Date().toISOString(),
      ip_hash: ipHash,
      user_agent: userAgent,
    })
    .select('id')
    .single();

  if (consentError || !consent) {
    return jsonResponse({ error: 'Enregistrement du contrat impossible' }, 502);
  }

  const folder = `${artist.id}/${consent.id}`;
  const signaturePath = `${folder}/signature.png`;
  const pdfPath = pdfBytes ? `${folder}/contrat.pdf` : null;

  const signatureUpload = await admin.storage
    .from('consents')
    .upload(signaturePath, signatureBytes, {
      contentType: 'image/png',
      upsert: true,
    });

  if (signatureUpload.error) {
    return jsonResponse({ error: 'Envoi de la signature impossible' }, 502);
  }

  if (pdfBytes && pdfPath) {
    const pdfUpload = await admin.storage
      .from('consents')
      .upload(pdfPath, pdfBytes, {
        contentType: 'application/pdf',
        upsert: true,
      });
    if (pdfUpload.error) {
      // La signature et les données restent exploitables : le PDF sera
      // régénérable côté app. On n'échoue pas la soumission pour autant.
      console.error('pdf upload failed', pdfUpload.error);
    }
  }

  await admin
    .from('client_consents')
    .update({
      signature_path: signaturePath,
      pdf_path: pdfPath,
    })
    .eq('id', consent.id);

  return jsonResponse({
    ok: true,
    consent_id: consent.id,
    client_id: clientId,
    studio_name: artist.studio_name ?? '',
  });
});
