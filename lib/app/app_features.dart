// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// App Features
///
/// 역할:
/// - 이 app이 활성화할 Feature와 route tree를 조립한다.
///
/// 경계:
/// - route 정책 조합은 app이 소유한다.
/// - Router 구현은 Engine에 맡긴다.
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:app_forge/engine/engine.dart';
import 'package:app_forge/features/auth_entry/presentation/auth_entry_notice.dart';
import 'package:app_forge/features/auth_entry/presentation/pages/login_page.dart';
import 'package:app_forge/features/auth_entry/presentation/pages/reset_password_page.dart';
import 'package:app_forge/features/auth_entry/presentation/pages/signup_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/posts/presentation/post_detail_page.dart';
import '../features/profile/presentation/profile_page.dart';

/// app redirect 판단용 최소 auth 상태.
enum AppAuthRedirectStatus { unknown, authenticated, unauthenticated }

/// app 활성 Feature 등록 목록.
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

/// Router tree 구성용 top-level route 목록.
final appRouteTrees = collectFeatureRouteTrees(appFeatures);

/// route matching / navigation sync용 flat route 목록.
final appRoutes = collectFeatureRoutes(appFeatures);

/// app layer가 소유하는 redirect 정책.
String? resolveAppRedirect({
  required AppAuthRedirectStatus authStatus,
  required String location,
}) {
  if (authStatus == AppAuthRedirectStatus.unknown) {
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

  if (authStatus == AppAuthRedirectStatus.unauthenticated &&
      !isPublicAuthEntryRoute) {
    return '/login';
  }

  if (authStatus == AppAuthRedirectStatus.authenticated &&
      isPublicAuthEntryRoute) {
    return '/home';
  }

  return null;
}

/// nested posts route placeholder 페이지.
class _PostsPage extends StatelessWidget {
  const _PostsPage();

  /// posts placeholder 본문 렌더링.
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
