import '../entities/user_entity.dart';
import 'result.dart';

abstract class ProfileRepository {
  Future<Result<UserEntity>> getProfile();
  Future<Result<UserEntity>> updateProfile({
    String? name,
    String? phone,
    String? email,
  });
}
