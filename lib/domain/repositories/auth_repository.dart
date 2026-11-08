import '../entities/user_entity.dart';
import 'result.dart';

abstract class AuthRepository {
  Future<Result<UserEntity>> login(String email, String password);
  Future<Result<UserEntity>> register(String name, String email, String password, {String? phone});
  Future<Result<void>> logout();
  Future<Result<UserEntity>> getCurrentUser();
  Future<Result<String>> getToken();
  Future<Result<String>> forgotPassword(String email);
  Future<Result<String>> resetPassword({
    required String token,
    required String newPassword,
  });
  Future<Result<String>> verifyEmail(String token);
  Future<Result<String>> resendVerification(String email);
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> clearStoredToken();
}
