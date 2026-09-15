import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/repositories/auth_repository_impl.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepositoryImpl _repository = AuthRepositoryImpl();

  UserEntity? _user;
  bool _isLoading = false;
  String? _error;

  UserEntity? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.role == 'admin';
  String? get error => _error;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.login(email, password);

    if (result.isSuccess) {
      _user = result.data;
    } else {
      _error = result.error;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> register(String name, String email, String password, {String? phone}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.register(name, email, password, phone: phone);

    if (result.isSuccess) {
      _user = result.data;
    } else {
      _error = result.error;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    final tokenResult = await _repository.getToken();
    if (tokenResult.isSuccess) {
      final result = await _repository.getCurrentUser();
      if (result.isSuccess) {
        _user = result.data;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
