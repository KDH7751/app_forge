// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Users Document DataSource
///
/// 역할:
/// - users/{uid} 문서의 upsert / delete 와 원시 서버 상태 관찰을 담당한다.
///
/// 경계:
/// - 문서 존재 여부와 blocked/disabled 같은 raw fact만 제공한다.
/// - invalid session 같은 정책 해석은 provider/session 계층이 소유한다.
/// - UI나 controller에서 직접 호출하지 않음.
/// ===================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// users/{uid} 문서에서 읽어낸 원시 서버 상태.
class UserDocumentServerState {
  const UserDocumentServerState({
    required this.exists,
    required this.isBlocked,
    required this.isDisabled,
  });

  final bool exists;
  final bool isBlocked;
  final bool isDisabled;
}

/// users 컬렉션 Firestore 접근기.
class UsersDocumentDataSource {
  UsersDocumentDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  /// users/{uid} 문서 upsert.
  Future<void> upsertUser({required String uid, required String email}) async {
    final document = _requireFirestore().collection('users').doc(uid);
    final snapshot = await document.get();
    final serverTimestamp = FieldValue.serverTimestamp();

    if (!snapshot.exists) {
      await document.set(<String, Object?>{
        'uid': uid,
        'email': email,
        'createdAt': serverTimestamp,
        'updatedAt': serverTimestamp,
      });
      return;
    }

    await document.update(<String, Object?>{
      'email': email,
      'updatedAt': serverTimestamp,
    });
  }

  /// users/{uid} 문서 삭제.
  Future<void> deleteUser({required String uid}) {
    return _requireFirestore().collection('users').doc(uid).delete();
  }

  /// users/{uid} 문서의 원시 서버 상태를 관찰한다.
  Stream<UserDocumentServerState> watchUserServerState({required String uid}) {
    return _requireFirestore().collection('users').doc(uid).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();

      return UserDocumentServerState(
        exists: snapshot.exists,
        isBlocked: _readBool(data, 'blocked'),
        isDisabled: _readBool(data, 'disabled'),
      );
    });
  }

  bool _readBool(Map<String, dynamic>? data, String key) {
    final value = data?[key];

    return value is bool && value;
  }

  FirebaseFirestore _requireFirestore() {
    final firestore = _firestore;

    if (firestore == null) {
      throw StateError('FirebaseFirestore is required for this operation.');
    }

    return firestore;
  }
}
