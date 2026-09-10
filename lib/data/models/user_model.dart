import '../../domain/entities/user_entity.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return UserModel(
      id: data['id'],
      name: data['name'],
      email: data['email'],
      phone: data['phone'],
      avatarUrl: data['avatarUrl'],
      role: data['role'],
      createdAt: DateTime.parse(data['createdAt']),
    );
  }

  UserEntity toEntity() => UserEntity(
    id: id,
    name: name,
    email: email,
    phone: phone,
    avatarUrl: avatarUrl,
    role: role,
    createdAt: createdAt,
  );
}
