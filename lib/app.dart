import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'core/network/app_navigator.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/app_settings_provider.dart';
import 'presentation/pages/detection/detection_result_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<ThemeProvider, ThemeMode>(
      selector: (_, theme) => theme.themeMode,
      builder: (context, themeMode, _) {
        return Selector<AppSettingsProvider, String>(
          selector: (_, settings) => settings.appName,
          builder: (context, appName, _) {
            return MaterialApp(
              title: appName,
              debugShowCheckedModeBanner: false,
              navigatorKey: appNavigatorKey,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              initialRoute: AppRoutes.splash,
              routes: AppRoutes.routes,
              onGenerateRoute: (settings) {
                if (settings.name == AppRoutes.detectionResult) {
                  return MaterialPageRoute(
                    builder: (_) => const DetectionResultPage(),
                    settings: settings,
                  );
                }
                return null;
              },
            );
          },
        );
      },
    );
  }
}
