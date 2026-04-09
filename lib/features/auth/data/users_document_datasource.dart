// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Users Document DataSource
///
/// 역할:
/// - users/{uid} 문서의 createdAt 유지 / updatedAt 갱신 규칙 강제.
///
/// 경계:
/// - login 성공 정의는 repository가 소유함.
/// - UI나 controller에서 직접 호출하지 않음.
/// ===================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// users 컬렉션 Firestore 접근기.
class UsersDocumentDataSource {
  UsersDocumentDataSource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// users/{uid} 문서 upsert.
  Future<void> upsertUser({required String uid, required String email}) async {
    final document = _firestore.collection('users').doc(uid);
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
    return _firestore.collection('users').doc(uid).delete();
  }
}
