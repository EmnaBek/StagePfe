import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:interface_stage/app/routes.dart';
import 'package:interface_stage/features/validation/domain/services/qr_token_parser.dart';

void main() {
  test('defines the application routes', () {
    expect(AppRoutes.routes.containsKey(AppRoutes.qrTokenValidation), isTrue);
    expect(AppRoutes.routes.containsKey(AppRoutes.dashboard), isTrue);
    expect(AppRoutes.routes.containsKey(AppRoutes.caisse), isTrue);
  });

  test('uses absolute route names for Navigator compatibility', () {
    for (final String routeName in AppRoutes.routes.keys) {
      expect(
        routeName.startsWith('/'),
        isTrue,
        reason: '$routeName must start with /',
      );
    }
  });

  test('keeps QR validation page free from data/session dependencies', () {
    final String source = File(
      'lib/features/validation/presentation/pages/qr_token_validation_page.dart',
    ).readAsStringSync();

    expect(source, isNot(contains("package:http/http.dart")));
    expect(source, isNot(contains("core/session/user_session.dart")));
  });

  test('extracts token from supported QR payloads', () {
    const QrTokenParser parser = QrTokenParser();

    expect(parser.extractToken('https://example.com?token=abc123'), 'abc123');
    expect(parser.extractToken('{"token":"jwt-token"}'), 'jwt-token');
    expect(parser.extractToken(' raw-token '), 'raw-token');
  });

  test('decodes JWT claims and extracts user metadata', () {
    const QrTokenParser parser = QrTokenParser();
    final String payload = base64Url.encode(
      utf8.encode(
        jsonEncode(<String, dynamic>{
          'name': 'Emna',
          'structure_type': 'CS',
          'exp': 1893456000,
        }),
      ),
    ).replaceAll('=', '');
    final String token = 'header.$payload.signature';

    final Map<String, dynamic>? claims = parser.tryDecodeJwtPayload(token);

    expect(claims, isNotNull);
    expect(parser.extractDisplayName(claims), 'Emna');
    expect(parser.extractStructureType(claims), 'cs');
    expect(claims?['exp_readable_utc'], '2030-01-01T00:00:00.000Z');
  });
}
