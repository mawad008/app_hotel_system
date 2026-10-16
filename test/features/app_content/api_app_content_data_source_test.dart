import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/network/interceptors/error_interceptor.dart';
import 'package:hotel_guest_app/core/storage/app_preferences.dart';
import 'package:hotel_guest_app/features/app_content/data/datasources/api_app_content_data_source.dart';
import 'package:hotel_guest_app/features/app_content/domain/entities/app_content.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body);

  final Map<String, dynamic> body;
  final List<RequestOptions> received = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    received.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiAppContentDataSource _source(
  _FakeAdapter adapter, [
  AppPreferences? preferences,
]) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
    ..httpClientAdapter = adapter
    ..interceptors.add(ErrorInterceptor());
  return ApiAppContentDataSource(ApiClient.withDio(dio), preferences);
}

void main() {
  const Locale ar = Locale('ar');
  const Locale en = Locale('en');

  test('reads GET /guest/app-content into AppContent', () async {
    final _FakeAdapter adapter = _FakeAdapter(<String, dynamic>{
      'success': true,
      'message': 'OK',
      'data': <String, dynamic>{
        'app_name_i18n': <String, dynamic>{'en': 'Oasis', 'ar': 'الواحة'},
        'logo_url': 'https://cdn.example.com/guest-app/logo/a.png',
        'onboarding_image_url':
            'https://cdn.example.com/guest-app/onboarding_image/b.jpg',
        'onboarding_title_i18n': <String, dynamic>{'ar': 'أهلاً'},
        'onboarding_body_i18n': null,
        'onboarding_cta_i18n': <String, dynamic>{'en': '  ', 'ar': 'ابدأ'},
        'updated_at': '2026-09-24T00:00:00Z',
      },
    });

    final AppContent content = await _source(adapter).fetchContent();

    expect(adapter.received.single.path, '/guest/app-content');
    expect(content.appName.resolve(en), 'Oasis');
    expect(content.appName.resolve(ar), 'الواحة');
    expect(content.logoUrl, 'https://cdn.example.com/guest-app/logo/a.png');
    expect(content.onboardingImageUrl, endsWith('b.jpg'));
    // A missing locale stays null so the screen uses its bundled copy in the
    // same language — it never borrows the other language.
    expect(content.onboardingTitle.resolve(ar), 'أهلاً');
    expect(content.onboardingTitle.resolve(en), isNull);
    expect(content.onboardingBody.resolve(ar), isNull);
    expect(content.onboardingCta.resolve(en), isNull);
    expect(content.onboardingCta.resolve(ar), 'ابدأ');
  });

  test('an unconfigured backend yields empty content', () async {
    final _FakeAdapter adapter = _FakeAdapter(<String, dynamic>{
      'success': true,
      'message': 'OK',
      'data': <String, dynamic>{
        'app_name_i18n': null,
        'logo_url': null,
        'onboarding_image_url': null,
        'onboarding_title_i18n': null,
        'onboarding_body_i18n': null,
        'onboarding_cta_i18n': null,
        'updated_at': null,
      },
    });

    final AppContent content = await _source(adapter).fetchContent();

    expect(content.logoUrl, isNull);
    expect(content.onboardingImageUrl, isNull);
    expect(content.appName.resolve(ar), isNull);
  });

  test('empty objects sent as [] and numbers sent as strings are read, '
      'not thrown on', () async {
    final InMemoryAppPreferences prefs = InMemoryAppPreferences();
    final _FakeAdapter adapter = _FakeAdapter(<String, dynamic>{
      'success': true,
      'meta': <String, dynamic>{
        'booking_policy': <String, dynamic>{'free_cancellation_hours': '24'},
      },
      'data': <String, dynamic>{
        'app_name_i18n': <String, dynamic>{'en': 'Oasis'},
        'support': <dynamic>[],
        'legal': <dynamic>[],
        'faq': <String, dynamic>{},
      },
    });

    final AppContent content = await _source(adapter, prefs).fetchContent();

    expect(content.appName.resolve(en), 'Oasis');
    expect(content.freeCancellationHours, 24);
    expect(content.support.phone, isNull);
    expect(content.faq, isEmpty);
    // The cache written from that response reads back the same way.
    expect(
      _source(adapter, prefs).cachedContent()?.appName.resolve(en),
      'Oasis',
    );
  });

  test('a cache in a shape this build cannot read is ignored', () {
    final InMemoryAppPreferences prefs = InMemoryAppPreferences(
      appContentCache: jsonEncode(<String, dynamic>{
        'data': <String, dynamic>{'faq': 'not a list', 'support': 42},
        'meta': <dynamic>['unexpected'],
      }),
    );
    expect(
      () => _source(_FakeAdapter(const <String, dynamic>{}), prefs).cachedContent(),
      returnsNormally,
    );
  });
}
