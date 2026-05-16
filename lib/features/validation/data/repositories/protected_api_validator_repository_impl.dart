import '../../domain/entities/protected_api_validation_response.dart';
import '../../domain/repositories/protected_api_validator_repository.dart';
import '../datasources/protected_api_remote_data_source.dart';

class ProtectedApiValidatorRepositoryImpl
    implements ProtectedApiValidatorRepository {
  ProtectedApiValidatorRepositoryImpl(this._remoteDataSource);

  final ProtectedApiRemoteDataSource _remoteDataSource;

  @override
  Future<ProtectedApiValidationResponse> validateToken({
    required Uri endpoint,
    required String token,
  }) {
    return _remoteDataSource.validateToken(endpoint: endpoint, token: token);
  }
}
