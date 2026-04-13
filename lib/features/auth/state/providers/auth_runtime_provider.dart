import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/users_document_datasource.dart';
import '../../data/factories/auth_runtime_factory.dart';
import '../../domain/core/auth_logger.dart';

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
