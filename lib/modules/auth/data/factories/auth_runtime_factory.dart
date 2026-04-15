import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/auth_logger.dart';
import '../../domain/session/auth_session.dart';
import '../datasources/users_document_datasource.dart';
import '../debug_auth_logger.dart';

/// auth data layer의 runtime dependency factory 모음.
FirebaseAuth createFirebaseAuth() {
  return FirebaseAuth.instance;
}

/// auth data layer의 Firestore dependency factory.
FirebaseFirestore createFirebaseFirestore() {
  return FirebaseFirestore.instance;
}

/// auth data layer의 logger factory.
AuthLogger createAuthLogger() {
  return const DebugAuthLogger();
}

/// auth data layer의 users datasource factory.
UsersDocumentDataSource createUsersDocumentDataSource({
  required FirebaseFirestore firestore,
}) {
  return UsersDocumentDataSource(firestore: firestore);
}

/// auth data layer의 session stream adapter.
Stream<Authenticated?> watchAuthSessions(FirebaseAuth firebaseAuth) {
  return firebaseAuth.authStateChanges().map((user) {
    final email = user?.email;

    if (user == null || email == null || email.isEmpty) {
      return null;
    }

    return Authenticated(uid: user.uid, email: email);
  });
}
