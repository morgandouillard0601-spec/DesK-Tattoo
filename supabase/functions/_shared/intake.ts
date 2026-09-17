/// Helpers partagés par les functions publiques d'accueil client (QR).

import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

/** Compte de test : le formulaire QR s'ouvre même sans abonnement ni fiche complète. */
export const TEST_INTAKE_EMAIL = 'morgandesk@gmail.com';

const ARTIST_INTAKE_FIELDS =
  'id, email, first_name, last_name, studio_name, city, role, subscription_status';

type IntakeArtistRow = {
  id: string;
  email?: string | null;
  first_name?: string | null;
  last_name?: string | null;
  studio_name?: string | null;
  city?: string | null;
  role?: string | null;
  subscription_status?: string | null;
};

/// Un artiste peut recevoir des fiches clients uniquement si son abonnement
/// est en règle (ou s'il est admin). Le compte de test passe toujours.
export function isArtistEntitled(artist: {
  role?: string | null;
  subscription_status?: string | null;
  email?: string | null;
}): boolean {
  if ((artist.email ?? '').trim().toLowerCase() === TEST_INTAKE_EMAIL) {
    return true;
  }
  if (artist.role === 'admin') return true;
  return (
    artist.subscription_status === 'active' ||
    artist.subscription_status === 'trialing'
  );
}

/// Résout le studio du QR. Si le token n'est pas encore en base (QR local),
/// on rattache le compte de test pour pouvoir essayer le formulaire.
export async function resolveIntakeArtist(
  admin: SupabaseClient,
  token: string,
): Promise<IntakeArtistRow | null> {
  const byToken = await admin
    .from('artists')
    .select(ARTIST_INTAKE_FIELDS)
    .eq('public_intake_token', token)
    .maybeSingle();

  if (byToken.data) return byToken.data as IntakeArtistRow;

  const byEmail = await admin
    .from('artists')
    .select(ARTIST_INTAKE_FIELDS)
    .ilike('email', TEST_INTAKE_EMAIL)
    .maybeSingle();

  if (byEmail.data) return byEmail.data as IntakeArtistRow;

  const { data: listed } = await admin.auth.admin.listUsers({ perPage: 200 });
  const user = (listed?.users ?? []).find(
    (u) => (u.email ?? '').trim().toLowerCase() === TEST_INTAKE_EMAIL,
  );
  if (!user) return null;

  const base = {
    id: user.id,
    email: TEST_INTAKE_EMAIL,
    first_name: 'Morgan',
    last_name: 'Desk',
    studio_name: 'DesK Tattoo Studio',
    city: 'Paris',
    role: 'admin',
    subscription_status: 'active',
  };

  const withToken = await admin
    .from('artists')
    .upsert({ ...base, public_intake_token: token })
    .select(ARTIST_INTAKE_FIELDS)
    .single();
  if (withToken.data) return withToken.data as IntakeArtistRow;

  const withoutToken = await admin
    .from('artists')
    .upsert(base)
    .select(ARTIST_INTAKE_FIELDS)
    .single();
  return (withoutToken.data as IntakeArtistRow | null) ?? null;
}

export function decodeBase64(value: string): Uint8Array {
  // Tolère les data URLs ("data:image/png;base64,....").
  const commaIndex = value.indexOf(',');
  const payload = value.startsWith('data:') && commaIndex !== -1
    ? value.slice(commaIndex + 1)
    : value;
  const binary = atob(payload.trim());
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

export async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

export function clientIpFrom(req: Request): string {
  const forwarded = req.headers.get('x-forwarded-for');
  if (forwarded && forwarded.length > 0) {
    return forwarded.split(',')[0].trim();
  }
  return req.headers.get('cf-connecting-ip') ?? 'unknown';
}

/// Âge révolu à la date du jour, ou null si la date est absente/invalide.
export function ageFromBirthDate(birthDate: string | null): number | null {
  if (!birthDate) return null;
  const parsed = new Date(birthDate);
  if (Number.isNaN(parsed.getTime())) return null;

  const today = new Date();
  let age = today.getUTCFullYear() - parsed.getUTCFullYear();
  const monthDiff = today.getUTCMonth() - parsed.getUTCMonth();
  if (monthDiff < 0 || (monthDiff === 0 && today.getUTCDate() < parsed.getUTCDate())) {
    age -= 1;
  }
  return age;
}

export function asTrimmedString(value: unknown, maxLength = 200): string {
  if (typeof value !== 'string') return '';
  return value.trim().slice(0, maxLength);
}

/// Chiffres uniquement, format FR (`+33 6…` → `06…`) pour matcher une fiche.
export function normalizePhone(value: string): string {
  const compact = value.replace(/[^\d+]/g, '');
  let digits = compact;
  if (digits.startsWith('+33')) {
    digits = `0${digits.slice(3)}`;
  } else if (digits.startsWith('0033')) {
    digits = `0${digits.slice(4)}`;
  } else if (digits.startsWith('33') && digits.length >= 11) {
    digits = `0${digits.slice(2)}`;
  }
  return digits.replace(/\D/g, '');
}
