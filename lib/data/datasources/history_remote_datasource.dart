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
      final json = responseJson['data'] as Map<String, dynamic>? ?? responseJson;
      return PaginatedResponseModel<DetectionModel>(
        data: (json['data'] as List)
            .map((e) => DetectionModel.fromJson(e))
            .toList(),
        page: json['page'],
        limit: json['limit'],
        total: json['total'],
        totalPages: json['totalPages'],
      );
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to load history');
  }
}
