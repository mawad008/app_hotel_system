import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/di/core_providers.dart';
import '../../core/security/secure_token_store.dart';
import '../../core/storage/app_preferences.dart';
import '../app.dart';

/// Single startup path for every entry point.
///
/// Responsibilities: bind the framework, build [AppConfig] from compile-time
/// defines, install top-level error handlers, and run the app inside a
/// [ProviderScope] with configuration injected.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppConfig config = AppConfig.fromEnvironment();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _report('flutter', details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _report('platform', error, stack);
    return true;
  };

  final AppPreferences preferences = await _loadPreferences();

  runApp(
    ProviderScope(
      overrides: <Override>[
        appConfigProvider.overrideWithValue(config),
        // Persist the guest's token so closing the app doesn't sign them out.
        tokenStoreProvider.overrideWithValue(SecureTokenStore()),
        // Remember onboarding + language so they are only asked once.
        appPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const HotelGuestApp(),
    ),
  );
}

/// Loaded before the first frame so the router knows whether onboarding was
/// already completed. Unavailable storage degrades to the old first-run flow
/// rather than blocking startup.
Future<AppPreferences> _loadPreferences() async {
  try {
    return await SharedAppPreferences.load();
  } catch (error, stack) {
    _report('preferences', error, stack);
    return InMemoryAppPreferences();
  }
}

/// Phase 0 crash sink: logs in debug only. A real crash-reporting integration
/// (behind an abstraction, opt-in, no PII) is a later-phase concern.
void _report(String source, Object error, StackTrace? stack) {
  if (kDebugMode) {
    developer.log('Uncaught ($source)', error: error, stackTrace: stack, name: 'app');
  }
}
