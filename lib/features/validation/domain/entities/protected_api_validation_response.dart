class ProtectedApiValidationResponse {
  const ProtectedApiValidationResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  final int statusCode;
  final Map<String, String> headers;
  final String body;

  bool get isSuccessful => statusCode >= 200 && statusCode < 300;
}
