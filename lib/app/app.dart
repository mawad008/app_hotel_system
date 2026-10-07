import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/l10n.dart';
import '../core/localization/locale_controller.dart';
import '../core/localization/supported_locales.dart';
import '../core/theme/app_theme.dart';
import 'router/app_router.dart';
import '../core/localization/numerals.dart';

/// Root application widget. Wires the (light-only) theme, localization (with
/// RTL/LTR) and routing from their providers so a locale change rebuilds the
/// whole app.
class HotelGuestApp extends ConsumerWidget {
  const HotelGuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Locale? localeOverride = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      onGenerateTitle: (BuildContext context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Dark mode is disabled: the app always renders the light theme.
      themeMode: ThemeMode.light,
      locale: localeOverride,
      supportedLocales: SupportedLocales.all,
      localizationsDelegates: AppLocalizationsWithNumeralsDelegate.delegates,
      localeListResolutionCallback: (
        List<Locale>? deviceLocales,
        Iterable<Locale> supported,
      ) {
        return SupportedLocales.resolveLocale(
          deviceLocales?.isNotEmpty ?? false ? deviceLocales!.first : null,
          supported,
        );
      },
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
