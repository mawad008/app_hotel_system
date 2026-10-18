import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/app.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/localization/locale_controller.dart';
import 'package:hotel_guest_app/core/localization/supported_locales.dart';
import 'package:hotel_guest_app/features/authentication/domain/entities/guest_profile.dart';

import 'auth_test_support.dart';

/// Pumps the whole app with authentication overrides and settles the startup
/// redirect. Returns the container so a test can drive controllers directly.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  AuthSession? bootSession,
  Locale? locale,
  Duration resendCooldown = Duration.zero,
  bool languageChosen = true,
  List<Override> extraOverrides = const <Override>[],
}) async {
  final ProviderContainer container = ProviderContainer(
    overrides: mergeOverrides(<Override>[
      ...authOverrides(
        bootSession: bootSession,
        resendCooldown: resendCooldown,
        languageChosen: languageChosen,
      ),
      ...extraOverrides,
    ]),
  );
  addTearDown(container.dispose);

  // Keep the default 800 logical width (horizontal layouts assume it) but give
  // tests a tall viewport: the design-system type scale uses Arabic (loose)
  // line-heights, so screens are ~15–20% taller and the stock 600px height
  // leaves sticky-footer CTAs and calendar rows clipped.
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(800, 1600);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  if (locale != null) {
    container.read(localeControllerProvider.notifier).set(locale);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const HotelGuestApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Pumps the app and navigates straight to the phone sign-in screen.
///
/// Since deferred auth landed (docs/mobile-deferred-auth.md) `/welcome` opens
/// discovery, not sign-in, so auth-screen tests jump to the auth surface
/// directly instead of tapping through the entry CTA.
Future<ProviderContainer> pumpSignIn(
  WidgetTester tester, {
  Locale? locale,
  Duration resendCooldown = Duration.zero,
  List<Override> extraOverrides = const <Override>[],
}) async {
  final ProviderContainer container = await pumpApp(
    tester,
    locale: locale,
    resendCooldown: resendCooldown,
    extraOverrides: extraOverrides,
  );
  container.read(appRouterProvider).goNamed(AppRoutes.signInName);
  await tester.pumpAndSettle();
  return container;
}

extension L10nFinder on WidgetTester {
  Future<AppLocalizations> l10n([String code = 'en']) =>
      AppLocalizations.delegate.load(Locale(code));
}

const Locale arabic = SupportedLocales.arabic;
