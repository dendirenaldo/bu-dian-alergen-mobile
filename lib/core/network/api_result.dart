import 'dart:convert';

import 'package:http/http.dart' as http;

/// Field-level validation error keyed by field name.
typedef FieldErrors = Map<String, String>;

/// Structured API error parsed from backend envelope:
/// `{ statusCode, message, code?, errors? }`.
class ApiError {
  final int statusCode;
  final String message;
  final String? code;
  final FieldErrors fieldErrors;

  const ApiError({
    required this.statusCode,
    required this.message,
    this.code,
    this.fieldErrors = const {},
  });

  bool get isUnauthenticated => statusCode == 401;
  bool get isValidation => statusCode == 400 || statusCode == 422;
  bool get isServerError => statusCode >= 500;
  bool get hasFieldErrors => fieldErrors.isNotEmpty;

  @override
  String toString() => message;
}

/// Exception thrown by datasources carrying a structured [ApiError].
class ApiException implements Exception {
  final ApiError error;
  const ApiException(this.error);

  int get statusCode => error.statusCode;

  @override
  String toString() => error.message;
}

/// Sealed result type for network operations.
sealed class ApiResult<T> {
  const ApiResult();

  bool get isSuccess => this is ApiSuccess<T>;
  bool get isFailure => this is ApiFailure<T>;

  T? get data => switch (this) {
        ApiSuccess<T>(:final value) => value,
        ApiFailure<T>() => null,
      };

  ApiError? get error => switch (this) {
        ApiSuccess<T>() => null,
        ApiFailure<T>(:final failure) => failure,
      };
}

class ApiSuccess<T> extends ApiResult<T> {
  final T value;
  const ApiSuccess(this.value);
}

class ApiFailure<T> extends ApiResult<T> {
  final ApiError failure;
  const ApiFailure(this.failure);
}

/// Parses backend error envelope `{statusCode, message, code, errors}`.
///
/// `errors` may be a List of `{field, message}` maps or a Map of
/// field -> message(s). Falls back gracefully on non-JSON bodies.
ApiError parseApiError(http.Response response, String fallback) {
  final statusCode = response.statusCode;
  String message = fallback;
  String? code;
  final fields = <String, String>{};

  try {
    final decoded = jsonDecode(response.body);
    final Map<String, dynamic>? body =
        decoded is Map ? decoded.cast<String, dynamic>() : null;
    if (body != null) {
      final rawMsg = body['message'];
      if (rawMsg is String && rawMsg.trim().isNotEmpty) {
        message = rawMsg.trim();
      } else if (rawMsg is List && rawMsg.isNotEmpty) {
        message = rawMsg.map((e) => e.toString()).join(', ');
      }
      final rawCode = body['code'];
      if (rawCode is String && rawCode.trim().isNotEmpty) {
        code = rawCode.trim();
      }
      final rawErrors = body['errors'];
      if (rawErrors is List) {
        for (final e in rawErrors) {
          if (e is Map) {
            final f = e['field']?.toString() ?? 'unknown';
            final m = e['message']?.toString() ?? e.toString();
            fields[f] = m;
          }
        }
      } else if (rawErrors is Map) {
        rawErrors.forEach((k, v) {
          final key = k.toString();
          if (v is List) {
            fields[key] = v.map((e) => e.toString()).join(', ');
          } else {
            fields[key] = v.toString();
          }
        });
      }
    }
  } catch (_) {
    final snippet = response.body.length > 120
        ? '${response.body.substring(0, 120)}…'
        : response.body;
    if (snippet.trim().isNotEmpty) {
      message = '$fallback ($snippet)';
    }
  }

  switch (statusCode) {
    case 401:
      if (message == fallback) {
        message = 'Sesi berakhir. Silakan masuk ulang.';
      }
    case 400:
    case 422:
      if (fields.isNotEmpty && message == fallback) {
        message = fields.values.first;
      }
      if (message == fallback) message = 'Data tidak valid. Periksa kembali isian.';
    case 429:
      if (message == fallback) {
        message = 'Terlalu banyak percobaan. Coba lagi nanti.';
      }
    case 503:
      if (message == fallback) {
        message = 'Layanan sedang sibuk. Coba lagi nanti.';
      }
    default:
      if (statusCode >= 500 && message == fallback) {
        message = 'Terjadi kesalahan server. Coba lagi nanti.';
      }
  }

  return ApiError(
    statusCode: statusCode,
    message: '$message (HTTP $statusCode)',
    code: code,
    fieldErrors: fields,
  );
}

/// Builds an [ApiError] for transport-level failures (timeout, no connection).
ApiError transportError(Object e, {String fallback = 'Koneksi bermasalah'}) {
  final msg = e.toString().replaceFirst('Exception: ', '');
  return ApiError(statusCode: -1, message: '$msg. Coba lagi.');
}
