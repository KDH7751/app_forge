import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_logger.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import 'auth_repository_firebase.dart';
import 'debug_app_logger.dart';
import 'users_document_datasource.dart';

/// auth data layer의 runtime dependency factory 모음.
FirebaseAuth createFirebaseAuth() {
  return FirebaseAuth.instance;
}

/// auth data layer의 Firestore dependency factory.
FirebaseFirestore createFirebaseFirestore() {
  return FirebaseFirestore.instance;
}

/// auth data layer의 logger factory.
AppLogger createAppLogger() {
  return const DebugAppLogger();
}

/// auth data layer의 users datasource factory.
UsersDocumentDataSource createUsersDocumentDataSource({
  required FirebaseFirestore firestore,
}) {
  return UsersDocumentDataSource(firestore: firestore);
}

/// auth data layer의 repository factory.
AuthRepository createAuthRepository({
  required FirebaseAuth firebaseAuth,
  required UsersDocumentDataSource usersDataSource,
  required AppLogger logger,
}) {
  return AuthRepositoryFirebase(
    firebaseAuth: firebaseAuth,
    usersDataSource: usersDataSource,
    logger: logger,
  );
}

/// auth data layer의 session stream adapter.
Stream<AuthSession?> watchAuthSessions(FirebaseAuth firebaseAuth) {
  return firebaseAuth.authStateChanges().map((user) {
    final email = user?.email;

    if (user == null || email == null || email.isEmpty) {
      return null;
    }

    return AuthSession(uid: user.uid, email: email);
  });
}
