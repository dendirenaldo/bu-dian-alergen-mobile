import 'user_model.dart';

class AuthResponseModel {
  /// Null bila backend tidak mengembalikan sesi (mis. register yang
  /// mewajibkan verifikasi email terlebih dahulu).
  final String? token;
  final UserModel user;

  AuthResponseModel({
    required this.token,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    // Backend register: { user: {...}, message } tanpa token.
    // Backend login: { user: {...}, token }.
    final rawToken = data['token'];
    final userJson = data['user'] is Map ? data['user'] : data;
    return AuthResponseModel(
      token: rawToken is String && rawToken.trim().isNotEmpty ? rawToken : null,
      user: UserModel.fromJson(
        (userJson as Map).cast<String, dynamic>(),
      ),
    );
  }
}
