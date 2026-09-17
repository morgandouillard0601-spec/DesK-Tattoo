import 'dart:math';

/// Lien public du formulaire QR : `{origin}/intake/{token}`.
/// Doit rester identique au mini-router web et à tools/intake-qr/generate.mjs.
class IntakeQrLink {
  const IntakeQrLink._();

  static final RegExp _tokenPattern = RegExp(r'^[A-Za-z0-9_-]{8,}$');
  static final RegExp _intakeUrlPattern = RegExp(
    r'^https?://[^/\s]+/intake/([A-Za-z0-9_-]+)$',
  );

  static String originOf(String webAppUrl) =>
      webAppUrl.trim().replaceAll(RegExp(r'/+$'), '');

  static bool isValidToken(String token) =>
      _tokenPattern.hasMatch(token.trim());

  /// 32 caractères hex, identique à `encode(gen_random_bytes(16), 'hex')`.
  static String generateToken() {
    final Random rng = Random.secure();
    return List<int>.generate(16, (_) => rng.nextInt(256))
        .map((int b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Construit l'URL encodée dans le QR d'un compte.
  static String build({
    required String webAppUrl,
    required String token,
  }) {
    final String origin = originOf(webAppUrl);
    final String clean = token.trim();
    if (origin.isEmpty) {
      throw ArgumentError('WEB_APP_URL vide');
    }
    if (!isValidToken(clean)) {
      throw ArgumentError('Token QR invalide');
    }
    return '$origin/intake/$clean';
  }

  static bool isValid(String url, {String? expectedToken}) {
    final String trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    final Match? match = _intakeUrlPattern.firstMatch(trimmed);
    if (match == null) return false;
    if (expectedToken == null) return true;
    return match.group(1) == expectedToken.trim();
  }

  static String? tokenOf(String url) {
    final Match? match = _intakeUrlPattern.firstMatch(
      url.trim().replaceAll(RegExp(r'/+$'), ''),
    );
    return match?.group(1);
  }
}
