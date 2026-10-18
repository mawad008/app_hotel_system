import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/network/interceptors/error_interceptor.dart';
import 'package:hotel_guest_app/core/time/clock.dart';
import 'package:hotel_guest_app/features/notifications/data/datasources/api_notifications_data_source.dart';
import 'package:hotel_guest_app/features/notifications/data/datasources/dummy_notifications_data_source.dart';
import 'package:hotel_guest_app/features/notifications/domain/entities/guest_notification.dart';
import 'package:hotel_guest_app/features/notifications/presentation/state/notifications_providers.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);

  final Map<String, (int, Map<String, dynamic>)> routes;
  final List<String> calls = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String key = '${options.method} ${options.path}';
    calls.add(key);
    final (int, Map<String, dynamic>) entry =
        routes[key] ?? (404, <String, dynamic>{'success': false, 'message': 'no route $key'});
    return ResponseBody.fromString(
      jsonEncode(entry.$2),
      entry.$1,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _row(int id, {bool read = false, String type = 'identity_verified'}) =>
    <String, dynamic>{
      'id': id,
      'reservation_id': 73,
      'hotel_id': 4,
      'type': type,
      'channel': 'in_app',
      'status': 'sent',
      'subject': 'Identity verified',
      'body': 'You can check in now.',
      'is_read': read,
      'read_at': read ? '2026-09-25T10:00:00.000000Z' : null,
      'created_at': '2026-09-25T09:00:00.000000Z',
    };

void main() {
  final DateTime now = DateTime(2026, 9, 25, 12);

  group('ApiNotificationsDataSource', () {
    ApiNotificationsDataSource source(_FakeAdapter adapter) => ApiNotificationsDataSource(
          ApiClient.withDio(
            Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
              ..httpClientAdapter = adapter
              ..interceptors.add(ErrorInterceptor()),
          ),
        );

    test('reads the feed and the server unread count', () async {
      final _FakeAdapter adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
        'GET /guest/notifications': (200, <String, dynamic>{
          'success': true,
          'data': <Object>[_row(2), _row(1, read: true, type: 'something_new')],
          'meta': <String, dynamic>{'unread_count': 7},
        }),
      });
      final NotificationFeed feed = await source(adapter).fetchFeed();
      expect(feed.unreadCount, 7);
      expect(feed.items.map((GuestNotification n) => n.id), <String>['2', '1']);
      expect(feed.items.first.type, GuestNotificationType.identityVerified);
      expect(feed.items.first.reservationId, '73');
      expect(feed.items.last.type, GuestNotificationType.unknown);
      expect(feed.items.last.isRead, isTrue);
    });

    test('marks one and all read on the guest-wide endpoints', () async {
      final _FakeAdapter adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
        'PATCH /guest/notifications/2/read': (200, <String, dynamic>{
          'success': true,
          'data': _row(2, read: true),
        }),
        'POST /guest/notifications/read-all': (200, <String, dynamic>{
          'success': true,
          'data': <String, dynamic>{'marked_read': 3},
        }),
      });
      final ApiNotificationsDataSource api = source(adapter);
      expect((await api.markRead('2')).isRead, isTrue);
      expect(await api.markAllRead(), 3);
      expect(adapter.calls, <String>[
        'PATCH /guest/notifications/2/read',
        'POST /guest/notifications/read-all',
      ]);
    });
  });

  test('dummy source keeps read state for the session', () async {
    final DummyNotificationsDataSource dummy = DummyNotificationsDataSource(clock: () => now);
    final NotificationFeed before = await dummy.fetchFeed();
    expect(before.unreadCount, 3);
    await dummy.markRead(before.items.first.id);
    expect((await dummy.fetchFeed()).unreadCount, 2);
    await dummy.markAllRead();
    expect((await dummy.fetchFeed()).unreadCount, 0);
  });

  testWidgets('the feed groups rows, shows the unread banner and marks all read',
      (WidgetTester tester) async {
    final ProviderContainer container = await pumpApp(
      tester,
      bootSession: completeSession(),
      extraOverrides: <Override>[clockProvider.overrideWithValue(() => now)],
    );
    final en = await tester.l10n();
    container.read(appRouterProvider).goNamed(AppRoutes.notificationsName);
    await tester.pumpAndSettle();

    expect(find.text(en.notificationsUnreadTitle(3)), findsOneWidget);
    expect(find.text(en.notificationsNow), findsOneWidget);
    expect(find.text(en.notificationsYesterday), findsNWidgets(2));

    await tester.tap(find.widgetWithText(FilledButton, en.notificationsMarkAllRead));
    await tester.pumpAndSettle();
    expect(find.text(en.notificationsAllReadTitle), findsOneWidget);
    expect(container.read(unreadNotificationsCountProvider), 0);
  });

  testWidgets('a signed-out guest has an empty feed and no request is made',
      (WidgetTester tester) async {
    final ProviderContainer container = await pumpApp(tester);
    final NotificationFeed feed = await container.read(notificationFeedProvider.future);
    expect(feed, NotificationFeed.empty);
  });
}
