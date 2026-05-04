import 'package:flutter/foundation.dart';

class UserSession {
  UserSession._();

  static final ValueNotifier<String?> displayName = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> authToken = ValueNotifier<String?>(null);
  static final ValueNotifier<Map<String, dynamic>?> decodedClaims =
      ValueNotifier<Map<String, dynamic>?>(null);
  static final ValueNotifier<String?> structureType =
      ValueNotifier<String?>(null);

  static void updateAuthSession({
    required String token,
    Map<String, dynamic>? claims,
    String? structure,
  }) {
    authToken.value = token;
    decodedClaims.value = claims;
    structureType.value = structure;
  }
}
