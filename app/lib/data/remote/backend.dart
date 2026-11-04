import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';

/// Initializes Supabase when this build is configured for a backend.
/// Returns false in guest-only builds; nothing else then touches the
/// network (ADR-003).
Future<bool> initBackend() async {
  if (!BackendConfig.isConfigured) return false;
  await Supabase.initialize(url: BackendConfig.url, publishableKey: BackendConfig.publishableKey);
  return true;
}

/// Whether [initBackend] succeeded; overridden in `main()`.
final backendReadyProvider = Provider<bool>((ref) => false);

SupabaseClient? _client(Ref ref) => ref.watch(backendReadyProvider) ? Supabase.instance.client : null;

final supabaseClientProvider = Provider<SupabaseClient?>(_client);

/// The signed-in user, or null for guests and unconfigured builds.
final currentUserProvider = StreamProvider<User?>((ref) async* {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    yield null;
    return;
  }
  yield client.auth.currentUser;
  await for (final state in client.auth.onAuthStateChange) {
    yield state.session?.user;
  }
});
