import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_preferences.dart';
import 'supported_locales.dart';

/// Holds the app locale.
///
/// Defaults to **Arabic** — the primary market locale and the Arabic-first
/// design intent — rather than following the device: a non-Arabic guest can
/// switch on the first-run language screen or from Account. `null` means "follow
/// the device locale" (resolved by `MaterialApp` against `supportedLocales`) and
/// is only reached via [useDeviceLocale].
///
/// The choice is persisted through [AppPreferences], so the language picked on
/// the first-run screen (which is not shown again) survives a restart.
class LocaleController extends Notifier<Locale?> {
  static const String _deviceCode = 'system';

  @override
  Locale? build() {
    final String? code = ref.read(appPreferencesProvider).localeCode;
    if (code == _deviceCode) return null;
    for (final Locale locale in SupportedLocales.all) {
      if (locale.languageCode == code) return locale;
    }
    return SupportedLocales.arabic;
  }

  void set(Locale? locale) {
    state = locale;
    unawaited(
      ref
          .read(appPreferencesProvider)
          .setLocaleCode(locale?.languageCode ?? _deviceCode),
    );
  }

  void useDeviceLocale() => set(null);
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);
