import 'package:http/http.dart' as http;

import '../../domain/entities/protected_api_validation_response.dart';

class ProtectedApiRemoteDataSource {
  ProtectedApiRemoteDataSource({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<ProtectedApiValidationResponse> validateToken({
    required Uri endpoint,
    required String token,
  }) async {
    final http.Response response = await _client.get(
      endpoint,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    return ProtectedApiValidationResponse(
      statusCode: response.statusCode,
      headers: response.headers,
      body: response.body,
    );
  }
}
