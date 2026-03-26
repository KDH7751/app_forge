import 'package:flutter/material.dart';

/// path param 전달 확인용 detail 페이지.
class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  /// 전달된 path param 기반 detail 본문 렌더링.
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
