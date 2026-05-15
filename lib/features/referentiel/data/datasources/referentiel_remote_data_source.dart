import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/referentiel_model.dart';

class ReferentielRemoteDataSource {
  ReferentielRemoteDataSource({http.Client? client})
      : _client = client ?? http.Client();

  static final Uri _syncUri =
      Uri.parse('https://archtpa.bridges-corp.cloud/api/sync-mobile');

  final http.Client _client;

  Future<List<ReferentielModel>> fetchItems({
    required String token,
    required String model,
  }) async {
    final http.Response response = await _client.post(
      _syncUri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'token': token,
        'model': model,
        'lastSync': '1970-01-01 00:00:00',
        'serial': '999',
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> rawResults = decoded is Map<String, dynamic>
        ? (decoded['results'] as List<dynamic>? ?? <dynamic>[])
        : <dynamic>[];

    return rawResults
        .whereType<Map<String, dynamic>>()
        .map(ReferentielModel.fromJson)
        .toList();
  }
}
