import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/detection_model.dart';
import '../models/paginated_response_model.dart';

class HistoryRemoteDataSource {
  final http.Client _client;

  HistoryRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<PaginatedResponseModel<DetectionModel>> getHistory({
    int page = 1,
    int limit = 10,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };

    final uri = Uri.parse('${AppConfig.baseUrl}${ApiEndpoints.history}')
        .replace(queryParameters: queryParams);

    final response = await _client
        .get(uri, headers: await _headers())
        .timeout(AppConfig.timeout);

    if (response.statusCode == 200) {
      final responseJson = jsonDecode(response.body);
      // Backend: { data: [...], total, page, limit, totalPages, meta? } dibungkus interceptor {data}.
      // Tangani: body.data = List langsung, atau body.data = Map berisi data List.
      final body = responseJson is Map<String, dynamic> ? responseJson : <String, dynamic>{'data': responseJson};
      final inner = body['data'];
      final Map<String, dynamic> json = inner is Map<String, dynamic> ? inner : body;
      final rawList = (inner is List ? inner : json['data']) as List? ?? [];
      final meta = (json['meta'] as Map<String, dynamic>?) ?? {};
      return PaginatedResponseModel<DetectionModel>(
        data: rawList
            .map((e) => DetectionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: (json['page'] ?? meta['page'] ?? page) as int,
        limit: (json['limit'] ?? meta['limit'] ?? limit) as int,
        total: (json['total'] ?? meta['total'] ?? rawList.length) as int,
        totalPages: (json['totalPages'] ?? meta['totalPages'] ?? 1) as int,
      );
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to load history');
  }
}
