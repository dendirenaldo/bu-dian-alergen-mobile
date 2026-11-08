import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_result.dart';

class SettingsRemoteDataSource {
  final http.Client _client;

  SettingsRemoteDataSource({http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, String>> getPublic() async {
    final uri = Uri.parse(AppConfig.join(ApiEndpoints.settingsPublic));
    try {
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
      throw ApiException(parseApiError(response, 'Gagal memuat pengaturan'));
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiException(transportError(e, fallback: 'Gagal memuat pengaturan'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(transportError(e, fallback: 'Gagal memuat pengaturan'));
    }
  }
}
