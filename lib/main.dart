import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'config/dependency_injection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(
    MultiProvider(
      providers: getProviders,
      child: const MyApp(),
    ),
  );
}