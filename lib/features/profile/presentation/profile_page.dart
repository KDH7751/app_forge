import 'package:flutter/material.dart';

/// drawer 노출 route 확인용 profile 페이지.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  /// drawer 노출 profile 본문 렌더링.
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
