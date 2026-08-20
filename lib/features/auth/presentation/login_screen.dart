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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _isRegister = true;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final AuthState auth = ref.read(authProvider);
      setState(() => _isRegister = !auth.hasLocalAccount);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      final AuthNotifier auth = ref.read(authProvider.notifier);
      if (_isRegister) {
        await auth.register(
          email: _email.text,
          password: _password.text,
        );
      } else {
        await auth.login(
          email: _email.text,
          password: _password.text,
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Size size = MediaQuery.sizeOf(context);
    final bool wide = size.width >= 700;

    final Widget form = _AuthCard(
      formKey: _formKey,
      email: _email,
      password: _password,
      confirm: _confirm,
      isRegister: _isRegister,
      obscure: _obscure,
      busy: _busy,
      error: _error,
      onToggleObscure: () => setState(() => _obscure = !_obscure),
      onToggleMode: () => setState(() {
        _isRegister = !_isRegister;
        _error = null;
        _confirm.clear();
      }),
      onSubmit: _busy ? null : _submit,
    );

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
                constraints: const BoxConstraints(maxWidth: 440),
                child: form,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.formKey,
    required this.email,
    required this.password,
    required this.confirm,
    required this.isRegister,
    required this.obscure,
    required this.busy,
    required this.error,
    required this.onToggleObscure,
    required this.onToggleMode,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirm;
  final bool isRegister;
  final bool obscure;
  final bool busy;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onToggleMode;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
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
          isRegister
              ? 'Crée ton compte studio'
              : 'Connecte-toi à ton studio',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        Material(
          color: theme.colorScheme.surfaceContainerLowest,
          elevation: 0,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    isRegister ? 'Créer un compte' : 'Connexion',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const <String>[
                      AutofillHints.email,
                    ],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'toi@studio.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (String? v) {
                      final String value = (v ?? '').trim();
                      if (value.isEmpty) return 'Email requis';
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: password,
                    obscureText: obscure,
                    autofillHints: <String>[
                      if (isRegister)
                        AutofillHints.newPassword
                      else
                        AutofillHints.password,
                    ],
                    textInputAction:
                        isRegister ? TextInputAction.next : TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!isRegister) onSubmit?.call();
                    },
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      hintText: '6 caractères minimum',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: onToggleObscure,
                        icon: Icon(
                          obscure
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
                  if (isRegister) ...<Widget>[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: confirm,
                      obscureText: obscure,
                      autofillHints: const <String>[
                        AutofillHints.newPassword,
                      ],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => onSubmit?.call(),
                      decoration: const InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                        prefixIcon: Icon(Icons.lock_rounded),
                      ),
                      validator: (String? v) {
                        if (v != password.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ),
                  ],
                  if (error != null) ...<Widget>[
                    const SizedBox(height: 14),
                    Text(
                      error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: onSubmit,
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isRegister ? 'Créer mon compte' : 'Se connecter',
                          ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: busy ? null : onToggleMode,
                    child: Text(
                      isRegister
                          ? 'Déjà un compte ? Se connecter'
                          : 'Pas de compte ? Créer un compte',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stocké localement pour l’instant — synchronisé '
                    'automatiquement dès que la base est branchée.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
