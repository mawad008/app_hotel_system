import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/localization/locale_controller.dart';
import 'package:hotel_guest_app/core/widgets/brand_logo.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';

String _location(ProviderContainer c) =>
    c.read(appRouterProvider).routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets('first run shows the language sheet over the splash, in Arabic', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await pumpApp(tester, languageChosen: false);
    final AppLocalizations ar = await tester.l10n('ar');

    expect(_location(c), AppRoutes.language);
    expect(find.text(ar.languageScreenHeading), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text(ar.languageScreenHeading))),
      TextDirection.rtl,
    );
    // The sheet floats over the splash lock-up (v2 overlay).
    expect(find.byType(BrandMark), findsOneWidget);
    expect(find.byType(BrandWordmark), findsOneWidget);
    // Arabic is the default until the guest picks; no separate continue step.
    expect(c.read(localeControllerProvider)?.languageCode, 'ar');
    expect(find.text(ar.commonContinue), findsNothing);
  });

  testWidgets('choosing English switches the app and opens onboarding', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await pumpApp(tester, languageChosen: false);
    final AppLocalizations ar = await tester.l10n('ar');
    final AppLocalizations en = await tester.l10n('en');

    expect(find.text(ar.languageArabic), findsOneWidget);
    expect(find.text(ar.languageEnglish), findsOneWidget);

    await tester.tap(find.text(ar.languageEnglish));
    await tester.pumpAndSettle();

    expect(c.read(localeControllerProvider)?.languageCode, 'en');
    expect(_location(c), AppRoutes.welcome);
    expect(find.text(en.entryHeadline), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text(en.entryHeadline))),
      TextDirection.ltr,
    );
  });

  testWidgets('choosing Arabic confirms it and opens onboarding', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await pumpApp(tester, languageChosen: false);
    final AppLocalizations ar = await tester.l10n('ar');

    await tester.tap(find.text(ar.languageArabic));
    await tester.pumpAndSettle();

    expect(c.read(localeControllerProvider)?.languageCode, 'ar');
    expect(_location(c), AppRoutes.welcome);
    expect(find.text(ar.entryHeadline), findsOneWidget);

    // The screen is not shown again for the rest of the session.
    c.read(appRouterProvider).go(AppRoutes.language);
    await tester.pumpAndSettle();
    expect(_location(c), AppRoutes.welcome);
  });

  testWidgets('a returning session skips the language screen', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await pumpApp(tester);
    expect(_location(c), AppRoutes.welcome);
  });

  test('the language route is registered', () {
    final ProviderContainer c = ProviderContainer(overrides: authOverrides());
    addTearDown(c.dispose);
    final Iterable<String> paths = c
        .read(appRouterProvider)
        .configuration
        .routes
        .whereType<GoRoute>()
        .map((GoRoute r) => r.path);
    expect(paths, contains(AppRoutes.language));
  });
}
