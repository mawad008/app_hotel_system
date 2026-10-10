import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small, non-secret settings that must survive the app being closed: whether
/// the guest finished first-run onboarding and which app language they chose.
///
/// Reads are synchronous — the values are loaded once in `bootstrap()` before
/// the first frame — so the router can decide the start screen without a
/// flash of onboarding. Writes are fire-and-forget persistence of state the
/// controllers already hold in memory.
///
/// Secrets (the access token) never go here — see `TokenStore`.
abstract interface class AppPreferences {
  bool get onboardingCompleted;

  Future<void> setOnboardingCompleted();

  /// The chosen app language code (`ar` / `en`), `system` for "follow the
  /// device", or `null` when the guest has never chosen.
  String? get localeCode;

  Future<void> setLocaleCode(String code);

  /// An identity photo the system camera was taking when the app was last
  /// sent to the background (serialized `PendingIdentityCapture`), so a guest
  /// whose app Android killed meanwhile is brought back to that step on the
  /// next launch. `null` when none.
  String? get pendingIdentityCapture;

  Future<void> setPendingIdentityCapture(String? value);
}

/// Default (tests, and the fallback if platform storage is unavailable):
/// nothing persists past the process.
class InMemoryAppPreferences implements AppPreferences {
  InMemoryAppPreferences({
    this.onboardingCompleted = false,
    this.localeCode,
    this.pendingIdentityCapture,
  });

  @override
  bool onboardingCompleted;

  @override
  String? localeCode;

  @override
  Future<void> setOnboardingCompleted() async => onboardingCompleted = true;

  @override
  Future<void> setLocaleCode(String code) async => localeCode = code;

  @override
  String? pendingIdentityCapture;

  @override
  Future<void> setPendingIdentityCapture(String? value) async =>
      pendingIdentityCapture = value;
}

/// Platform-backed [AppPreferences] (NSUserDefaults / SharedPreferences /
/// localStorage on web).
class SharedAppPreferences implements AppPreferences {
  SharedAppPreferences._(this._prefs);

  static const String _onboardingKey = 'onboarding_completed';
  static const String _localeKey = 'app_locale';
  static const String _pendingIdentityKey = 'pending_identity_capture';

  final SharedPreferencesWithCache _prefs;

  static Future<SharedAppPreferences> load() async {
    final SharedPreferencesWithCache prefs =
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: <String>{_onboardingKey, _localeKey, _pendingIdentityKey},
          ),
        );
    return SharedAppPreferences._(prefs);
  }

  @override
  bool get onboardingCompleted => _prefs.getBool(_onboardingKey) ?? false;

  @override
  Future<void> setOnboardingCompleted() => _prefs.setBool(_onboardingKey, true);

  @override
  String? get localeCode => _prefs.getString(_localeKey);

  @override
  Future<void> setLocaleCode(String code) => _prefs.setString(_localeKey, code);

  @override
  String? get pendingIdentityCapture => _prefs.getString(_pendingIdentityKey);

  @override
  Future<void> setPendingIdentityCapture(String? value) => value == null
      ? _prefs.remove(_pendingIdentityKey)
      : _prefs.setString(_pendingIdentityKey, value);
}

/// In-memory by default; `bootstrap()` overrides it with the loaded
/// [SharedAppPreferences].
final appPreferencesProvider = Provider<AppPreferences>(
  (Ref ref) => InMemoryAppPreferences(),
);
