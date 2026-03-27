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

import '../data/debug_app_logger.dart';
import '../data/auth_repository_firebase.dart';
import '../data/users_document_datasource.dart';
import '../domain/app_logger.dart';
import '../domain/auth_repository.dart';

/// FirebaseAuth DI provider.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Firestore DI provider.
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// logger DI provider.
final appLoggerProvider = Provider<AppLogger>((ref) {
  return const DebugAppLogger();
});

/// users datasource DI provider.
final usersDocumentDataSourceProvider = Provider<UsersDocumentDataSource>((
  ref,
) {
  final firestore = ref.watch(firebaseFirestoreProvider);

  return UsersDocumentDataSource(firestore: firestore);
});

/// auth repository DI provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final usersDataSource = ref.watch(usersDocumentDataSourceProvider);
  final logger = ref.watch(appLoggerProvider);

  return AuthRepositoryFirebase(
    firebaseAuth: firebaseAuth,
    usersDataSource: usersDataSource,
    logger: logger,
  );
});
