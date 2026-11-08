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
  String? _pendingEmail;
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
  bool get isEmailNotVerified => _errorCode == 'EMAIL_NOT_VERIFIED';
  String? get successMessage => _successMessage;
  String? get pendingEmail => _pendingEmail;

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
      // Login sukses berarti email sudah terverifikasi (backend 403 bila
      // belum). Bersihkan penanda pending untuk email yang sama.
      if (_pendingEmail != null &&
          _pendingEmail!.toLowerCase() == email.trim().toLowerCase()) {
        _pendingEmail = null;
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
      if (result.code == 'EMAIL_NOT_VERIFIED') {
        // Pertahankan email agar halaman login bisa menawarkan kirim ulang.
        if (_pendingEmail != email.trim()) {
          _pendingEmail = email.trim();
          after = true;
        }
      }
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
      final registered = result.data;
      if (registered != null && !registered.emailVerified) {
        // Wajib verifikasi: jangan anggap login. Simpan email pending agar
        // splash/halaman verifikasi tahu ke mana harus kirim ulang.
        if (_user != null) {
          _user = null;
          after = true;
        }
        if (_pendingEmail != registered.email) {
          _pendingEmail = registered.email;
          after = true;
        }
        after = _setSuccess(
              'Registrasi berhasil. Cek email untuk verifikasi.',
            ) ||
            after;
      } else {
        if (_user != registered) {
          _user = registered;
          after = true;
        }
        if (_pendingEmail != null) {
          _pendingEmail = null;
          after = true;
        }
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

  Future<Result<String>> verifyEmail(String token) async {
    var changed = _setLoading(true);
    changed = _setError(null) || changed;
    changed = _setSuccess(null) || changed;
    _notifyIfChanged(changed);

    final result = await _repository.verifyEmail(token);
    if (_disposed) return result;

    var after = false;
    if (result.isSuccess) {
      after = _setSuccess(result.data) || after;
      // Token valid → akun siap login; hapus penanda pending bila ada.
      if (_pendingEmail != null) {
        _pendingEmail = null;
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
    return result;
  }

  Future<Result<String>> resendVerification(String email) async {
    var changed = _setLoading(true);
    changed = _setError(null) || changed;
    changed = _setSuccess(null) || changed;
    _notifyIfChanged(changed);

    final result = await _repository.resendVerification(email);
    if (_disposed) return result;

    var after = false;
    if (result.isSuccess) {
      after = _setSuccess(result.data) || after;
      if (_pendingEmail != email.trim()) {
        _pendingEmail = email.trim();
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
    if (_pendingEmail != null) {
      _pendingEmail = null;
      changed = true;
    }
    changed = _setError(null) || changed;
    changed = _setSuccess(null) || changed;
    changed = _setLoading(false) || changed;
    _notifyIfChanged(changed);
  }

  void setPendingEmail(String? email) {
    final normalized = email?.trim().isEmpty ?? true ? null : email!.trim();
    if (_pendingEmail == normalized) return;
    _pendingEmail = normalized;
    if (!_disposed) notifyListeners();
  }

  void clearPendingEmail() => setPendingEmail(null);

  /// Single-notify auth check: computes the end state first, then
  /// notifies at most once. 401 is detected via [Result.statusCode],
  /// never via string matching. Akun yang belum verifikasi email juga
  /// ditolak (tidak dianggap login) agar splash tidak lolos ke main.
  Future<void> checkAuth() async {
    final wasLoading = _isLoading;
    final hadUser = _user != null;
    final hadPending = _pendingEmail;
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
      final fetched = result.data;
      // Tolak sesi yang emailnya belum terverifikasi.
      if (fetched != null && !fetched.emailVerified) {
        try {
          await _repository.clearStoredToken();
        } catch (_) {}
        _user = null;
        _isLoading = false;
        var changed = hadUser || wasLoading;
        if (_pendingEmail != fetched.email) {
          _pendingEmail = fetched.email;
          changed = true;
        }
        changed = _setError(
              'Email belum diverifikasi. Silakan verifikasi email Anda.',
              statusCode: 403,
              code: 'EMAIL_NOT_VERIFIED',
            ) ||
            changed;
        _notifyIfChanged(changed);
        return;
      }
      final userChanged = _user?.id != fetched?.id;
      _user = fetched;
      _isLoading = false;
      var changed = userChanged || wasLoading;
      changed = _setError(null) || changed;
      // Akun terverifikasi: bersihkan penanda pending yang usang.
      if (hadPending != null) {
        _pendingEmail = null;
        changed = true;
      }
      _notifyIfChanged(changed);
    } else if (result.isUnauthenticated || result.code == 'EMAIL_NOT_VERIFIED') {
      try {
        await _repository.clearStoredToken();
      } catch (_) {}
      _user = null;
      _isLoading = false;
      var changed = hadUser || wasLoading;
      changed = _setError(
            result.code == 'EMAIL_NOT_VERIFIED'
                ? 'Email belum diverifikasi. Silakan verifikasi email Anda.'
                : null,
            statusCode: result.statusCode,
            code: result.code,
            fieldErrors: result.fieldErrors,
          ) ||
          changed;
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
