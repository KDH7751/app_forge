// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Home Page
///
/// 역할:
/// - home Feature의 placeholder presentation 진입점을 제공한다
///
/// 책임:
/// - Engine이 Feature 내부 구현을 몰라도 page 등록이 가능함을 보여준다
///
/// 경계:
/// - Feature presentation layer에 속한다
/// - app composition이나 Engine policy는 정의하지 않는다
///
/// 의존성:
/// - Flutter presentation type만 참조한다
/// ===================================================================

import 'package:flutter/material.dart';

/// Phase 1 home slice용 placeholder page이다.
///
/// 계약:
/// - 등록된 Feature의 최소 진입 page를 렌더링한다
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Phase 1 Home Placeholder'));
  }
}
