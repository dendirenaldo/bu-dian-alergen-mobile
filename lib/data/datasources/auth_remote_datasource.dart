import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/utils/auth_token.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final http.Client _client;

  AuthRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  Future<String?> _getToken() async {
    try {
      return await getValidToken();
    } catch (_) {
      return null;
    }
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
    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(AppConfig.timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResponseModel.fromJson(jsonDecode(response.body));
      }
      throw ApiException(parseApiError(response, 'Login gagal'));
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiException(transportError(e, fallback: 'Login gagal'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(transportError(e, fallback: 'Login gagal'));
    }
  }

  Future<AuthResponseModel> register(String name, String email, String password, {String? phone}) async {
    final uri = Uri.parse(AppConfig.join(ApiEndpoints.register));
    final body = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    };
    try {
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
      throw ApiException(parseApiError(response, 'Registrasi gagal'));
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiException(transportError(e, fallback: 'Registrasi gagal'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(transportError(e, fallback: 'Registrasi gagal'));
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');
    } catch (_) {
      // Best-effort local cleanup; never surfacing storage errors on logout.
    }
  }

  Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (_) {
      // Best-effort; token absence is the desired end-state anyway.
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
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
      throw ApiException(parseApiError(response, 'Gagal memuat user'));
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiException(transportError(e, fallback: 'Gagal memuat user'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(transportError(e, fallback: 'Gagal memuat user'));
    }
  }

  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      throw ApiException(transportError(e, fallback: 'Gagal menyimpan sesi'));
    }
  }

  Future<String?> getStoredToken() async {
    try {
      return await getValidToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final uri = Uri.parse(AppConfig.join(ApiEndpoints.changePassword));
      final response = await _client
          .post(
            uri,
            headers: await _headers(),
            body: jsonEncode({
              'currentPassword': currentPassword,
              'newPassword': newPassword,
            }),
          )
          .timeout(AppConfig.timeout);

      if (response.statusCode == 200 || response.statusCode == 201) return;
      throw ApiException(parseApiError(response, 'Gagal mengubah kata sandi'));
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiException(transportError(e, fallback: 'Gagal mengubah kata sandi'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(transportError(e, fallback: 'Gagal mengubah kata sandi'));
    }
  }

  Future<String> forgotPassword(String email) async {
    try {
      final uri = Uri.parse(AppConfig.join(ApiEndpoints.forgotPassword));
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({'email': email.trim()}),
          )
          .timeout(AppConfig.timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['message'] != null) {
            return '${body['message']}';
          }
        } catch (_) {}
        return 'Jika email terdaftar, tautan reset telah dikirim';
      }
      throw ApiException(parseApiError(response, 'Gagal meminta reset password'));
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiException(transportError(e, fallback: 'Gagal meminta reset password'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(transportError(e, fallback: 'Gagal meminta reset password'));
    }
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final uri = Uri.parse(AppConfig.join(ApiEndpoints.resetPassword));
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({'token': token.trim(), 'newPassword': newPassword}),
          )
          .timeout(AppConfig.timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['message'] != null) {
            return '${body['message']}';
          }
        } catch (_) {}
        return 'Password berhasil direset';
      }
      throw ApiException(parseApiError(response, 'Gagal mereset password'));
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw ApiException(transportError(e, fallback: 'Gagal mereset password'));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(transportError(e, fallback: 'Gagal mereset password'));
    }
  }
}
