// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// App Features
///
/// 역할:
/// - 이 app에서 사용할 Feature slice를 등록한다
///
/// 책임:
/// - app이 소유한 Feature composition을 Engine shell에 노출한다
///
/// 경계:
/// - 어떤 Feature가 활성화됐는지는 안다
/// - Engine 내부에서 Router policy를 구현하지는 않는다
///
/// 의존성:
/// - public Engine barrel과 app local Feature page를 참조한다
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:app_forge/engine/engine.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/posts/presentation/post_detail_page.dart';
import '../features/profile/presentation/profile_page.dart';

/// Phase 2에서 app bootstrap이 사용하는 Feature registry이다.
final appFeatures = <EngineFeature>[
  EngineFeature(
    key: 'auth',
    routes: <RouteDef>[
      RouteDef(
        path: '/login',
        name: 'login',
        label: 'Login',
        useShell: false,
        showAppBar: false,
        builder: (_, __) => const LoginPage(),
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

/// RouterEngine 입력으로 사용하는 route tree다.
final appRouteTrees = collectFeatureRouteTrees(appFeatures);

/// matcher와 navigation state가 사용하는 평탄화 route 목록이다.
final appRoutes = collectFeatureRoutes(appFeatures);

class _PostsPage extends StatelessWidget {
  const _PostsPage();

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
