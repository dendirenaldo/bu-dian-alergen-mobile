import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/result.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _dataSource;

  ProfileRepositoryImpl({ProfileRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? ProfileRemoteDataSource();

  @override
  Future<Result<UserEntity>> getProfile() async {
    try {
      final user = await _dataSource.getProfile();
      return Result.success(user.toEntity());
    } catch (e) {
      return Result.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<Result<UserEntity>> updateProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    try {
      final user = await _dataSource.updateProfile(
        name: name,
        phone: phone,
        email: email,
      );
      return Result.success(user.toEntity());
    } catch (e) {
      return Result.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
