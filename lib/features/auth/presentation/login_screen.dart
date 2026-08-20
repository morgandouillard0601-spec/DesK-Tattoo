import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _step1Key = GlobalKey<FormState>();
  final GlobalKey<FormState> _step2Key = GlobalKey<FormState>();
  final GlobalKey<FormState> _step3Key = GlobalKey<FormState>();
  final GlobalKey<FormState> _loginKey = GlobalKey<FormState>();

  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _studio = TextEditingController();
  final TextEditingController _experience = TextEditingController(text: '1');
  final TextEditingController _bio = TextEditingController();
  final TextEditingController _instagram = TextEditingController();
  final TextEditingController _customSpecialty = TextEditingController();

  static const List<String> _specialtyOptions = <String>[
    'Black & Grey',
    'Réalisme',
    'Géométrique',
    'Traditionnel',
    'Fineline',
    'Japonais',
    'Lettering',
    'Dotwork',
    'Aquarelle',
    'Ornemental',
  ];

  final Set<String> _specialties = <String>{};

  bool _isRegister = true;
  int _step = 0;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final AuthState auth = ref.read(authProvider);
      setState(() {
        _isRegister = !auth.hasLocalAccount;
        _step = 0;
      });
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _studio.dispose();
    _experience.dispose();
    _bio.dispose();
    _instagram.dispose();
    _customSpecialty.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isRegister = !_isRegister;
      _step = 0;
      _error = null;
      _confirm.clear();
    });
  }

  Future<void> _submitLogin() async {
    setState(() => _error = null);
    if (!(_loginKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      await ref.read(authProvider.notifier).login(
            email: _email.text,
            password: _password.text,
          );
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Une erreur est survenue. Réessaie.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _nextOrCreate() async {
    setState(() => _error = null);

    if (_step == 0) {
      if (!(_step1Key.currentState?.validate() ?? false)) return;
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      if (!(_step2Key.currentState?.validate() ?? false)) return;
      setState(() => _step = 2);
      return;
    }

    if (!(_step3Key.currentState?.validate() ?? false)) return;
    if (_specialties.isEmpty) {
      setState(() => _error = 'Choisis au moins une spécialité');
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(authProvider.notifier).register(
            email: _email.text,
            password: _password.text,
            profile: RegisterProfileInput(
              firstName: _firstName.text,
              lastName: _lastName.text,
              phone: _phone.text,
              studioName: _studio.text,
              specialties: _specialties.toList()..sort(),
              experienceYears: int.tryParse(_experience.text) ?? 0,
              bio: _bio.text,
              instagram: _instagram.text,
            ),
          );
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Une erreur est survenue. Réessaie.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addCustomSpecialty() {
    final String value = _customSpecialty.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _specialties.add(value);
      _customSpecialty.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Size size = MediaQuery.sizeOf(context);
    final bool wide = size.width >= 700;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              theme.colorScheme.surface,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 48 : 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.brush_rounded,
                          size: 44,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'DesK Tattoo',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isRegister
                          ? 'Crée ton compte studio'
                          : 'Connecte-toi à ton studio',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Material(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                        child: _isRegister
                            ? _buildRegister(theme)
                            : _buildLogin(theme),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogin(ThemeData theme) {
    return Form(
      key: _loginKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Connexion',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: _emailValidator,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitLogin(),
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (String? v) {
              if (v == null || v.isEmpty) return 'Mot de passe requis';
              return null;
            },
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 14),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _busy ? null : _submitLogin,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('Se connecter'),
          ),
          TextButton(
            onPressed: _busy ? null : _toggleMode,
            child: const Text('Pas de compte ? Créer un compte'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegister(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Créer un compte',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _stepTitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        _StepDots(current: _step, total: 3),
        const SizedBox(height: 18),
        if (_step == 0) _buildStep1(),
        if (_step == 1) _buildStep2(),
        if (_step == 2) _buildStep3(theme),
        if (_error != null) ...<Widget>[
          const SizedBox(height: 14),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 22),
        Row(
          children: <Widget>[
            if (_step > 0)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _step -= 1;
                          _error = null;
                        }),
                child: const Text('Retour'),
              ),
            const Spacer(),
            FilledButton(
              onPressed: _busy ? null : _nextOrCreate,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(_step == 2 ? 'Créer mon compte' : 'Continuer'),
            ),
          ],
        ),
        TextButton(
          onPressed: _busy ? null : _toggleMode,
          child: const Text('Déjà un compte ? Se connecter'),
        ),
        Text(
          'Ces infos ouvrent ta session et apparaissent dans ton profil.',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String get _stepTitle => switch (_step) {
        0 => 'Étape 1/3 — Accès au compte',
        1 => 'Étape 2/3 — Identité & studio',
        _ => 'Étape 3/3 — Spécialités & détails',
      };

  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        children: <Widget>[
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'toi@studio.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: _emailValidator,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              hintText: '6 caractères minimum',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (String? v) {
              if (v == null || v.isEmpty) return 'Mot de passe requis';
              if (v.length < 6) return 'Au moins 6 caractères';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirm,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Confirmer le mot de passe',
              prefixIcon: Icon(Icons.lock_rounded),
            ),
            validator: (String? v) {
              if (v != _password.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: _required,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                  ),
                  validator: _required,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              hintText: '+33 6 …',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: _required,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _studio,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Nom du studio',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            validator: _required,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(ThemeData theme) {
    return Form(
      key: _step3Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: _experience,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Années d\'expérience',
              prefixIcon: Icon(Icons.timeline_rounded),
            ),
            validator: (String? v) {
              if (v == null || v.trim().isEmpty) return 'Requis';
              final int? n = int.tryParse(v);
              if (n == null || n < 0) return 'Nombre invalide';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Spécialités',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ..._specialtyOptions.map((String s) {
                final bool selected = _specialties.contains(s);
                return FilterChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (bool v) {
                    setState(() {
                      if (v) {
                        _specialties.add(s);
                      } else {
                        _specialties.remove(s);
                      }
                    });
                  },
                );
              }),
              ..._specialties
                  .where((String s) => !_specialtyOptions.contains(s))
                  .map(
                    (String s) => FilterChip(
                      label: Text(s),
                      selected: true,
                      onSelected: (_) => setState(() => _specialties.remove(s)),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _customSpecialty,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Autre spécialité',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addCustomSpecialty(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _addCustomSpecialty,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _instagram,
            decoration: const InputDecoration(
              labelText: 'Instagram (optionnel)',
              hintText: '@ton.studio',
              prefixIcon: Icon(Icons.camera_alt_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _bio,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Bio (optionnel)',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  String? _emailValidator(String? v) {
    final String value = (v ?? '').trim();
    if (value.isEmpty) return 'Email requis';
    if (!value.contains('@') || !value.contains('.')) {
      return 'Email invalide';
    }
    return null;
  }

  String? _required(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requis';
    return null;
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: List<Widget>.generate(total, (int i) {
        final bool active = i <= current;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
