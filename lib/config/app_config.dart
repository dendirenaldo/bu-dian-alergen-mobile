class AppConfig {
  /// Host API tanpa path version.
  ///
  /// Contoh benar:
  ///   --dart-define=API_BASE_URL=https://researchcomnets.ilkom.unsri.ac.id
  /// Contoh yang TETAP ditoleransi (otomatis dinormalisasi):
  ///   https://researchcomnets.ilkom.unsri.ac.id/api/v1
  ///   https://researchcomnets.ilkom.unsri.ac.id/api/v1/
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://researchcomnets.ilkom.unsri.ac.id',
  );
  static const String appName = 'Allergen Detector';
  static const Duration timeout = Duration(seconds: 30);

  /// Timeout khusus deteksi (upload/teks) karena backend ML bisa 120 detik.
  static const Duration detectionTimeout = Duration(seconds: 120);

  /// Base URL yang sudah dinormalisasi: tanpa trailing slash,
  /// tanpa suffix /api/v1 (agar tidak double prefix).
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

  /// Gabung base + endpoint path secara aman.
  ///
  /// - [endpoint] boleh '/auth/login' (otomatis jadi '/api/v1/auth/login')
  ///   atau '/api/v1/auth/login' (dipakai apa adanya).
  /// - Tidak pernah menghasilkan '/api/v1/api/v1/...'.
  static String join(String endpoint) {
    var path = endpoint.trim();
    if (path.isEmpty) return '$normalizedBaseUrl/api/v1';
    if (!path.startsWith('/')) path = '/$path';
    // Collapse duplicate slashes (kecuali setelah scheme).
    if (!path.startsWith('/api/v1/') && path != '/api/v1') {
      path = '/api/v1$path';
    }
    return '$normalizedBaseUrl$path';
  }

  /// Ubah imageUrl relatif backend ('/uploads/xxx.jpg') jadi URL absolut.
  /// Jika sudah absolut (http...), dikembalikan apa adanya.
  static String? resolveImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final p = path.trim();
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    if (p.startsWith('/')) return '$normalizedBaseUrl$p';
    return '$normalizedBaseUrl/$p';
  }
}
