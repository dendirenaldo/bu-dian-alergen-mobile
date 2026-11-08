import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../../core/network/app_navigator.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/result.dart';
import '../../data/repositories/auth_repository_impl.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepositoryImpl _repository;

  AuthProvider({AuthRepositoryImpl? repository})
      : _repository = repository ?? AuthRepositoryImpl();

  UserEntity? _user;
  bool _isLoading = false;
  String? _error;
  int? _errorStatusCode;
  String? _errorCode;
  Map<String, String> _fieldErrors = const {};
  String? _successMessage;
  bool _disposed = false;

  /// Optional hook invoked after a 401 session invalidation.
  /// Defaults to redirecting to login via the global navigator key
  /// inside a post-frame callback (never notify/navigate during build).
  void Function()? onUnauthenticated;

  UserEntity? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.role == 'admin';
  String? get error => _error;
  int? get errorStatusCode => _errorStatusCode;
  String? get errorCode => _errorCode;
  Map<String, String> get fieldErrors => _fieldErrors;
  bool get isSessionExpired => _errorStatusCode == 401;
  String? get successMessage => _successMessage;

  void _notifyIfChanged(bool changed) {
    if (changed && !_disposed) notifyListeners();
  }

  bool _setLoading(bool value) {
    if (_isLoading == value) return false;
    _isLoading = value;
    return true;
  }

  bool _setError(
    String? value, {
    int? statusCode,
    String? code,
    Map<String, String>? fieldErrors,
  }) {
    var changed = false;
    if (_error != value) {
      _error = value;
      changed = true;
    }
    if (_errorStatusCode != statusCode) {
      _errorStatusCode = statusCode;
      changed = true;
    }
    if (_errorCode != code) {
      _errorCode = code;
      changed = true;
    }
    final fields = fieldErrors ?? const <String, String>{};
    if (!_mapEquals(_fieldErrors, fields)) {
      _fieldErrors = fields;
      changed = true;
    }
    return changed;
  }

  bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (b[k] != a[k]) return false;
    }
    return true;
  }

  bool _setSuccess(String? value) {
    if (_successMessage == value) return false;
    _successMessage = value;
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> login(String email, String password) async {
    var changed = _setLoading(true);
    changed = _setError(null) || changed;
    changed = _setSuccess(null) || changed;
    _notifyIfChanged(changed);

    final result = await _repository.login(email, password);
    if (_disposed) return;

    var after = false;
    if (result.isSuccess) {
      if (_user != result.data) {
        _user = result.data;
        after = true;
      }
    } else {
      after = _setError(
            result.error,
            statusCode: result.statusCode,
            code: result.code,
            fieldErrors: result.fieldErrors,
          ) ||
          after;
      if (result.isUnauthenticated) _handleUnauthenticated();
    }
    after = _setLoading(false) || after;
    _notifyIfChanged(after);
  }

  Future<void> register(String name, String email, String password, {String? phone}) async {
    var changed = _setLoading(true);
    changed = _setError(null) || changed;
    changed = _setSuccess(null) || changed;
    _notifyIfChanged(changed);

    final result = await _repository.register(name, email, password, phone: phone);
    if (_disposed) return;

    var after = false;
    if (result.isSuccess) {
      if (_user != result.data) {
        _user = result.data;
        after = true;
      }
    } else {
      after = _setError(
            result.error,
            statusCode: result.statusCode,
            code: result.code,
            fieldErrors: result.fieldErrors,
          ) ||
          after;
    }
    after = _setLoading(false) || after;
    _notifyIfChanged(after);
  }

  Future<Result<String>> forgotPassword(String email) async {
    var changed = _setLoading(true);
    changed = _setError(null) || changed;
    changed = _setSuccess(null) || changed;
    _notifyIfChanged(changed);

    final result = await _repository.forgotPassword(email);
    if (_disposed) return result;

    var after = false;
    if (result.isSuccess) {
      after = _setSuccess(result.data) || after;
    } else {
      after = _setError(
            result.error,
            statusCode: result.statusCode,
            code: result.code,
            fieldErrors: result.fieldErrors,
          ) ||
          after;
    }
    after = _setLoading(false) || after;
    _notifyIfChanged(after);
    return result;
  }

  Future<Result<String>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    var changed = _setLoading(true);
    changed = _setError(null) || changed;
    changed = _setSuccess(null) || changed;
    _notifyIfChanged(changed);

    final result = await _repository.resetPassword(
      token: token,
      newPassword: newPassword,
    );
    if (_disposed) return result;

    var after = false;
    if (result.isSuccess) {
      after = _setSuccess(result.data) || after;
    } else {
      after = _setError(
            result.error,
            statusCode: result.statusCode,
            code: result.code,
            fieldErrors: result.fieldErrors,
          ) ||
          after;
    }
    after = _setLoading(false) || after;
    _notifyIfChanged(after);
    return result;
  }

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    var changed = _setLoading(true);
    changed = _setError(null) || changed;
    changed = _setSuccess(null) || changed;
    _notifyIfChanged(changed);

    final result = await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    if (_disposed) return result;

    var after = false;
    if (result.isSuccess) {
      after = _setSuccess('Password berhasil diubah') || after;
    } else {
      after = _setError(
            result.error,
            statusCode: result.statusCode,
            code: result.code,
            fieldErrors: result.fieldErrors,
          ) ||
          after;
      if (result.isUnauthenticated) _handleUnauthenticated();
    }
    after = _setLoading(false) || after;
    _notifyIfChanged(after);
    return result;
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // Logout lokal bersifat best-effort.
    }
    if (_disposed) return;
    var changed = false;
    if (_user != null) {
      _user = null;
      changed = true;
    }
    changed = _setError(null) || changed;
    changed = _setSuccess(null) || changed;
    changed = _setLoading(false) || changed;
    _notifyIfChanged(changed);
  }

  /// Single-notify auth check: computes the end state first, then
  /// notifies at most once. 401 is detected via [Result.statusCode],
  /// never via string matching.
  Future<void> checkAuth() async {
    final wasLoading = _isLoading;
    final hadUser = _user != null;
    _isLoading = true;

    final tokenResult = await _repository.getToken();
    if (_disposed) return;
    if (!tokenResult.isSuccess) {
      _user = null;
      _isLoading = false;
      _notifyIfChanged(hadUser || wasLoading);
      return;
    }

    final result = await _repository.getCurrentUser();
    if (_disposed) return;
    if (result.isSuccess) {
      final userChanged = _user?.id != result.data?.id;
      _user = result.data;
      _isLoading = false;
      var changed = userChanged || wasLoading;
      changed = _setError(null) || changed;
      _notifyIfChanged(changed);
    } else if (result.isUnauthenticated) {
      try {
        await _repository.clearStoredToken();
      } catch (_) {}
      _user = null;
      _isLoading = false;
      var changed = hadUser || wasLoading;
      changed = _setError(null) || changed;
      _notifyIfChanged(changed);
    } else {
      // Non-401 failure (e.g. offline): single notify, keep signed out
      // without surfacing a blocking error.
      _isLoading = false;
      var changed = wasLoading;
      changed = _setError(
            result.error,
            statusCode: result.statusCode,
            code: result.code,
            fieldErrors: result.fieldErrors,
          ) ||
          changed;
      _notifyIfChanged(changed);
    }
  }

  Future<void> invalidateSession() async {
    try {
      await _repository.clearStoredToken();
    } catch (_) {
      // Best-effort.
    }
    if (_disposed) return;
    var changed = false;
    if (_user != null) {
      _user = null;
      changed = true;
    }
    changed = _setLoading(false) || changed;
    _notifyIfChanged(changed);
    _handleUnauthenticated();
  }

  void _handleUnauthenticated() {
    if (_disposed) return;
    if (onUnauthenticated != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_disposed) return;
        onUnauthenticated?.call();
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    });
  }

  void clearError() {
    _notifyIfChanged(_setError(null));
  }

  void clearSuccess() {
    _notifyIfChanged(_setSuccess(null));
  }
}
