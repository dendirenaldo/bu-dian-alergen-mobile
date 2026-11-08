import '../../core/network/api_result.dart';

class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  /// HTTP status code from backend envelope (`statusCode`), if any.
  /// `-1` means transport-level failure (timeout / no connection).
  final int? statusCode;

  /// Stable backend error code (`code`), e.g. EMAIL_TAKEN.
  final String? code;

  /// Field-level validation errors (`errors`), keyed by field name.
  final Map<String, String> fieldErrors;

  Result.success(this.data)
      : error = null,
        isSuccess = true,
        statusCode = null,
        code = null,
        fieldErrors = const {};

  Result.failure(
    this.error, {
    this.statusCode,
    this.code,
    Map<String, String>? fieldErrors,
  })  : data = null,
        isSuccess = false,
        fieldErrors = fieldErrors ?? const {};

  /// Convenience constructor mapping a structured [ApiError].
  factory Result.failureFromApi(ApiError apiError) => Result.failure(
        apiError.message,
        statusCode: apiError.statusCode,
        code: apiError.code,
        fieldErrors: apiError.fieldErrors,
      );

  bool get isUnauthenticated => statusCode == 401;
  bool get isValidationError => statusCode == 400 || statusCode == 422;
  bool get isServerError => statusCode != null && statusCode! >= 500;
}
