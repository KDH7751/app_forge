// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Auth Repository Provider
///
/// 역할:
/// - auth repository와 Firebase/data/logger 의존성을 app 소비용으로 조립함.
///
/// 경계:
/// - FirebaseUser를 외부에 노출하지 않음.
/// - router나 redirect 로직을 직접 다루지 않음.
/// ===================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_data_factory.dart';
import '../data/users_document_datasource.dart';
import '../domain/app_logger.dart';
import '../domain/auth_repository.dart';

/// FirebaseAuth DI provider.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return createFirebaseAuth();
});

/// Firestore DI provider.
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return createFirebaseFirestore();
});

/// logger DI provider.
final appLoggerProvider = Provider<AppLogger>((ref) {
  return createAppLogger();
});

/// users datasource DI provider.
final usersDocumentDataSourceProvider = Provider<UsersDocumentDataSource>((
  ref,
) {
  final firestore = ref.watch(firebaseFirestoreProvider);

  return createUsersDocumentDataSource(firestore: firestore);
});

/// auth repository DI provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final usersDataSource = ref.watch(usersDocumentDataSourceProvider);
  final logger = ref.watch(appLoggerProvider);

  return createAuthRepository(
    firebaseAuth: firebaseAuth,
    usersDataSource: usersDataSource,
    logger: logger,
  );
});
