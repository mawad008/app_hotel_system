import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/l10n.dart';
import '../core/localization/locale_controller.dart';
import '../core/localization/supported_locales.dart';
import '../core/theme/app_theme.dart';
import 'router/app_router.dart';
import '../core/localization/numerals.dart';
import '../core/platform/web_app_icon.dart';
import '../features/app_content/domain/entities/app_content.dart';
import '../features/app_content/presentation/state/app_content_providers.dart';

/// Root application widget. Wires the (light-only) theme, localization (with
/// RTL/LTR) and routing from their providers so a locale change rebuilds the
/// whole app.
///
/// The app name (task switcher / browser tab), brand colour and web icon are
/// dashboard-managed ([brandingProvider]) — the cached copy from the first
/// frame, the fresh one once loaded, the bundled defaults if never fetched.
class HotelGuestApp extends ConsumerWidget {
  const HotelGuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Locale? localeOverride = ref.watch(localeControllerProvider);
    final AppContent branding = ref.watch(brandingProvider);
    if (branding.appIconUrl case final String icon) applyWebAppIcon(icon);

    return MaterialApp.router(
      onGenerateTitle: (BuildContext context) =>
          branding.appName.resolve(Localizations.localeOf(context)) ??
          context.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightBranded(branding.primaryColor),
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
      // Side notches / rounded corners in landscape: one horizontal safe
      // area around the whole navigator covers every screen, sheet and
      // dialog. Top and bottom are left to each screen (full-bleed heroes,
      // app bars and bottom bars handle those insets themselves).
      builder: (BuildContext context, Widget? child) => ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          top: false,
          bottom: false,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
