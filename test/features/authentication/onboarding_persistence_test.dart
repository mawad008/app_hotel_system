import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/localization/locale_controller.dart';
import 'package:hotel_guest_app/core/storage/app_preferences.dart';
import 'package:hotel_guest_app/features/authentication/presentation/pages/entry_welcome_page.dart';
import 'package:hotel_guest_app/features/authentication/presentation/pages/language_selection_page.dart';
import 'package:hotel_guest_app/features/authentication/presentation/state/language_selection_controller.dart';
import 'package:hotel_guest_app/features/discovery/presentation/pages/discover_page.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('finishing onboarding is persisted', (WidgetTester tester) async {
    final InMemoryAppPreferences prefs = InMemoryAppPreferences();
    await pumpApp(
      tester,
      extraOverrides: <Override>[appPreferencesProvider.overrideWithValue(prefs)],
    );
    expect(find.byType(EntryWelcomePage), findsOneWidget);

    final AppLocalizations en = await tester.l10n();
    await tester.tap(find.text(en.entryStartAction));
    await tester.pumpAndSettle();

    expect(find.byType(DiscoverPage), findsOneWidget);
    expect(prefs.onboardingCompleted, isTrue);
  });

  testWidgets(
    'a relaunch after onboarding skips language + onboarding for a guest',
    (WidgetTester tester) async {
      // Real start-up state: nothing seeded but the persisted flag.
      await pumpApp(
        tester,
        languageChosen: false,
        extraOverrides: <Override>[
          appPreferencesProvider.overrideWithValue(
            InMemoryAppPreferences(onboardingCompleted: true),
          ),
          languageSelectedProvider.overrideWith(LanguageSelectionController.new),
        ],
      );

      expect(find.byType(LanguageSelectionPage), findsNothing);
      expect(find.byType(EntryWelcomePage), findsNothing);
      expect(find.byType(DiscoverPage), findsOneWidget);
    },
  );

  testWidgets('the first launch still shows the language screen', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      languageChosen: false,
      extraOverrides: <Override>[
        languageSelectedProvider.overrideWith(LanguageSelectionController.new),
      ],
    );

    expect(find.byType(LanguageSelectionPage), findsOneWidget);
  });

  group('LocaleController persistence', () {
    ProviderContainer containerWith(AppPreferences prefs) {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[appPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('restores the stored language', () {
      final ProviderContainer container = containerWith(
        InMemoryAppPreferences(localeCode: 'en'),
      );
      expect(container.read(localeControllerProvider), const Locale('en'));
    });

    test('defaults to Arabic when nothing is stored', () {
      final ProviderContainer container = containerWith(
        InMemoryAppPreferences(),
      );
      expect(container.read(localeControllerProvider), const Locale('ar'));
    });

    test('persists a change, including "follow the device"', () {
      final InMemoryAppPreferences prefs = InMemoryAppPreferences();
      final ProviderContainer container = containerWith(prefs);

      container.read(localeControllerProvider.notifier).set(const Locale('en'));
      expect(prefs.localeCode, 'en');

      container.read(localeControllerProvider.notifier).useDeviceLocale();
      expect(prefs.localeCode, 'system');
      expect(containerWith(prefs).read(localeControllerProvider), isNull);
    });
  });
}
