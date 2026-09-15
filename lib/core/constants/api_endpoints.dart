/// Single source of truth untuk path API (tanpa host).
/// Selalu dipakai via `AppConfig.join(...)`, JANGAN digabung manual
/// dengan `AppConfig.baseUrl` agar tidak double prefix `/api/v1/api/v1`.
class ApiEndpoints {
  static const String login = '/api/v1/auth/login';
  static const String register = '/api/v1/auth/register';
  static const String profile = '/api/v1/auth/profile';
  static const String changePassword = '/api/v1/auth/change-password';

  static const String detect = '/api/v1/detections/upload';
  static const String detectText = '/api/v1/detections/text';
  static const String history = '/api/v1/detections';
  static String historyDetail(int id) => '/api/v1/detections/$id';

  static const String dashboardStats = '/api/v1/dashboard/stats';
  static const String dashboardRecent = '/api/v1/dashboard/recent';
  static const String dashboardTrend = '/api/v1/dashboard/trend';

  /// Pengaturan publik (tanpa login): nama aplikasi dkk.
  static const String settingsPublic = '/api/v1/settings/public';

  static const String products = '/api/v1/products';
  static const String categories = '/api/v1/categories';
  static const String allergens = '/api/v1/allergens';
  static const String contents = '/api/v1/contents';
}
