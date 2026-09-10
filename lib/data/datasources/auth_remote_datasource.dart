import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final http.Client _client;

  AuthRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<AuthResponseModel> login(String email, String password) async {
    final response = await _client
        .post(
          Uri.parse('${AppConfig.baseUrl}${ApiEndpoints.login}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(AppConfig.timeout);

    if (response.statusCode == 200) {
      return AuthResponseModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
  }

  Future<AuthResponseModel> register(String name, String email, String password) async {
    final response = await _client
        .post(
          Uri.parse('${AppConfig.baseUrl}${ApiEndpoints.register}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'name': name, 'email': email, 'password': password}),
        )
        .timeout(AppConfig.timeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return AuthResponseModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Registration failed');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _client
        .get(
          Uri.parse('${AppConfig.baseUrl}${ApiEndpoints.profile}'),
          headers: await _headers(),
        )
        .timeout(AppConfig.timeout);

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to get user');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> getStoredToken() async {
    return _getToken();
  }
}
