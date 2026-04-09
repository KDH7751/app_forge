// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// AppFeatures
///
/// 역할:
/// - app에서 활성화할 feature와 전역 흐름 입력을 정의한다.
///
/// 영향:
/// - 이 설정에 따라 app 전체 라우팅 구조, 접근 흐름, 전역 알림 방식이 달라진다.
///
/// 주의:
/// - route나 전역 정책을 바꾸면 관련 화면 접근 흐름을 함께 확인해야 한다.
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:app_forge/engine/engine.dart';
import 'package:app_forge/features/auth/domain/auth_session.dart';
import 'package:app_forge/features/auth/state/auth_error_mapper.dart';
import 'package:app_forge/features/auth_entry/state/auth_entry_notice.dart';
import 'package:app_forge/features/auth_entry/ui/login_page.dart';
import 'package:app_forge/features/auth_entry/ui/reset_password_page.dart';
import 'package:app_forge/features/auth_entry/ui/signup_page.dart';
import '../features/home/ui/home_page.dart';
import '../features/posts/ui/post_detail_page.dart';
import '../features/profile/ui/profile_page.dart';

/// 이 앱이 실제로 활성화하는 feature 목록.
///
/// 이 목록에 따라 app 전체 라우팅 구조와
/// 화면 접근 가능 범위가 결정된다.
final appFeatures = <EngineFeature>[
  EngineFeature(
    key: 'auth_entry',
    routes: <RouteDef>[
      RouteDef(
        path: '/login',
        name: 'login',
        label: 'Login',
        useShell: false,
        showAppBar: false,
        builder: (_, state) => LoginPage(
          notice: state.extra is AuthEntryNotice
              ? state.extra! as AuthEntryNotice
              : null,
        ),
      ),
      RouteDef(
        path: '/signup',
        name: 'signup',
        label: 'Sign Up',
        useShell: false,
        showAppBar: false,
        builder: (_, __) => const SignupPage(),
      ),
      RouteDef(
        path: '/reset-password',
        name: 'resetPassword',
        label: 'Reset Password',
        useShell: false,
        showAppBar: false,
        builder: (_, __) => const ResetPasswordPage(),
      ),
    ],
  ),
  EngineFeature(
    key: 'home',
    routes: <RouteDef>[
      RouteDef(
        path: '/home',
        name: 'home',
        label: 'Home',
        icon: Icons.home_outlined,
        showAppBar: true,
        showBottomNav: true,
        builder: (_, __) => const HomePage(),
      ),
    ],
  ),
  EngineFeature(
    key: 'profile',
    routes: <RouteDef>[
      RouteDef(
        path: '/profile',
        name: 'profile',
        label: 'Profile',
        icon: Icons.person_outline,
        showAppBar: true,
        showBottomNav: true,
        showDrawer: true,
        builder: (_, __) => const ProfilePage(),
      ),
    ],
  ),
  EngineFeature(
    key: 'posts',
    routes: <RouteDef>[
      RouteDef(
        path: '/posts',
        name: 'posts',
        label: 'Posts',
        showAppBar: true,
        showBottomNav: false,
        builder: (_, __) => const _PostsPage(),
        children: <RouteDef>[
          RouteDef(
            path: '/posts/:id',
            name: 'postDetail',
            label: 'Post Detail',
            showAppBar: true,
            showBottomNav: false,
            showDrawer: false,
            builder: (_, state) =>
                PostDetailPage(postId: state.pathParameters['id'] ?? 'unknown'),
          ),
        ],
      ),
    ],
  ),
];

/// feature별 top-level route tree를 모은 목록.
///
/// 이 값에 따라 app의 상위 화면 구조와
/// nested route 연결 방식이 달라진다.
final appRouteTrees = collectFeatureRouteTrees(appFeatures);

/// route matching과 current route 판별에 사용하는 flat route 목록.
///
/// 이 값을 바꾸면 app 전역의
/// 현재 화면 판별 기준도 함께 달라진다.
final appRoutes = collectFeatureRoutes(appFeatures);

/// 전역 에러 알림 문구를 만들 때 순서대로 조회하는 feature mapper 목록.
///
/// 이 목록에 따라 app 전역 알림에서
/// 어떤 메시지를 우선 사용할지가 달라진다.
final appErrorNotificationTextMappers = <String? Function(Object?)>[
  mapAuthErrorText,
];

/// 인증 상태와 현재 location을 기준으로 redirect 대상을 결정한다.
///
/// 비로그인 사용자는 auth entry route만 접근하게 하고
/// 로그인 사용자는 login / signup 같은 공개 진입 화면에 머물지 않게 만든다.
/// 공개 route 목록을 바꾸면 app 전체 인증 진입 흐름도 함께 달라진다.
String? resolveAppRedirect({
  required AuthSession authSession,
  required String location,
}) {
  if (authSession is Pending) {
    return null;
  }

  final normalizedLocation = normalizeLocationPath(location);
  const publicAuthEntryRoutes = <String>{
    '/login',
    '/signup',
    '/reset-password',
  };
  final isPublicAuthEntryRoute = publicAuthEntryRoutes.contains(
    normalizedLocation,
  );

  if (authSession is Unauthenticated && !isPublicAuthEntryRoute) {
    return '/login';
  }

  if (authSession is Invalid && !isPublicAuthEntryRoute) {
    return '/login';
  }

  if (authSession is Authenticated && isPublicAuthEntryRoute) {
    return '/home';
  }

  return null;
}

/// 전역 에러 알림용 문자열을 결정한다.
///
/// 각 feature가 제공한 mapper를 순서대로 조회해
/// 첫 번째로 매칭되는 메시지를 사용한다.
/// 이 결과에 따라 app 전역 알림 문구가 달라진다.
String? mapAppErrorNotificationText(Object? domainError) {
  for (final mapper in appErrorNotificationTextMappers) {
    final message = mapper(domainError);

    if (message != null) {
      return message;
    }
  }

  return null;
}

/// nested posts route 연결을 확인하기 위한 placeholder 페이지.
///
/// posts route 구성이 바뀔 때
/// 기본 진입 화면 역할을 하는 페이지다.
class _PostsPage extends StatelessWidget {
  const _PostsPage();

  /// posts route의 임시 본문을 렌더링한다.
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Posts route for nested detail validation.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
