// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Auth Session Provider
///
/// 역할:
/// - repository의 auth session stream을 AuthSession 기준 provider로 노출함.
///
/// 경계:
/// - FirebaseUser를 직접 노출하지 않음.
/// - redirect 판단은 app layer가 소유함.
/// ===================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_session.dart';
import 'auth_repository_provider.dart';

/// 현재 auth session stream provider.
final authSessionProvider = StreamProvider<AuthSession?>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return repository.watchSession();
});
