#!/usr/bin/env node
/**
 * Génère un QR unique par compte DesK Tattoo.
 * Le payload est TOUJOURS `{WEB_APP_URL}/intake/{token}` — même URL que
 * le mini-router web (`lib/features/intake/web_intake_router.dart`).
 *
 * Usage :
 *   WEB_APP_URL=https://moonlit-medovik-0ae9fb.netlify.app \
 *     node generate.mjs --token abcdef0123456789
 *   node generate.mjs --url https://site.netlify.app/intake/abcdef0123456789
 */
import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { generateCodes } from '@liquid-js/qr-code-styling-cli';

const here = dirname(fileURLToPath(import.meta.url));
const outDir = join(here, 'out');
const logoPath = join(here, '../../assets/icon/app_icon.png');

const INTAKE_URL = /^https?:\/\/[^/\s]+\/intake\/([A-Za-z0-9_-]+)$/;

function argValue(flag) {
  const index = process.argv.indexOf(flag);
  if (index === -1 || index + 1 >= process.argv.length) return '';
  return process.argv[index + 1].trim();
}

function originFromEnv() {
  const raw = (process.env.WEB_APP_URL ?? '').trim().replace(/\/+$/, '');
  if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
    throw new Error(
      'WEB_APP_URL manquant. Ex. WEB_APP_URL=https://moonlit-medovik-0ae9fb.netlify.app',
    );
  }
  return raw;
}

function parseIntakeUrl(url) {
  const match = url.match(INTAKE_URL);
  if (!match) {
    throw new Error(
      `URL QR invalide (attendu https://host/intake/{token}) : ${url}`,
    );
  }
  return { url, token: match[1] };
}

function buildIntakeUrl(token) {
  const clean = token.trim();
  if (!/^[A-Za-z0-9_-]{8,}$/.test(clean)) {
    throw new Error(`Token QR invalide : ${token}`);
  }
  return parseIntakeUrl(`${originFromEnv()}/intake/${clean}`);
}

const style = {
  image: logoPath,
  qrOptions: {
    errorCorrectionLevel: 'Q',
  },
  imageOptions: {
    hideBackgroundDots: true,
    imageSize: 0.22,
    margin: 4,
  },
  dotsOptions: {
    type: 'rounded',
    color: '#5E1B89',
  },
  cornersSquareOptions: {
    type: 'extra-rounded',
    color: '#1A1224',
  },
  cornersDotOptions: {
    type: 'dot',
    color: '#5E1B89',
  },
  backgroundOptions: {
    color: '#ffffff',
  },
};

async function generateOne(intake) {
  const codes = await generateCodes(
    {
      ...style,
      data: intake.url,
    },
    'png',
    1024,
    here,
  );

  const entry = codes[intake.url];
  if (!entry?.buffer) {
    throw new Error(`Génération CLI échouée pour ${intake.url}`);
  }

  await mkdir(outDir, { recursive: true });
  const file = join(outDir, `${intake.token}.png`);
  await writeFile(file, entry.buffer);

  return {
    token: intake.token,
    url: intake.url,
    file,
  };
}

const tokenArg = argValue('--token');
const urlArg = argValue('--url');

let intake;
if (urlArg) {
  intake = parseIntakeUrl(urlArg.replace(/\/+$/, ''));
} else if (tokenArg) {
  intake = buildIntakeUrl(tokenArg);
} else {
  console.error('Passe --token <token> ou --url https://host/intake/<token>');
  process.exit(1);
}

const result = await generateOne(intake);
console.log(JSON.stringify(result, null, 2));
