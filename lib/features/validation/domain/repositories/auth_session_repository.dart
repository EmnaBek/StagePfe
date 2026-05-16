abstract class AuthSessionRepository {
  Future<void> saveAuthSession({
    required String token,
    Map<String, dynamic>? claims,
    String? structure,
    String? displayName,
  });
}
