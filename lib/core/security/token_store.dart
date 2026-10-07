/// Storage for the guest's API access token (Laravel Sanctum bearer token).
///
/// The app uses `SecureTokenStore` (Keychain / Keystore, installed in
/// `bootstrap()`); tests use `InMemoryTokenStore`. Tokens are never written to
/// source or logs
/// (mobile/docs/architecture.md §8, mobile/docs/coding_rules.md §10).
abstract interface class TokenStore {
  Future<String?> readAccessToken();

  Future<void> writeAccessToken(String token);

  /// The guest profile last confirmed by the backend, as an opaque JSON
  /// string saved next to the token. It lets a cold start restore the session
  /// when the backend cannot be reached (offline, timeout) instead of showing
  /// a signed-in guest the sign-in screen.
  Future<String?> readProfileSnapshot();

  Future<void> writeProfileSnapshot(String snapshot);

  /// Removes the token and the profile snapshot.
  Future<void> clear();
}
