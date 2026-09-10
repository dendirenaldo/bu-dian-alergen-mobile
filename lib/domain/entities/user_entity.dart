class UserEntity {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final DateTime createdAt;

  UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.createdAt,
  });
}
