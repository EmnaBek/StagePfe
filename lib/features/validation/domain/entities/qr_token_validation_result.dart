class QrTokenValidationResult {
  const QrTokenValidationResult({
    required this.rawQrValue,
    this.token,
    this.decodedClaims,
    this.jwtDecodeNote,
    this.serverResponse,
    this.error,
    this.shouldOpenDashboard = false,
  });

  final String rawQrValue;
  final String? token;
  final Map<String, dynamic>? decodedClaims;
  final String? jwtDecodeNote;
  final String? serverResponse;
  final String? error;
  final bool shouldOpenDashboard;

  bool get hasError => error != null && error!.isNotEmpty;
}
