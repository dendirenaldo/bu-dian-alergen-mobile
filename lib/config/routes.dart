import 'package:flutter/material.dart';
import '../presentation/pages/splash/splash_page.dart';
import '../presentation/pages/onboarding/onboarding_page.dart';
import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/auth/register_page.dart';
import '../presentation/pages/main/main_shell_page.dart';
import '../presentation/pages/detection/detection_page.dart';
import '../presentation/pages/detection/detection_result_page.dart';
import '../presentation/pages/history/history_page.dart';
import '../presentation/pages/history/history_detail_page.dart';
import '../presentation/pages/profile/profile_page.dart';
import '../presentation/pages/profile/edit_profile_page.dart';
import '../presentation/pages/profile/settings_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String detect = '/detect';
  static const String detectionResult = '/detection-result';
  static const String history = '/history';
  static const String historyDetail = '/history-detail';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashPage(),
        onboarding: (context) => const OnboardingPage(),
        login: (context) => const LoginPage(),
        register: (context) => const RegisterPage(),
        main: (context) => const MainShellPage(),
        detect: (context) => const DetectionPage(),
        history: (context) => const HistoryPage(),
        historyDetail: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final id = args?['id'] as int?;
          return HistoryDetailPage(detectionId: id ?? 0);
        },
        profile: (context) => const ProfilePage(),
        editProfile: (context) => const EditProfilePage(),
        settings: (context) => const SettingsPage(),
        detectionResult: (context) => const DetectionResultPage(),
      };
}