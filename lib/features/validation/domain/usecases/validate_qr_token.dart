import '../entities/protected_api_validation_response.dart';
import '../entities/qr_token_validation_result.dart';
import '../repositories/auth_session_repository.dart';
import '../repositories/protected_api_validator_repository.dart';
import '../services/qr_token_parser.dart';

class ValidateQrToken {
  ValidateQrToken(
    this._authSessionRepository,
    this._protectedApiValidatorRepository, {
    QrTokenParser parser = const QrTokenParser(),
  }) : _parser = parser;

  final AuthSessionRepository _authSessionRepository;
  final ProtectedApiValidatorRepository _protectedApiValidatorRepository;
  final QrTokenParser _parser;

  Future<QrTokenValidationResult> call({
    required String rawQrValue,
    String? protectedApiEndpoint,
  }) async {
    final String normalizedRawValue = rawQrValue.trim();
    final String token = _parser.extractToken(normalizedRawValue);
    if (token.isEmpty) {
      return QrTokenValidationResult(
        rawQrValue: rawQrValue,
        error: 'Aucun token exploitable trouvé dans le QR.',
      );
    }

    final Map<String, dynamic>? decodedClaims = _parser.tryDecodeJwtPayload(
      token,
    );

    await _authSessionRepository.saveAuthSession(
      token: token,
      claims: decodedClaims,
      structure: _parser.extractStructureType(decodedClaims),
      displayName: _parser.extractDisplayName(decodedClaims),
    );

    final String? jwtDecodeNote = decodedClaims == null
        ? 'Token détecté, mais payload JWT illisible (ou token non-JWT).'
        : null;

    final String endpoint = protectedApiEndpoint?.trim() ?? '';
    if (endpoint.isEmpty) {
      return QrTokenValidationResult(
        rawQrValue: rawQrValue,
        token: token,
        decodedClaims: decodedClaims,
        jwtDecodeNote: jwtDecodeNote,
        shouldOpenDashboard: true,
      );
    }

    final Uri? uri = Uri.tryParse(endpoint);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return QrTokenValidationResult(
        rawQrValue: rawQrValue,
        token: token,
        decodedClaims: decodedClaims,
        jwtDecodeNote: jwtDecodeNote,
        error: 'URL invalide. Exemple: https://api.exemple.com/path',
      );
    }

    final ProtectedApiValidationResponse response =
        await _protectedApiValidatorRepository.validateToken(
      endpoint: uri,
      token: token,
    );

    return QrTokenValidationResult(
      rawQrValue: rawQrValue,
      token: token,
      decodedClaims: decodedClaims,
      jwtDecodeNote: jwtDecodeNote,
      serverResponse: _formatProtectedApiResponse(response),
      shouldOpenDashboard: response.isSuccessful,
    );
  }

  String _formatProtectedApiResponse(ProtectedApiValidationResponse response) {
    return 'HTTP ${response.statusCode}\n\n'
        'Headers: ${response.headers}\n\n'
        '${_parser.formatBody(response.body)}';
  }
}
