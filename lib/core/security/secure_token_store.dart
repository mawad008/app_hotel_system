import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_store.dart';

/// Platform-backed [TokenStore]: the token survives the app being closed, so
/// a cold start restores the session (`AuthRepository.restoreSession`) instead
/// of sending the guest back to sign-in. Keychain on iOS/macOS, Keystore-
/// encrypted storage on Android, WebCrypto-encrypted storage on web.
///
/// Installed in `bootstrap()`; tests keep [InMemoryTokenStore] because the
/// platform channel does not exist there.
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              // Readable after the first unlock so a background refresh can
              // still authenticate; never synced to other devices.
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
              mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
            );

  static const String _key = 'guest_access_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() async {
    try {
      final String? token = await _storage.read(key: _key);
      return (token == null || token.isEmpty) ? null : token;
    } catch (_) {
      // Unreadable entry (e.g. Android keystore reset after a backup restore):
      // treat as signed out and drop it so the next sign-in can write cleanly.
      await clear();
      return null;
    }
  }

  @override
  Future<void> writeAccessToken(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Nothing more to do — a failed delete must not block signing out.
    }
  }
}
