import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';
import 'package:hotel_guest_app/core/widgets/live_refresh.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/extend_stay.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';
import 'package:hotel_guest_app/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';

import '../../features/payment/payment_test_support.dart' show fakeReservation;
import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';

/// A server whose answer changes between fetches (staff act in the dashboard).
class _LiveRepo implements ReservationRepository {
  _LiveRepo(this.current);
  Reservation current;
  int fetches = 0;
  @override
  Future<Reservation> getById(String id) async {
    fetches++;
    return current;
  }

  @override
  Future<List<Reservation>> list() async => <Reservation>[current];
  @override
  Future<Reservation> create(CreateReservationRequest request) => throw UnimplementedError();
  @override
  Future<Reservation> cancel(String id) => throw UnimplementedError();
  @override
  Future<ExtendStayResult> extend(ExtendStayRequest request) => throw UnimplementedError();
}

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('refreshes on every interval while visible', (WidgetTester tester) async {
    int calls = 0;
    await tester.pumpWidget(
      _host(
        LiveRefresh(
          interval: const Duration(seconds: 10),
          onRefresh: () => calls++,
          child: const SizedBox(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 25));
    expect(calls, 2);
  });

  testWidgets('does not refresh while hidden (inactive tab / ticker off)', (WidgetTester tester) async {
    int calls = 0;
    await tester.pumpWidget(
      _host(
        TickerMode(
          enabled: false,
          child: LiveRefresh(
            interval: const Duration(seconds: 10),
            onRefresh: () => calls++,
            child: const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 25));
    expect(calls, 0);
  });

  testWidgets('does not refresh while another route covers it', (WidgetTester tester) async {
    int calls = 0;
    final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        home: LiveRefresh(
          interval: const Duration(seconds: 10),
          onRefresh: () => calls++,
          child: const SizedBox(),
        ),
      ),
    );
    nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => const SizedBox()));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 25));
    expect(calls, 0);
  });

  testWidgets('refreshes when the app returns to the foreground', (WidgetTester tester) async {
    int calls = 0;
    await tester.pumpWidget(
      _host(LiveRefresh(interval: null, onRefresh: () => calls++, child: const SizedBox())),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets(
      'a room assigned from the dashboard shows on the open bookings screen '
      'without restarting the app', (WidgetTester tester) async {
    final _LiveRepo repo = _LiveRepo(
      fakeReservation(id: 'r1', status: ReservationStatus.depositHeld),
    );
    final ProviderContainer c = await pumpApp(
      tester,
      bootSession: completeSession(),
      locale: const Locale('en'),
      extraOverrides: <Override>[reservationRepositoryProvider.overrideWithValue(repo)],
    );
    final en = await tester.l10n();
    c.read(appRouterProvider).goNamed(AppRoutes.bookingsName);
    await tester.pumpAndSettle();
    final String assigned = 'The Oasis Hotel · ${en.bookingRoomNumber('412')}';
    expect(find.text(assigned), findsNothing);

    // Staff assign room 412 in the dashboard while the guest watches.
    repo.current = fakeReservation(
      id: 'r1',
      status: ReservationStatus.depositHeld,
      roomNumber: '412',
    );
    await tester.pump(LiveRefresh.defaultInterval);
    await tester.pumpAndSettle();

    expect(find.text(assigned), findsOneWidget);
  });
}
