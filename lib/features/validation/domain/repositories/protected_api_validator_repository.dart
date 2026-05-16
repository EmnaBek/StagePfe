import '../entities/protected_api_validation_response.dart';

abstract class ProtectedApiValidatorRepository {
  Future<ProtectedApiValidationResponse> validateToken({
    required Uri endpoint,
    required String token,
  });
}
