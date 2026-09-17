/// Helpers partagés par les functions publiques d'accueil client (QR).

/// Un artiste peut recevoir des fiches clients uniquement si son abonnement
/// est en règle (ou s'il est admin).
export function isArtistEntitled(artist: {
  role?: string | null;
  subscription_status?: string | null;
}): boolean {
  if (artist.role === 'admin') return true;
  return (
    artist.subscription_status === 'active' ||
    artist.subscription_status === 'trialing'
  );
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
