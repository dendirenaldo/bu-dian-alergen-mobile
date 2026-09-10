import 'user_model.dart';

class AuthResponseModel {
  final String token;
  final UserModel user;

  AuthResponseModel({
    required this.token,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return AuthResponseModel(
      token: data['token'],
      user: UserModel.fromJson(data['user']),
    );
  }
}
