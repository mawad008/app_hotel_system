import 'token_store.dart';

/// Non-persistent [TokenStore]. The token lives only for the process lifetime,
/// which is acceptable for Phase 0 (no authentication flow yet) and for tests.
class InMemoryTokenStore implements TokenStore {
  String? _token;
  String? _profileSnapshot;

  @override
  Future<String?> readAccessToken() async => _token;

  @override
  Future<void> writeAccessToken(String token) async => _token = token;

  @override
  Future<String?> readProfileSnapshot() async => _profileSnapshot;

  @override
  Future<void> writeProfileSnapshot(String snapshot) async =>
      _profileSnapshot = snapshot;

  @override
  Future<void> clear() async {
    _token = null;
    _profileSnapshot = null;
  }
}
