import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';

import '../data/consent_pdf.dart';
import '../data/intake_repository.dart';
import '../domain/consent_text.dart';
import '../domain/intake_submission.dart';
import 'intake_success_screen.dart';

/// Formulaire public ouvert par le QR code du tatoueur.
/// Aucune authentification : le visiteur est un client du studio.
class IntakeFormScreen extends ConsumerStatefulWidget {
  const IntakeFormScreen({required this.token, super.key});

  final String token;

  @override
  ConsumerState<IntakeFormScreen> createState() => _IntakeFormScreenState();
}

class _IntakeFormScreenState extends ConsumerState<IntakeFormScreen> {
  static const int _minAge = 18;

  final GlobalKey<FormState> _identityKey = GlobalKey<FormState>();

  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _postalCode = TextEditingController();

  final Map<String, TextEditingController> _health =
      <String, TextEditingController>{
    for (final HealthQuestion q in ConsentText.healthQuestions)
      q.key: TextEditingController(),
  };

  final Map<String, bool> _accepted = <String, bool>{
    for (final ConsentCheckbox box in ConsentText.checkboxes) box.key: false,
  };

  final SignatureController _signature = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  DateTime? _birthDate;
  int _step = 0;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _signature.addListener(_onSignatureChanged);
  }

  @override
  void dispose() {
    _signature.removeListener(_onSignatureChanged);
    _signature.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _city.dispose();
    _postalCode.dispose();
    for (final TextEditingController c in _health.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onSignatureChanged() {
    // Réactive le bouton dès le premier trait.
    if (mounted) setState(() {});
  }

  bool get _isMinor {
    final DateTime? birth = _birthDate;
    if (birth == null) return false;
    return ageOn(birth, DateTime.now()) < _minAge;
  }

  bool get _requiredBoxesChecked => ConsentText.checkboxes
      .where((ConsentCheckbox b) => b.required)
      .every((ConsentCheckbox b) => _accepted[b.key] == true);

  Future<void> _pickBirthDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Date de naissance',
      locale: const Locale('fr'),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _error = null;
      });
    }
  }

  void _next() {
    setState(() => _error = null);

    if (_step == 0) {
      if (!(_identityKey.currentState?.validate() ?? false)) return;
      if (_birthDate == null) {
        setState(() => _error = 'Renseigne ta date de naissance');
        return;
      }
      if (_isMinor) {
        setState(() => _error = ConsentText.minorBlockedMessage);
        return;
      }
      if (_phone.text.trim().isEmpty && _email.text.trim().isEmpty) {
        setState(() => _error = 'Un téléphone ou un email est nécessaire');
        return;
      }
      setState(() => _step = 1);
      return;
    }

    if (_step == 1) {
      if (!_requiredBoxesChecked) {
        setState(
          () => _error = 'Coche les consentements obligatoires pour continuer',
        );
        return;
      }
      setState(() => _step = 2);
    }
  }

  void _back() {
    setState(() {
      _step -= 1;
      _error = null;
    });
  }

  Future<void> _submit(IntakeStudio studio) async {
    if (_signature.isEmpty) {
      setState(() => _error = 'Signature manquante');
      return;
    }
    if (!_requiredBoxesChecked || _birthDate == null || _isMinor) {
      setState(() => _error = 'Le formulaire est incomplet');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final Uint8List? signaturePng = await _signature.toPngBytes(
        width: 600,
        height: 240,
      );
      if (signaturePng == null) {
        setState(() {
          _busy = false;
          _error = 'Signature illisible, réessaie';
        });
        return;
      }

      final IntakeSubmission submission = IntakeSubmission(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        birthDate: _birthDate!,
        phone: _phone.text.trim(),
        email: _email.text.trim().toLowerCase(),
        address: _address.text.trim(),
        city: _city.text.trim(),
        postalCode: _postalCode.text.trim(),
        healthAnswers: <String, String>{
          for (final MapEntry<String, TextEditingController> e
              in _health.entries)
            e.key: e.value.text.trim(),
        },
        acceptedFlags: Map<String, bool>.from(_accepted),
      );

      final DateTime signedAt = DateTime.now();
      Uint8List? pdfBytes;
      try {
        pdfBytes = await buildConsentPdf(
          studio: studio,
          submission: submission,
          signaturePng: signaturePng,
          signedAt: signedAt,
        );
      } catch (_) {
        // Le contrat reste régénérable côté studio à partir des données et de
        // la signature : on n'empêche pas l'envoi.
        pdfBytes = null;
      }

      await ref.read(intakeRepositoryProvider).submit(
            token: widget.token,
            submission: submission,
            signaturePng: signaturePng,
            pdfBytes: pdfBytes,
          );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => IntakeSuccessScreen(
            studioName: studio.displayName,
            clientName: submission.fullName,
            pdfBytes: pdfBytes,
          ),
        ),
      );
    } on IntakeException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Envoi impossible. Réessaie dans un instant.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<IntakeStudio> studio =
        ref.watch(intakeStudioProvider(widget.token));

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              theme.colorScheme.surface,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: studio.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object e, _) => _ErrorState(
              message: e is IntakeException
                  ? e.message
                  : 'Ce lien n\'est plus valide.',
            ),
            data: (IntakeStudio s) => _buildForm(theme, s),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme, IntakeStudio studio) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    Icons.assignment_turned_in_rounded,
                    size: 38,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                studio.displayName,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fiche client et consentement avant tatouage',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              Material(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        _stepTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _StepDots(current: _step, total: 3),
                      const SizedBox(height: 18),
                      if (_step == 0) _buildIdentityStep(theme),
                      if (_step == 1) _buildConsentStep(theme),
                      if (_step == 2) _buildSignatureStep(theme),
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
                      const SizedBox(height: 20),
                      Row(
                        children: <Widget>[
                          if (_step > 0)
                            TextButton(
                              onPressed: _busy ? null : _back,
                              child: const Text('Retour'),
                            ),
                          const Spacer(),
                          FilledButton(
                            onPressed: _busy
                                ? null
                                : _step == 2
                                    ? () => _submit(studio)
                                    : _next,
                            child: _busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _step == 2 ? 'Signer et envoyer' : 'Continuer',
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tes informations sont transmises uniquement au studio.',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _stepTitle => switch (_step) {
        0 => 'Étape 1/3 — Tes informations',
        1 => 'Étape 2/3 — Santé et consentements',
        _ => 'Étape 3/3 — Signature',
      };

  Widget _buildIdentityStep(ThemeData theme) {
    final DateFormat dayShort = DateFormat('dd/MM/yyyy', 'fr_FR');

    return Form(
      key: _identityKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: _required,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _pickBirthDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date de naissance',
                prefixIcon: const Icon(Icons.cake_outlined),
                errorText: _isMinor ? 'Réservé aux majeurs' : null,
              ),
              child: Text(
                _birthDate == null
                    ? 'Sélectionner'
                    : '${dayShort.format(_birthDate!)} · '
                        '${ageOn(_birthDate!, DateTime.now())} ans',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _birthDate == null
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
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
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: (String? v) {
              final String value = (v ?? '').trim();
              if (value.isEmpty) return null;
              if (!value.contains('@') || !value.contains('.')) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _address,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              prefixIcon: Icon(Icons.home_outlined),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: _postalCode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Code postal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _city,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(labelText: 'Ville'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsentStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          ConsentText.intro,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        for (final HealthQuestion q in ConsentText.healthQuestions) ...<Widget>[
          TextFormField(
            controller: _health[q.key],
            maxLines: q.isShort ? 1 : 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: q.label,
              hintText: q.hint,
              alignLabelWithHint: !q.isShort,
            ),
          ),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 4),
        Text(
          'Le contrat',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Scrollbar(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: <Widget>[
                for (final ConsentClause clause in ConsentText.clauses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          clause.title,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          clause.body,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final ConsentCheckbox box in ConsentText.checkboxes)
          CheckboxListTile(
            value: _accepted[box.key] ?? false,
            onChanged: (bool? v) => setState(() {
              _accepted[box.key] = v ?? false;
              _error = null;
            }),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              box.label,
              style: theme.textTheme.bodySmall,
            ),
            subtitle: box.required
                ? Text(
                    'Obligatoire',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : null,
          ),
      ],
    );
  }

  Widget _buildSignatureStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          ConsentText.signatureNotice,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline,
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Signature(
            controller: _signature,
            height: 220,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _signature.isEmpty
                    ? 'Signe avec ton doigt dans le cadre'
                    : 'Signature enregistrée',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton.icon(
              onPressed:
                  _signature.isEmpty || _busy ? null : () => _signature.clear(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Effacer'),
            ),
          ],
        ),
      ],
    );
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.link_off_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Lien indisponible',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
