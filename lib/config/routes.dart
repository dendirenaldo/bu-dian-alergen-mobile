import 'package:flutter/material.dart';
import '../presentation/pages/splash/splash_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String detect = '/detect';
  static const String detectionResult = '/detection-result';
  static const String history = '/history';
  static const String historyDetail = '/history-detail';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashPage(),
      // TODO: Add other routes as pages are implemented
    };
  }
}