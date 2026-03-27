// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Main App Bootstrap
///
/// 역할:
/// - app Plugin 초기화와 Router composition bootstrap 담당.
///
/// 경계:
/// - app composition 세부 사항만 조립함.
/// - Router policy나 Feature 비즈니스 로직은 구현하지 않음.
/// ===================================================================

import 'package:flutter/material.dart';
import 'app/app_bootstrap.dart';
import 'app/app_plugins.dart';

/// app bootstrap 진입점.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAppPlugins();

  runApp(const AppBootstrap());
}
