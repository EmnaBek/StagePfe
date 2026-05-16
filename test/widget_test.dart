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

}
