import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../config/providers.dart';

final Provider<bool> supabaseEnabledProvider = Provider<bool>((Ref ref) {
  return ref.watch(appConfigProvider).supabaseConfigured;
});

final Provider<SupabaseClient?> supabaseClientProvider =
    Provider<SupabaseClient?>((Ref ref) {
  if (!ref.watch(supabaseEnabledProvider)) return null;
  return Supabase.instance.client;
});

Future<void> initSupabaseIfConfigured(AppConfig config) async {
  if (!config.supabaseConfigured) return;
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabaseAnonKey,
  );
}
