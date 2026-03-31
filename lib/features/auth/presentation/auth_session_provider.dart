// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Auth Session Provider
///
/// 역할:
/// - auth presentation layer의 provider로 FirebaseAuth session stream을 AuthSession 기준으로 노출함.
///
/// 경계:
/// - auth는 UI page를 소유하지 않음.
/// - FirebaseUser를 직접 노출하지 않음.
/// - redirect 판단은 app layer가 소유함.
/// ===================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_session.dart';
import 'auth_repository_provider.dart';

/// auth session stream source provider.
final authSessionStreamProvider = Provider<Stream<AuthSession?>>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);

  return firebaseAuth.authStateChanges().map(_mapFirebaseUserToSession);
});

/// 현재 auth session stream provider.
final authSessionProvider = StreamProvider<AuthSession?>((ref) {
  return ref.watch(authSessionStreamProvider);
});

AuthSession? _mapFirebaseUserToSession(User? user) {
  final email = user?.email;

  if (user == null || email == null || email.isEmpty) {
    return null;
  }

  return AuthSession(uid: user.uid, email: email);
}
