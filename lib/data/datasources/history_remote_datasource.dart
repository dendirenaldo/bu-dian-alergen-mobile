import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/auth_token.dart';
import '../models/detection_model.dart';
import '../models/paginated_response_model.dart';

class HistoryRemoteDataSource {
  final http.Client _client;

  HistoryRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final token = await getValidToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
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
    // PENTING: backend GET /api/v1/detections HANYA menerima page & limit.
    // Mengirim search/sortBy/sortOrder memicu 400 forbidNonWhitelisted.
    // Search/sort dilakukan client-side di HistoryProvider.
    final safePage = page < 1 ? 1 : page;
    final safeLimit = limit < 1 ? 10 : (limit > 100 ? 100 : limit);
    final queryParams = {
      'page': safePage.toString(),
      'limit': safeLimit.toString(),
    };

    final uri = Uri.parse(AppConfig.join(ApiEndpoints.history))
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
        page: (json['page'] ?? meta['page'] ?? safePage) as int,
        limit: (json['limit'] ?? meta['limit'] ?? safeLimit) as int,
        total: (json['total'] ?? meta['total'] ?? rawList.length) as int,
        totalPages: (json['totalPages'] ?? meta['totalPages'] ?? 1) as int,
      );
    }
    String msg = 'Gagal memuat riwayat';
    try {
      final b = jsonDecode(response.body);
      if (b is Map && b['message'] != null) msg = '${b['message']} (HTTP ${response.statusCode})';
    } catch (_) {
      msg = 'Gagal memuat riwayat (HTTP ${response.statusCode} @ $uri)';
    }
    throw Exception(msg);
  }
}
