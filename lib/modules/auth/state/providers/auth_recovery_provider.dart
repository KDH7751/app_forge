import 'package:flutter_riverpod/flutter_riverpod.dart';

/// login/signup 중 users 문서 복구를 기다리는 in-flight action 수.
///
/// auth module 내부에서만 쓰는 lifecycle 조정 값이며,
/// consumer feature의 공개 계약으로 노출하지 않는다.
final authRecoveryCountProvider = StateProvider<int>((ref) {
  return 0;
});
