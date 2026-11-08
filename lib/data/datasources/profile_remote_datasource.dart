import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/utils/auth_token.dart';
import '../models/user_model.dart';

class ProfileRemoteDataSource {
  final http.Client _client;

  ProfileRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    String? token;
    try {
      token = await getValidToken();
    } catch (_) {
      token = null;
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _client
          .get(
            Uri.parse(AppConfig.join(ApiEndpoints.profile)),
            headers: await _headers(),
          )
          .timeout(AppConfig.timeout);

      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      }
      throw ApiException(parseApiError(response, 'Gagal memuat profil'));
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiException(transportError(e, fallback: 'Gagal memuat profil'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(transportError(e, fallback: 'Gagal memuat profil'));
    }
  }

  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

    try {
      final response = await _client
          .put(
            Uri.parse(AppConfig.join(ApiEndpoints.profile)),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(AppConfig.timeout);

      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      }
      throw ApiException(parseApiError(response, 'Gagal memperbarui profil'));
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiException(transportError(e, fallback: 'Gagal memperbarui profil'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(transportError(e, fallback: 'Gagal memperbarui profil'));
    }
  }
}
