class AppConfig {
  /// flutter run --dart-define=API_BASE_URL=https://api.example.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001',
  );
  static const String appName = 'Bu Dian';
  static const Duration timeout = Duration(seconds: 30);
}
