import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';

class ProfileRemoteDataSource {
  final http.Client _client;

  ProfileRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<UserModel> getProfile() async {
    final response = await _client
        .get(
          Uri.parse('${AppConfig.baseUrl}${ApiEndpoints.profile}'),
          headers: await _headers(),
        )
        .timeout(AppConfig.timeout);

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to get profile');
  }

  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (email != null) body['email'] = email;

    final response = await _client
        .put(
          Uri.parse('${AppConfig.baseUrl}${ApiEndpoints.profile}'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(AppConfig.timeout);

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to update profile');
  }
}
