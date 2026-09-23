import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/result.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl({AuthRemoteDataSource? dataSource})
      : _dataSource = dataSource ?? AuthRemoteDataSource();

  @override
  Future<Result<UserEntity>> login(String email, String password) async {
    try {
      final response = await _dataSource.login(email, password);
      await _dataSource.saveToken(response.token);
      return Result.success(response.user.toEntity());
    } catch (e) {
      return Result.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<Result<UserEntity>> register(String name, String email, String password, {String? phone}) async {
    try {
      final response = await _dataSource.register(name, email, password, phone: phone);
      await _dataSource.saveToken(response.token);
      return Result.success(response.user.toEntity());
    } catch (e) {
      return Result.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _dataSource.logout();
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<UserEntity>> getCurrentUser() async {
    try {
      final user = await _dataSource.getCurrentUser();
      return Result.success(user.toEntity());
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<String>> getToken() async {
    try {
      final token = await _dataSource.getStoredToken();
      if (token != null) {
        return Result.success(token);
      }
      return Result.failure('No token found');
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<void> clearStoredToken() => _dataSource.clearToken();
}
