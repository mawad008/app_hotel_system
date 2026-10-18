import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/app.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/theme/app_colors.dart';
import 'package:hotel_guest_app/core/widgets/brand_logo.dart';
import 'package:hotel_guest_app/features/authentication/presentation/pages/auth_splash_page.dart';
import 'package:hotel_guest_app/features/authentication/presentation/pages/language_selection_page.dart';
import 'package:hotel_guest_app/features/authentication/presentation/state/auth_controller.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';

void main() {
  testWidgets('the branded splash holds on screen, then hands off to the flow', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        ...authOverrides(languageChosen: false),
        splashMinDurationProvider.overrideWithValue(
          const Duration(milliseconds: 300),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HotelGuestApp(),
      ),
    );
    await tester.pump();

    // The splash is up while the (held) session restore is in flight: the
    // brand navy field with the app icon over the STDY HOTELS wordmark.
    expect(find.byType(AuthSplashPage), findsOneWidget);
    expect(find.byType(BrandMark), findsOneWidget);
    expect(find.byType(BrandWordmark), findsOneWidget);
    final AppLocalizations en = await tester.l10n();
    expect(find.bySemanticsLabel(en.appName), findsOneWidget);
    final Scaffold scaffold = tester.widget(
      find.descendant(
        of: find.byType(AuthSplashPage),
        matching: find.byType(Scaffold),
      ),
    );
    expect(scaffold.backgroundColor, AppPrimitives.brandNavy);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Once the hold elapses it moves on to the first-run language screen.
    expect(find.byType(AuthSplashPage), findsNothing);
    expect(find.byType(LanguageSelectionPage), findsOneWidget);
  });
}
