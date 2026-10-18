import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/widgets/primary_button.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('renders the promise headline and the single call to action', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    final AppLocalizations en = await tester.l10n();

    expect(find.text(en.entryHeadline), findsOneWidget);
    expect(find.text(en.entrySubtext), findsOneWidget);
    expect(find.text(en.entryStartAction), findsOneWidget);
  });

  testWidgets('the entry screen shows a single call to action and no chrome', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    final AppLocalizations en = await tester.l10n();

    // v2 onboarding is photo-forward: one glass card, no language toggle.
    // No uploaded logo → the app name instead, never a bundled mark.
    expect(find.text(en.brandWordmark), findsOneWidget);
    expect(find.byType(Image), findsOneWidget); // just the hero photo
    expect(find.byType(PrimaryButton), findsOneWidget);
    expect(find.text(en.languageArabic), findsNothing);
    expect(find.text(en.languageEnglish), findsNothing);
  });

  testWidgets(
    'the call to action opens discovery, not sign-in (deferred auth)',
    (WidgetTester tester) async {
      await pumpApp(tester);
      final AppLocalizations en = await tester.l10n();

      await tester.tap(find.text(en.entryStartAction));
      await tester.pumpAndSettle();

      expect(find.text(en.authPhoneHeading), findsNothing);
      expect(find.text(en.discoverExploreHotels), findsOneWidget);
      // v2 Home has no sign-in entry: guests sign in at booking confirm.
      expect(find.text(en.authPhoneTitle), findsNothing);
    },
  );

  testWidgets('the entry headline follows the active locale direction', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    final AppLocalizations en = await tester.l10n();

    expect(
      Directionality.of(tester.element(find.text(en.entryHeadline))),
      TextDirection.ltr,
    );
  });
}
