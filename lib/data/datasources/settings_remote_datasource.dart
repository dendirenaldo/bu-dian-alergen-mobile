import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../core/constants/api_endpoints.dart';

/// Pengaturan publik backend (tanpa login): nama aplikasi dkk.
/// Selalu punya fallback agar UI tidak pernah kosong.
class SettingsRemoteDataSource {
  final http.Client _client;

  SettingsRemoteDataSource({http.Client? client})
      : _client = client ?? http.Client();

  /// Ambil {app_name, app_version, registration_enabled}.
  /// Throw bila gagal — pemanggil wajib fallback ke [AppConfig.appName].
  Future<Map<String, String>> getPublic() async {
    final uri = Uri.parse(AppConfig.join(ApiEndpoints.settingsPublic));
    final response = await _client
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(AppConfig.timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final holder = (body is Map && body['data'] is Map)
          ? body['data'] as Map
          : (body as Map? ?? {});
      return {
        'app_name': (holder['app_name'] ?? '').toString(),
        'app_version': (holder['app_version'] ?? '').toString(),
        'registration_enabled':
            (holder['registration_enabled'] ?? '').toString(),
      };
    }
    throw Exception('HTTP ${response.statusCode}');
  }
}
