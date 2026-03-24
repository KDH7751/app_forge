// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Post Detail Page
///
/// 역할:
/// - param route 검증용 detail page를 제공한다
///
/// 책임:
/// - path param이 UI에 전달되는지 확인할 수 있게 한다
///
/// 경계:
/// - posts 비즈니스 로직은 구현하지 않는다
/// - bottom nav나 drawer 노출 정책은 route metadata가 결정한다
///
/// 의존성:
/// - Flutter presentation type만 참조한다
/// ===================================================================

import 'package:flutter/material.dart';

class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Post Detail',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Resolved path param id: $postId',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
