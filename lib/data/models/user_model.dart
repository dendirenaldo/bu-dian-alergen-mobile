import '../../domain/entities/user_entity.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final DateTime createdAt;
  final bool emailVerified;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
    this.emailVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    // Backend dapat mengembalikan user di dalam `data.user` (login/register)
    // atau langsung sebagai objek user (profile). Normalisasi keduanya.
    final Map<String, dynamic> u;
    final nested = data['user'];
    if (nested is Map<String, dynamic>) {
      u = nested;
    } else if (nested is Map) {
      u = nested.cast<String, dynamic>();
    } else {
      u = data;
    }
    final rawCreated = u['createdAt'] as String?;
    final rawVerified = u['emailVerified'];
    final rawVerifiedAt = u['emailVerifiedAt'];
    final verified = rawVerified is bool
        ? rawVerified
        : rawVerifiedAt != null && rawVerifiedAt.toString().isNotEmpty;
    return UserModel(
      id: u['id'],
      name: u['name'] ?? '',
      email: u['email'] ?? '',
      phone: u['phone'],
      avatarUrl: u['avatarUrl'],
      role: u['role'] ?? 'user',
      createdAt: rawCreated != null ? DateTime.tryParse(rawCreated) ?? DateTime.now() : DateTime.now(),
      emailVerified: verified,
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
    emailVerified: emailVerified,
  );
}
