import '../../core/network/api_result.dart';
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
      // Backend menolak login bila email belum terverifikasi (403
      // EMAIL_NOT_VERIFIED) sehingga token umumnya selalu ada di sini.
      // Simpan hanya bila token benar-benar dikembalikan.
      if (response.token != null && response.token!.isNotEmpty) {
        await _dataSource.saveToken(response.token!);
      }
      return Result.success(response.user.toEntity());
    } on ApiException catch (e) {
      return Result.failureFromApi(e.error);
    } catch (e) {
      return Result.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<Result<UserEntity>> register(String name, String email, String password, {String? phone}) async {
    try {
      final response = await _dataSource.register(name, email, password, phone: phone);
      // Register tidak mengembalikan token saat verifikasi email wajib:
      // jangan menyimpan sesi apa pun agar splash tidak menganggap login.
      if (response.token != null && response.token!.isNotEmpty) {
        await _dataSource.saveToken(response.token!);
      }
      return Result.success(response.user.toEntity());
    } on ApiException catch (e) {
      return Result.failureFromApi(e.error);
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
    } on ApiException catch (e) {
      return Result.failureFromApi(e.error);
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
      return Result.failure('No token found', statusCode: 401);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<String>> forgotPassword(String email) async {
    try {
      final message = await _dataSource.forgotPassword(email);
      return Result.success(message);
    } on ApiException catch (e) {
      return Result.failureFromApi(e.error);
    } catch (e) {
      return Result.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<Result<String>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final message = await _dataSource.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      return Result.success(message);
    } on ApiException catch (e) {
      return Result.failureFromApi(e.error);
    } catch (e) {
      return Result.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return Result.success(null);
    } on ApiException catch (e) {
      return Result.failureFromApi(e.error);
    } catch (e) {
      return Result.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<Result<String>> verifyEmail(String token) async {
    try {
      final message = await _dataSource.verifyEmail(token);
      return Result.success(message);
    } on ApiException catch (e) {
      return Result.failureFromApi(e.error);
    } catch (e) {
      return Result.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<Result<String>> resendVerification(String email) async {
    try {
      final message = await _dataSource.resendVerification(email);
      return Result.success(message);
    } on ApiException catch (e) {
      return Result.failureFromApi(e.error);
    } catch (e) {
      return Result.failure(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Future<void> clearStoredToken() => _dataSource.clearToken();
}
