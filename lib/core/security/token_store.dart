/// Storage for the guest's API access token (Laravel Sanctum bearer token).
///
/// The app uses `SecureTokenStore` (Keychain / Keystore, installed in
/// `bootstrap()`); tests use `InMemoryTokenStore`. Tokens are never written to
/// source or logs
/// (mobile/docs/architecture.md §8, mobile/docs/coding_rules.md §10).
abstract interface class TokenStore {
  Future<String?> readAccessToken();

  Future<void> writeAccessToken(String token);

  Future<void> clear();
}
