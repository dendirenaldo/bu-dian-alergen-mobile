import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToNext();
    });
  }

  Future<void> _navigateToNext() async {
    final settingsFuture = context
        .read<AppSettingsProvider>()
        .load()
        .timeout(const Duration(seconds: 10), onTimeout: () {});
    final authProvider = context.read<AuthProvider>();
    final authFuture = authProvider
        .checkAuth()
        .timeout(const Duration(seconds: 10), onTimeout: () {});
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      settingsFuture,
      authFuture,
    ]);
    if (!mounted) return;

    bool onboardingComplete = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    } catch (_) {
      onboardingComplete = false;
    }

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    } else if (!onboardingComplete) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appName = context.watch<AppSettingsProvider>().appName;
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.shieldCheck,
              size: 72,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                appName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.appDescription,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}