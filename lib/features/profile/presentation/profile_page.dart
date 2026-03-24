// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Profile Page
///
/// 역할:
/// - shell 내부 profile route 검증용 페이지를 제공한다
///
/// 책임:
/// - drawer 노출 정책이 적용되는 페이지를 렌더링한다
///
/// 경계:
/// - profile 비즈니스 로직은 구현하지 않는다
/// - shell 정책은 route metadata가 결정한다
///
/// 의존성:
/// - Flutter presentation type만 참조한다
/// ===================================================================

import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Profile route inside the Engine shell with drawer enabled.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
