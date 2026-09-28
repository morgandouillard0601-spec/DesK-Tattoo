import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/form_sheet_scaffold.dart';
import '../../data/artist_repository.dart';
import '../../domain/artist.dart';

/// Mêmes suggestions qu'à l'inscription, complétées par une saisie libre.
const List<String> _specialtyOptions = <String>[
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

Future<bool?> showProfileEditSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const ProfileEditSheet(),
  );
}

class ProfileEditSheet extends ConsumerStatefulWidget {
  const ProfileEditSheet({super.key});

  @override
  ConsumerState<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<ProfileEditSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _studio;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _siret;
  late final TextEditingController _experience;
  late final TextEditingController _instagram;
  late final TextEditingController _bio;
  final TextEditingController _customSpecialty = TextEditingController();

  late final Set<String> _specialties;

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final Artist artist = ref.read(artistProvider);
    _firstName = TextEditingController(text: artist.firstName);
    _lastName = TextEditingController(text: artist.lastName);
    _phone = TextEditingController(text: artist.phone);
    _studio = TextEditingController(text: artist.studioName);
    _address = TextEditingController(text: artist.address);
    _city = TextEditingController(text: artist.city);
    _siret = TextEditingController(text: artist.siret);
    _experience = TextEditingController(text: artist.experienceYears.toString());
    _instagram = TextEditingController(text: artist.instagram ?? '');
    _bio = TextEditingController(text: artist.bio ?? '');
    _specialties = <String>{...artist.specialties};
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _studio.dispose();
    _address.dispose();
    _city.dispose();
    _siret.dispose();
    _experience.dispose();
    _instagram.dispose();
    _bio.dispose();
    _customSpecialty.dispose();
    super.dispose();
  }

  void _addCustomSpecialty() {
    final String value = _customSpecialty.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _specialties.add(value);
      _customSpecialty.clear();
    });
  }

  String? _required(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requis';
    return null;
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_specialties.isEmpty) {
      setState(() => _error = 'Choisis au moins une spécialité');
      return;
    }

    setState(() => _busy = true);

    final Artist current = ref.read(artistProvider);
    final String bio = _bio.text.trim();
    final String instagram = _instagram.text.trim();

    final Artist updated = current.copyWith(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      phone: _phone.text.trim(),
      studioName: _studio.text.trim(),
      address: _address.text.trim(),
      city: _city.text.trim(),
      siret: _siret.text.replaceAll(RegExp(r'\s'), ''),
      specialties: _specialties.toList()..sort(),
      experienceYears: int.tryParse(_experience.text) ?? 0,
      bio: bio.isEmpty ? null : bio,
      instagram: instagram.isEmpty ? null : instagram,
    );

    try {
      await ref.read(artistProvider.notifier).saveProfile(updated);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Enregistrement impossible. Vérifie ta connexion.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Artist artist = ref.watch(artistProvider);

    return FormSheetScaffold(
      title: 'Mes informations',
      canSave: !_busy,
      onSave: _save,
      saveLabel: _busy ? 'Enregistrement…' : 'Enregistrer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _SectionTitle('Identité'),
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
                // L'email est l'identifiant de connexion : le changer demande
                // une revérification par mail, hors périmètre de ce formulaire.
                TextField(
                  enabled: false,
                  controller: TextEditingController(text: artist.email),
                  decoration: const InputDecoration(
                    labelText: 'Email (identifiant de connexion)',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionTitle('Studio'),
                TextFormField(
                  controller: _studio,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nom du salon',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                  validator: _required,
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
                  validator: _required,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _city,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Ville',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _siret,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'SIRET',
                    hintText: '14 chiffres',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (String? v) {
                    final String digits = (v ?? '').replaceAll(RegExp(r'\s'), '');
                    if (digits.isEmpty) return 'Requis';
                    if (digits.length != 14 || int.tryParse(digits) == null) {
                      return 'SIRET invalide (14 chiffres)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                const _SectionTitle('Activité'),
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
          ),
          const SizedBox(height: 22),
          const _SectionTitle('Spécialités'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ..._specialtyOptions.map((String s) {
                return FilterChip(
                  label: Text(s),
                  selected: _specialties.contains(s),
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
          if (_error != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
