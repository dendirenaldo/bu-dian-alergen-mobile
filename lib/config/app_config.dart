class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://researchcomnets.ilkom.unsri.ac.id',
  );
  static const String appName = 'Allergen Detector';
  static const Duration timeout = Duration(seconds: 30);

  static const Duration detectionTimeout = Duration(seconds: 120);

  static String get normalizedBaseUrl {
    var url = baseUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    const suffix = '/api/v1';
    if (url.toLowerCase().endsWith(suffix)) {
      url = url.substring(0, url.length - suffix.length);
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static String join(String endpoint) {
    var path = endpoint.trim();
    if (path.isEmpty) return '$normalizedBaseUrl/api/v1';
    if (!path.startsWith('/')) path = '/$path';
    if (!path.startsWith('/api/v1/') && path != '/api/v1') {
      path = '/api/v1$path';
    }
    return '$normalizedBaseUrl$path';
  }

  static String? resolveImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final p = path.trim();
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    if (p.startsWith('/')) return '$normalizedBaseUrl$p';
    return '$normalizedBaseUrl/$p';
  }
}
