import '../entities/user_entity.dart';
import 'result.dart';

abstract class AuthRepository {
  Future<Result<UserEntity>> login(String email, String password);
  Future<Result<UserEntity>> register(String name, String email, String password, {String? phone});
  Future<Result<void>> logout();
  Future<Result<UserEntity>> getCurrentUser();
  Future<Result<String>> getToken();
}
