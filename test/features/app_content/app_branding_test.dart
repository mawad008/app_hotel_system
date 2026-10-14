import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/platform/external_launcher.dart';
import 'package:hotel_guest_app/core/security/token_store.dart';
import 'package:hotel_guest_app/core/storage/app_preferences.dart';
import 'package:hotel_guest_app/core/theme/app_theme.dart';
import 'package:hotel_guest_app/features/app_content/data/datasources/api_app_content_data_source.dart';
import 'package:hotel_guest_app/features/app_content/data/datasources/dummy_app_content_data_source.dart';
import 'package:hotel_guest_app/features/app_content/domain/entities/app_content.dart';
import 'package:hotel_guest_app/features/app_content/presentation/state/app_content_providers.dart';
import 'package:hotel_guest_app/features/app_content/presentation/widgets/brand_link_actions.dart';

import '../../support/pump_app.dart';
import '../../support/test_config.dart';

class _NoTokens implements TokenStore {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> readAccessToken() async => null;
  @override
  Future<void> writeAccessToken(String token) async {}
  @override
  Future<String?> readProfileSnapshot() async => null;
  @override
  Future<void> writeProfileSnapshot(String snapshot) async {}
}

/// The API source with the network down — only its cache can answer.
class _OfflineApiSource extends ApiAppContentDataSource {
  _OfflineApiSource(super.client, super.preferences);

  @override
  Future<AppContent> fetchContent() async => throw const NetworkException();
}

class _RecordingLauncher implements ExternalLauncher {
  final List<String> calls = <String>[];

  @override
  Future<bool> dial(String phone) async {
    calls.add('dial:$phone');
    return true;
  }
  @override
  Future<bool> whatsapp(String phone) async {
    calls.add('wa:$phone');
    return true;
  }
  @override
  Future<bool> email(String email) async {
    calls.add('mail:$email');
    return true;
  }
  @override
  Future<bool> openUrl(String url) async {
    calls.add('url:$url');
    return true;
  }
  @override
  Future<bool> openMap({required double latitude, required double longitude}) async => true;
}

const Map<String, Object?> _response = <String, Object?>{
  'data': <String, Object?>{
    'app_name_i18n': <String, String>{'en': 'Oasis', 'ar': 'الواحة'},
    'app_icon_url': 'https://cdn.test/icon.png',
    'primary_color': '#1A2B3C',
    'support': <String, Object?>{
      'phone': '+20 100 123 4567',
      'whatsapp': '+201001234567',
      'email': 'help@oasis.test',
      'website': null,
    },
    'legal': <String, Object?>{'terms_url': 'https://oasis.test/terms', 'privacy_url': null},
    'faq': <Object?>[],
  },
};

void main() {
  final ApiClient client = ApiClient(config: testConfig, tokenStore: _NoTokens());

  test('the cached response is parsed into full branding', () {
    final AppContent? cached = ApiAppContentDataSource(
      client,
      InMemoryAppPreferences(appContentCache: jsonEncode(_response)),
    ).cachedContent();

    expect(cached, isNotNull);
    expect(cached!.appName.en, 'Oasis');
    expect(cached.primaryColor, const Color(0xFF1A2B3C));
    expect(cached.appIconUrl, 'https://cdn.test/icon.png');
    expect(cached.support.phone, '+20 100 123 4567');
    expect(cached.support.website, isNull);
    expect(cached.termsUrl, 'https://oasis.test/terms');
    expect(cached.privacyUrl, isNull);
  });

  test('an unreadable cache is ignored, never thrown', () {
    expect(
      ApiAppContentDataSource(client, InMemoryAppPreferences(appContentCache: '{oops'))
          .cachedContent(),
      isNull,
    );
  });

  test('offline, the app keeps the last branding instead of the defaults', () async {
    final InMemoryAppPreferences prefs =
        InMemoryAppPreferences(appContentCache: jsonEncode(_response));
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        appContentDataSourceProvider.overrideWithValue(_OfflineApiSource(client, prefs)),
      ],
    );
    addTearDown(container.dispose);

    // Before the fetch settles, the cached branding is already there…
    expect(container.read(brandingProvider).appName.en, 'Oasis');
    // …and a failed fetch resolves to it too.
    final AppContent content = await container.read(appContentProvider.future);
    expect(content.primaryColor, const Color(0xFF1A2B3C));
  });

  testWidgets('the app title and primary colour follow the dashboard', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      extraOverrides: <Override>[
        appContentDataSourceProvider.overrideWithValue(
          const DummyAppContentDataSource(
            content: AppContent(
              appName: ManagedText(en: 'Oasis', ar: 'الواحة'),
              primaryColor: Color(0xFF1A2B3C),
            ),
          ),
        ),
      ],
    );

    final MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.colorScheme.primary, const Color(0xFF1A2B3C));
    // A dark brand colour keeps white labels on buttons.
    expect(app.theme!.colorScheme.onPrimary, const Color(0xFFFFFFFF));
    expect(tester.widget<Title>(find.byType(Title)).title, 'Oasis');
  });

  testWidgets('support contacts open the dialer, WhatsApp and mail', (
    WidgetTester tester,
  ) async {
    final _RecordingLauncher launcher = _RecordingLauncher();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[externalLauncherProvider.overrideWithValue(launcher)],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SupportContactsCard(
              contacts: SupportContacts(
                phone: '+20 100 123 4567',
                whatsapp: '+201001234567',
                email: 'help@oasis.test',
              ),
            ),
          ),
        ),
      ),
    );
    final AppLocalizations en = await AppLocalizations.delegate.load(const Locale('en'));

    // Website not set → its row is hidden.
    expect(find.text(en.supportWebsite), findsNothing);

    await tester.tap(find.text(en.supportCall));
    await tester.tap(find.text(en.supportWhatsapp));
    await tester.tap(find.text(en.supportEmail));
    await tester.pump();

    expect(launcher.calls, <String>[
      'dial:+20 100 123 4567',
      'wa:+201001234567',
      'mail:help@oasis.test',
    ]);
  });

  testWidgets('no contacts configured renders nothing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SupportContactsCard(contacts: SupportContacts.none)),
      ),
    );
    expect(find.byType(InkWell), findsNothing);
  });
}
