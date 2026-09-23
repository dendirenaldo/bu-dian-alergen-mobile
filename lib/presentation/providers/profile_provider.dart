import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/repositories/profile_repository_impl.dart';

class UserProfile {
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;

  UserProfile({
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
  });

  factory UserProfile.fromEntity(UserEntity entity) {
    return UserProfile(
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      avatarUrl: entity.avatarUrl,
    );
  }
}

class ProfileProvider extends ChangeNotifier {
  final ProfileRepositoryImpl _repository = ProfileRepositoryImpl();

  bool _isLoading = false;
  String? _error;
  UserProfile? _user;

  bool get isLoading => _isLoading;
  String? get error => _error;
  UserProfile? get user => _user;

  String get name => _user?.name ?? 'User';
  String get email => _user?.email ?? '';
  String? get phone => _user?.phone;
  String? get avatarUrl => _user?.avatarUrl;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getProfile();
      if (result.isSuccess && result.data != null) {
        _user = UserProfile.fromEntity(result.data!);
      } else {
        _error = result.error ?? 'Gagal memuat profil';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.updateProfile(
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      if (result.isSuccess && result.data != null) {
        _user = UserProfile.fromEntity(result.data!);
        return true;
      } else {
        _error = result.error ?? 'Gagal memperbarui profil';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
