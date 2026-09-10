import 'dart:convert';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthService(this._apiService, this._storageService);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiService.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Login failed: ${response.body}');
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await _apiService.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
    });
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Registration failed: ${response.body}');
  }

  Future<void> logout() async {
    await _storageService.removeToken();
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiService.get('/auth/profile');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get profile: ${response.body}');
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiService.put('/auth/profile', body: data);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to update profile: ${response.body}');
  }
}
