import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'config/dependency_injection.dart';
import 'core/link/app_link_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(
    MultiProvider(
      providers: getProviders,
      child: const MyApp(),
    ),
  );
  // Deep link verifikasi email / reset password (cold start + foreground).
  // Best-effort: jangan blokir startup bila plugin gagal.
  AppLinkService.instance.init();
}