import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_result.dart';

class ContentItem {
  final String title;
  final String body;

  const ContentItem({required this.title, required this.body});
}

class ContentsRemoteDataSource {
  final http.Client _client;

  ContentsRemoteDataSource({http.Client? client})
      : _client = client ?? http.Client();

  Future<ContentItem> getBySlug(String slug) async {
    final base = ApiEndpoints.contents.endsWith('/')
        ? ApiEndpoints.contents.substring(0, ApiEndpoints.contents.length - 1)
        : ApiEndpoints.contents;
    final uri = Uri.parse(AppConfig.join('$base/$slug'));
    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(AppConfig.timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final Map<String, dynamic> holder;
        if (decoded is Map && decoded['data'] is Map) {
          holder = (decoded['data'] as Map).cast<String, dynamic>();
        } else if (decoded is Map) {
          holder = decoded.cast<String, dynamic>();
        } else {
          holder = {};
        }
        return ContentItem(
          title: '${holder['title'] ?? slug}',
          body: '${holder['body'] ?? ''}',
        );
      }
      throw ApiException(parseApiError(response, 'Gagal memuat konten'));
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiException(transportError(e, fallback: 'Gagal memuat konten'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(transportError(e, fallback: 'Gagal memuat konten'));
    }
  }
}
