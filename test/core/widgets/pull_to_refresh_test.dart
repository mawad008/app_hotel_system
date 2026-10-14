import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';
import 'package:hotel_guest_app/core/errors/failure.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/widgets/message_view.dart';
import 'package:hotel_guest_app/core/widgets/pull_to_refresh.dart';
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
  bool fail = false;

  @override
  Future<Reservation> getById(String id) async {
    if (fail) throw const Failure(FailureKind.network);
    return current;
  }

  @override
  Future<List<Reservation>> list() async {
    if (fail) throw const Failure(FailureKind.network);
    return <Reservation>[current];
  }

  @override
  Future<Reservation> create(CreateReservationRequest request) =>
      throw UnimplementedError();
  @override
  Future<Reservation> cancel(String id) => throw UnimplementedError();
  @override
  Future<ExtendStayResult> extend(ExtendStayRequest request) =>
      throw UnimplementedError();
}

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(body: child),
);

Future<void> _pull(WidgetTester tester, Finder from) async {
  await tester.fling(from, const Offset(0, 400), 1000);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pulling a list shorter than the screen refreshes', (
    WidgetTester tester,
  ) async {
    int calls = 0;
    await tester.pumpWidget(
      _host(
        PullToRefresh(
          onRefresh: () async => calls++,
          child: ListView(children: const <Widget>[Text('only row')]),
        ),
      ),
    );
    await _pull(tester, find.text('only row'));
    expect(calls, 1);
  });

  testWidgets('pulling an empty / error state refreshes', (
    WidgetTester tester,
  ) async {
    int calls = 0;
    await tester.pumpWidget(
      _host(
        PullToRefresh(
          onRefresh: () async => calls++,
          child: const EmptyView(title: 'Nothing here'),
        ),
      ),
    );
    // Pull from near the top of the screen, well outside the centred block.
    await _pull(tester, find.byType(EmptyView));
    expect(calls, 1);
  });

  testWidgets('a failed refresh shows the reason in a snackbar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PullToRefresh(
          onRefresh: () async => throw const Failure(FailureKind.network),
          child: ListView(children: const <Widget>[Text('row')]),
        ),
      ),
    );
    await _pull(tester, find.text('row'));
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('row'), findsOneWidget);
  });

  testWidgets(
    'pulling the bookings screen shows a room assigned from the dashboard, '
    'and a failed pull keeps it on screen',
    (WidgetTester tester) async {
      final _LiveRepo repo = _LiveRepo(
        fakeReservation(id: 'r1', status: ReservationStatus.depositHeld),
      );
      final ProviderContainer c = await pumpApp(
        tester,
        bootSession: completeSession(),
        locale: const Locale('en'),
        extraOverrides: <Override>[
          reservationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      final en = await tester.l10n();
      c.read(appRouterProvider).goNamed(AppRoutes.bookingsName);
      await tester.pumpAndSettle();
      final String assigned =
          'The Oasis Hotel · ${en.bookingRoomNumber('412')}';
      expect(find.text(assigned), findsNothing);

      repo.current = fakeReservation(
        id: 'r1',
        status: ReservationStatus.depositHeld,
        roomNumber: '412',
      );
      await _pull(tester, find.byType(ListView).first);
      expect(find.text(assigned), findsOneWidget);

      repo.fail = true;
      await _pull(tester, find.byType(ListView).first);
      expect(find.text(assigned), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    },
  );
}
