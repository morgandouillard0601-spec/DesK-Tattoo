import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../profile/data/artist_repository.dart';
import '../../profile/domain/artist.dart';

class AdminStudiosScreen extends ConsumerStatefulWidget {
  const AdminStudiosScreen({super.key});

  @override
  ConsumerState<AdminStudiosScreen> createState() => _AdminStudiosScreenState();
}

class _AdminStudiosScreenState extends ConsumerState<AdminStudiosScreen> {
  late Future<List<Artist>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(artistProvider.notifier).listAllStudiosForAdmin();
  }

  Future<void> _reload() async {
    setState(() {
      _future = ref.read(artistProvider.notifier).listAllStudiosForAdmin();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dossiers studios'),
      ),
      body: FutureBuilder<List<Artist>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<Artist>> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<Artist> studios = snap.data ?? const <Artist>[];
          if (studios.isEmpty) {
            return Center(
              child: Text(
                'Aucun dossier studio pour le moment.',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: studios.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int i) {
                final Artist a = studios[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        a.initials,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      a.studioName.isEmpty ? a.fullName : a.studioName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      [
                        if (a.city.isNotEmpty) a.city,
                        a.email,
                        a.subscriptionStatus.labelFr,
                      ].where((String s) => s.isNotEmpty).join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(
                      '${AppRoutes.adminStudios}/${a.id}',
                      extra: a,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
