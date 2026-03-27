// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Main Runtime Entry
///
/// 역할:
/// - plugin 실행과 runtime host 시작 담당.
///
/// 경계:
/// - app 설정 source of truth를 만들지 않음.
/// - Router policy나 Feature 비즈니스 로직은 구현하지 않음.
/// ===================================================================

import 'package:flutter/material.dart';
import 'app/app_plugins.dart';
import 'bootstrap/bootstrap.dart';

/// runtime 시작 진입점.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAppPlugins();

  runApp(const Bootstrap());
}
