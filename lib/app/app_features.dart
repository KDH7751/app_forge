// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// AppFeatures
///
/// 역할:
/// - app이 직접 여는 feature/policy 입력과 그로부터 파생되는 route 계산을 함께 둔다.
///
/// 영향:
/// - 상단 입력 구역을 바꾸면 하단 route/redirect 파생값이 함께 달라진다.
///
/// 주의:
/// - 사용자가 직접 수정할 값은 상단 입력 구역만 본다.
/// - 하단 파생 구역은 입력을 기반으로 계산되는 값이므로 구조 기준 없이 직접 바꾸지 않는다.
/// ===================================================================

import 'package:flutter/material.dart';
import '../engine/engine.dart';
import '../features/auth_flow/auth_flow.dart';
import '../modules/auth/auth.dart';
import '../features/home/ui/home_page.dart';
import '../features/posts/ui/post_detail_page.dart';
import '../features/profile/ui/profile_page.dart';

/// -------------------------------------------------------------------
/// User-Editable Feature And Policy Input
///
/// 이 구역은 앱이 실제로 여는 기능과 정책 입력만 둔다.
/// feature 노출 범위, auth activation policy, route source-of-truth 변경은 여기서 시작한다.
/// bootstrap과 root UI가 쓰는 하단 파생값은 모두 이 구역을 바탕으로 계산된다.
/// -------------------------------------------------------------------

/// app이 auth provider set 위에 덮는 최종 활성화 정책.
///
/// auth assembly는 provider set이 기본 제공하는 capability에만 이 정책을 적용한다.
/// 따라서 여기서는 capability를 새로 만들지 못하고, 필요한 경우 일부만 비활성화할 수 있다.
/// 이 값을 바꾸면 auth 관련 UI 진입 흐름과 일부 provider 조립 가능 범위가 함께 달라진다.
final authPolicy = const AuthActivationPolicy(
  disabledCapabilities: <AuthCapability>{},
);

/// shell router가 실제로 소비하는 feature 목록.
///
/// route 추가/삭제는 `appRouteTrees`, `appRoutes`, redirect 흐름에 모두 영향이 있으므로
/// 이 목록을 바꾸면 라우팅 테스트와 초기 진입 흐름을 함께 확인해야 한다.
/// 사용자가 직접 화면 구조를 바꾸려면 하단 파생값 대신 이 목록을 수정하는 것이 기준이다.
final appFeatures = <EngineFeature>[
  EngineFeature(
    key: 'auth_flow',
    routes: <RouteDef>[
      RouteDef(
        path: '/login',
        name: 'login',
        label: 'Login',
        useShell: false,
        showAppBar: false,
        builder: (_, __) => const LoginPage(),
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

/// -------------------------------------------------------------------
/// Derived Feature Wiring
///
/// 이 구역은 상단 입력을 바탕으로 계산되거나 해석되는 값만 둔다.
/// bootstrap과 root UI는 이 파생값을 직접 소비하므로,
/// 사용자는 먼저 상단 입력을 수정하고 이 구역은 계산 결과로 읽는 편이 맞다.
/// 이 값을 직접 손보면 feature 입력과 실제 runtime 해석이 어긋날 수 있다.
/// -------------------------------------------------------------------

/// shell router가 tree 형태 그대로 소비하는 top-level route 목록.
///
/// `RouterEngine`은 이 값을 기반으로 실제 route tree를 만든다.
/// nested route 구조를 바꾸면 현재 화면 판별용 flat 목록과 함께 의미가 바뀐다.
final appRouteTrees = collectFeatureRouteTrees(appFeatures);

/// matcher와 current route 판별에서 사용하는 flat route 목록.
///
/// shell의 현재 탭 판별과 route match helper가 이 값을 본다.
/// `appFeatures`를 수정했다면 이 값이 반영된 navigation 동작도 함께 검증해야 한다.
final appRoutes = collectFeatureRoutes(appFeatures);

/// app이 현재 잠금 기준으로 유지하는 auth redirect 정책.
///
/// bootstrap router redirect는 최종 `AuthSession`과 현재 location만 이 함수에 넘긴다.
/// 공개 auth flow route 집합이나 기본 진입 규칙을 바꾸면 app 전역 접근 흐름이 흔들린다.
/// 이번 구조에서는 redirect canonical policy 자체를 다시 설계하지 않고,
/// 상단 feature 입력을 해석하는 app-level 결정 함수로만 유지한다.
String? resolveAppRedirect({
  required AuthSession authSession,
  required String location,
}) {
  if (authSession is Pending) {
    return null;
  }

  final normalizedLocation = normalizeLocationPath(location);
  const publicAuthFlowRoutes = <String>{'/login', '/signup', '/reset-password'};
  final isPublicAuthFlowRoute = publicAuthFlowRoutes.contains(
    normalizedLocation,
  );

  if (authSession is Unauthenticated && !isPublicAuthFlowRoute) {
    return '/login';
  }

  if (authSession is Invalid && !isPublicAuthFlowRoute) {
    return '/login';
  }

  if (authSession is Authenticated && isPublicAuthFlowRoute) {
    return '/home';
  }

  return null;
}

/// nested posts route 연결을 확인하기 위한 placeholder 페이지.
///
/// `appFeatures`가 여는 posts tree의 기본 builder이므로,
/// route 구조 검증용 placeholder를 바꾸면 widget test 기대치도 함께 달라진다.
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
