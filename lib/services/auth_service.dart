import 'dart:convert';
import '../core/constants/api_endpoints.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Service legacy. Endpoint diperbaiki ke /api/v1/* via ApiEndpoints.
class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthService(this._apiService, this._storageService);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiService.post(ApiEndpoints.login, body: {
      'email': email,
      'password': password,
    });
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Login failed: ${response.body}');
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await _apiService.post(ApiEndpoints.register, body: {
      'name': name,
      'email': email,
      'password': password,
    });
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Registration failed: ${response.body}');
  }

  Future<void> logout() async {
    await _storageService.removeToken();
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiService.get(ApiEndpoints.profile);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get profile: ${response.body}');
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    // Backend hanya mengizinkan name/phone/avatarUrl — buang email jika ada.
    final body = Map<String, dynamic>.from(data)..remove('email');
    final response = await _apiService.put(ApiEndpoints.profile, body: body);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to update profile: ${response.body}');
  }
}
