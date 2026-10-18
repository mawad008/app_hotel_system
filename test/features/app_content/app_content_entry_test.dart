import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/app_content/data/datasources/app_content_data_source.dart';
import 'package:hotel_guest_app/features/app_content/data/datasources/dummy_app_content_data_source.dart';
import 'package:hotel_guest_app/features/app_content/domain/entities/app_content.dart';
import 'package:hotel_guest_app/features/app_content/presentation/state/app_content_providers.dart';

import '../../support/pump_app.dart';

class _FailingSource implements AppContentDataSource {
  @override
  Future<AppContent> fetchContent() async => throw const NetworkException();
}

/// Answers only after [delay] — a cold start on a slow mobile network.
class _SlowSource implements AppContentDataSource {
  _SlowSource(this.delay, this.content);
  final Duration delay;
  final AppContent content;

  @override
  Future<AppContent> fetchContent() =>
      Future<AppContent>.delayed(delay, () => content);
}

void main() {
  testWidgets('onboarding shows the dashboard-managed copy', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      extraOverrides: <Override>[
        appContentDataSourceProvider.overrideWithValue(
          const DummyAppContentDataSource(
            content: AppContent(
              onboardingTitle: ManagedText(en: 'Welcome to Oasis', ar: 'أهلاً'),
              onboardingCta: ManagedText(en: 'Explore'),
            ),
          ),
        ),
      ],
    );
    final AppLocalizations en = await tester.l10n();

    expect(find.text('Welcome to Oasis'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text(en.entryHeadline), findsNothing);
    // Not configured → the bundled copy.
    expect(find.text(en.entrySubtext), findsOneWidget);
    // No uploaded logo → only the app name.
    expect(find.text(en.brandWordmark), findsOneWidget);
  });

  testWidgets('a failed content fetch falls back to the bundled defaults', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      extraOverrides: <Override>[
        appContentDataSourceProvider.overrideWithValue(_FailingSource()),
      ],
    );
    final AppLocalizations en = await tester.l10n();

    expect(find.text(en.entryHeadline), findsOneWidget);
    expect(find.text(en.entryStartAction), findsOneWidget);
    expect(find.text(en.brandWordmark), findsOneWidget);
  });

  test('appContentProvider never throws', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appContentDataSourceProvider.overrideWithValue(_FailingSource()),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(appContentProvider.future),
      same(AppContent.empty),
    );
  });

  testWidgets('a response that lands after the timeout is still adopted', (
    WidgetTester tester,
  ) async {
    const AppContent fresh =
        AppContent(appName: ManagedText(en: 'STDY HOTELS', ar: 'ستدي هوتلز'));
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appContentDataSourceProvider.overrideWithValue(
          _SlowSource(const Duration(seconds: 5), fresh),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(appContentProvider, (_, _) {});

    // The deadline passes first: the bundled defaults stand in.
    await tester.pump(appContentTimeout + const Duration(milliseconds: 10));
    expect(container.read(appContentProvider).value, same(AppContent.empty));

    // Then the real answer arrives and replaces them.
    await tester.pump(const Duration(seconds: 3));
    expect(container.read(appContentProvider).value, same(fresh));
  });
}
