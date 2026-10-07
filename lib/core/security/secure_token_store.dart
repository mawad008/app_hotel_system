import 'package:flutter/services.dart' show PlatformException;
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
  static const String _profileKey = 'guest_profile_snapshot';

  final FlutterSecureStorage _storage;

  /// The token is read from platform storage once per process and then served
  /// from memory: every API request asks for it, and a keystore round-trip per
  /// request is both slow and one more chance for a transient platform error
  /// to look like "signed out".
  Future<String?>? _token;

  @override
  Future<String?> readAccessToken() => _token ??= _load();

  Future<String?> _load() async {
    try {
      final String? token = await _storage.read(key: _key);
      return (token == null || token.isEmpty) ? null : token;
    } on PlatformException {
      // Undecryptable entry (e.g. Android keystore reset after a backup
      // restore): treat as signed out and drop it so the next sign-in can
      // write cleanly.
      await _deleteAll();
      return null;
    } catch (_) {
      // Anything else is not evidence the entry is bad — report "no token"
      // for now but keep it, and try again on the next read.
      _token = null;
      return null;
    }
  }

  @override
  Future<void> writeAccessToken(String token) async {
    _token = Future<String?>.value(token);
    await _storage.write(key: _key, value: token);
  }

  @override
  Future<String?> readProfileSnapshot() async {
    try {
      return await _storage.read(key: _profileKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeProfileSnapshot(String snapshot) async {
    try {
      await _storage.write(key: _profileKey, value: snapshot);
    } catch (_) {
      // The snapshot is only an offline convenience — never fail a sign-in
      // because it could not be saved.
    }
  }

  @override
  Future<void> clear() async {
    _token = Future<String?>.value(null);
    await _deleteAll();
  }

  Future<void> _deleteAll() async {
    for (final String key in <String>[_key, _profileKey]) {
      try {
        await _storage.delete(key: key);
      } catch (_) {
        // Nothing more to do — a failed delete must not block signing out.
      }
    }
  }
}
