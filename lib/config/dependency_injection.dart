import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../presentation/providers/theme_provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/providers/detection_provider.dart';
import '../presentation/providers/history_provider.dart';
import '../presentation/providers/profile_provider.dart';
import '../presentation/providers/bottom_nav_provider.dart';

List<SingleChildWidget> get getProviders {
  return [
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => DetectionProvider()),
    ChangeNotifierProvider(create: (_) => HistoryProvider()),
    ChangeNotifierProvider(create: (_) => ProfileProvider()),
    ChangeNotifierProvider(create: (_) => BottomNavProvider()),
  ];
}

void setupDependencies() {
  // Initialize any singleton services here
  // Example: GetIt instance, HTTP client, etc.
}