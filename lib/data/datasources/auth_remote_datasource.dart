import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Helper pesan error aman: backend kirim {message}, tapi jika URL salah
/// server balas HTML (404 nginx) sehingga jsonDecode gagal. Jangan sembunyikan URL.
String _errMsg(http.Response r, String fallback) {
  try {
    final body = jsonDecode(r.body);
    if (body is Map && body['message'] != null) {
      return '${body['message']} (HTTP ${r.statusCode})';
    }
  } catch (_) {
    final snippet = r.body.length > 120 ? '${r.body.substring(0, 120)}…' : r.body;
    return '$fallback (HTTP ${r.statusCode} @ ${r.request?.url} :: $snippet)';
  }
  return '$fallback (HTTP ${r.statusCode})';
}

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
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<AuthResponseModel> login(String email, String password) async {
    final uri = Uri.parse(AppConfig.join(ApiEndpoints.login));
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode({'email': email.trim(), 'password': password}),
        )
        .timeout(AppConfig.timeout);

    // Backend Nest POST default 201; terima 200 & 201.
    if (response.statusCode == 200 || response.statusCode == 201) {
      return AuthResponseModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(_errMsg(response, 'Login gagal'));
  }

  Future<AuthResponseModel> register(String name, String email, String password, {String? phone}) async {
    final uri = Uri.parse(AppConfig.join(ApiEndpoints.register));
    final body = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    };
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(AppConfig.timeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return AuthResponseModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(_errMsg(response, 'Registrasi gagal'));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }

  Future<UserModel> getCurrentUser() async {
    final uri = Uri.parse(AppConfig.join(ApiEndpoints.profile));
    final response = await _client
        .get(
          uri,
          headers: await _headers(),
        )
        .timeout(AppConfig.timeout);

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(_errMsg(response, 'Gagal memuat user'));
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> getStoredToken() async {
    return _getToken();
  }
}
