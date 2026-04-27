import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/users_document_datasource.dart';
import '../../data/factories/auth_runtime_factory.dart';
import '../../data/api/api_auth_client.dart';
import '../../data/api/harness/in_memory_api_auth_client.dart';
import '../../data/api/harness/in_memory_api_server.dart';
import '../../domain/auth_logger.dart';
import 'auth_setup_provider.dart';

/// FirebaseAuth DI provider.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return createFirebaseAuth();
});

/// Firestore DI provider.
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return createFirebaseFirestore();
});

/// logger DI provider.
final authLoggerProvider = Provider<AuthLogger>((ref) {
  return createAuthLogger();
});

/// users datasource DI provider.
final usersDocumentDataSourceProvider = Provider<UsersDocumentDataSource>((
  ref,
) {
  final firestore = ref.watch(firebaseFirestoreProvider);

  return createUsersDocumentDataSource(firestore: firestore);
});

/// API auth client DI provider.
///
/// The Phase 3.6 follow-up wires the API test harness client here. A future HTTP
/// client can replace this implementation behind the same ApiAuthClient
/// contract.
final apiAuthClientProvider = Provider<ApiAuthClient>((ref) {
  final setup = ref.watch(authSetupProvider);

  if (setup.config is! ApiTestHarnessAuthConfig) {
    throw StateError(
      'Auth provider `${setup.provider.name}` requires ApiTestHarnessAuthConfig.',
    );
  }

  final server = InMemoryApiServer.seeded();
  ref.onDispose(server.dispose);

  return InMemoryApiAuthClient(server: server);
});
