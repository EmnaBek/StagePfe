import 'package:interface_stage/core/session/user_session.dart';

import '../../domain/repositories/auth_session_repository.dart';

class UserSessionAuthRepository implements AuthSessionRepository {
  @override
  Future<void> saveAuthSession({
    required String token,
    Map<String, dynamic>? claims,
    String? structure,
    String? displayName,
  }) async {
    if (displayName != null && displayName.isNotEmpty) {
      UserSession.displayName.value = displayName;
    }

    UserSession.updateAuthSession(
      token: token,
      claims: claims,
      structure: structure,
    );
  }
}
