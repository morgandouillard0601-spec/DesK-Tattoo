# DesK Tattoo — Application mobile Flutter

Base d'une application mobile Flutter (iOS + Android) pour DesK Tattoo.

## Stack technique

- **Flutter 3.44+** / **Dart 3.12+**
- **Riverpod** — gestion d'état réactive et testable
- **go_router** — navigation déclarative basée sur les URL
- **Dio** — client HTTP avec intercepteurs et logging
- **shared_preferences** + **flutter_secure_storage** — stockage local clair / chiffré
- **flutter_dotenv** — variables d'environnement par build
- **flutter_localizations** + ARB — internationalisation FR / EN
- **flutter_lints** + règles strictes — qualité de code

## Pré-requis

- Flutter SDK installé (`brew install --cask flutter`)
- Xcode (pour iOS) et Android Studio (pour Android)
- CocoaPods (`sudo gem install cocoapods`)

Vérifiez votre installation:

```bash
flutter doctor
```

## Démarrage rapide

```bash
flutter pub get
flutter gen-l10n
flutter run
```

Lancer sur un appareil spécifique:

```bash
flutter devices
flutter run -d <device_id>
```

## Configuration d'environnement

Les variables sont chargées depuis `.env` à la racine du projet (déclaré comme asset dans `pubspec.yaml`).

Copiez `.env.example` en `.env` et adaptez les valeurs:

```bash
cp .env.example .env
```

Variables disponibles:

| Variable | Description | Défaut |
| --- | --- | --- |
| `APP_NAME` | Nom affiché de l'application | `DesK Tattoo` |
| `APP_ENV` | Environnement (`dev`, `staging`, `prod`) | `dev` |
| `API_BASE_URL` | URL de base de l'API | `https://api.example.com` |
| `API_TIMEOUT_MS` | Timeout HTTP en millisecondes | `15000` |

## Architecture du projet

```
lib/
├── main.dart                       # Bootstrap (dotenv, prefs, ProviderScope)
├── app.dart                        # MaterialApp.router + i18n + thème
├── core/
│   ├── config/                     # AppConfig + providers de configuration
│   ├── network/                    # Dio client (intercepteurs, logging)
│   ├── router/                     # go_router (routes nommées)
│   ├── storage/                    # SharedPreferences + Secure Storage
│   └── theme/                      # ThemeData M3 + ThemeModeController
├── features/
│   ├── splash/presentation/        # Écran de démarrage
│   └── home/presentation/          # Écran d'accueil
├── shared/widgets/                 # Widgets réutilisables
└── l10n/
    ├── app_en.arb                  # Traductions anglaises
    ├── app_fr.arb                  # Traductions françaises
    └── generated/                  # Code généré (à ne pas modifier)
```

## Internationalisation

Les fichiers ARB sont dans `lib/l10n/`. Pour ajouter une nouvelle clé:

1. Modifiez `lib/l10n/app_en.arb` et `lib/l10n/app_fr.arb`
2. Régénérez:

```bash
flutter gen-l10n
```

3. Utilisez dans un widget:

```dart
final l10n = AppLocalizations.of(context);
Text(l10n.welcome);
```

## Thème

Le thème Material 3 (clair + sombre) est défini dans `lib/core/theme/app_theme.dart`. Le mode est piloté par `ThemeModeController` (persisté dans `SharedPreferences`).

## Commandes utiles

```bash
flutter analyze            # Linter strict
flutter test               # Tests unitaires
flutter gen-l10n           # Régénération i18n
flutter pub upgrade --major-versions  # Mise à jour des dépendances
flutter build ipa          # Build iOS
flutter build apk          # Build Android (APK)
flutter build appbundle    # Build Android (Play Store)
```

## Versions minimales

- **iOS**: 13.0
- **Android**: SDK 24 (Android 7.0)
- **Bundle ID iOS / applicationId Android**: `com.desktattoo.desk_tattoo`

## Prochaines étapes suggérées

- Configurer le splash natif (`flutter_native_splash`) et l'icône (`flutter_launcher_icons`)
- Ajouter Firebase / Sentry pour le crash reporting
- Mettre en place un pipeline CI (analyze + test + build)
- Définir les flavors `dev` / `staging` / `prod`
