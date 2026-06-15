class ApiError implements Exception {
  ApiError(this.code, this.message, this.status, [this.details]);

  final String code;
  final String message;
  final int status;
  final Map<String, dynamic>? details;

  @override
  String toString() => 'ApiError($code): $message';
}

bool isApiErrorBody(dynamic json) {
  return json is Map && json.containsKey('error');
}

ApiError apiErrorFromResponse(int status, dynamic json, String statusText) {
  if (isApiErrorBody(json)) {
    final err = (json as Map)['error'] as Map?;
    return ApiError(
      err?['code']?.toString() ?? 'API_ERROR',
      err?['message']?.toString() ?? statusText,
      status,
      err?['details'] is Map ? Map<String, dynamic>.from(err!['details'] as Map) : null,
    );
  }
  return ApiError('HTTP_ERROR', statusText, status);
}

T unwrapApiData<T>(dynamic json) {
  if (json is Map && json.containsKey('data')) {
    return json['data'] as T;
  }
  return json as T;
}
