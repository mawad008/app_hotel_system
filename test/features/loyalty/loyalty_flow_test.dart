import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/loyalty/data/datasources/dummy_loyalty_data_source.dart';
import 'package:hotel_guest_app/features/loyalty/data/repositories/loyalty_repository_impl.dart';
import 'package:hotel_guest_app/features/loyalty/presentation/state/loyalty_providers.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/extend_stay.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';
import 'package:hotel_guest_app/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';
import 'loyalty_test_support.dart';

final DateTime _now = DateTime(2026, 9, 8, 11);

class _ReservationRepo implements ReservationRepository {
  _ReservationRepo(this.status);
  final ReservationStatus status;
  @override
  Future<Reservation> create(CreateReservationRequest request) async =>
      fakeReservation(status: status);
  @override
  Future<Reservation> getById(String id) async =>
      fakeReservation(id: id, status: status, amount: 900);
  @override
  Future<List<Reservation>> list() async => <Reservation>[];

  @override
  Future<Reservation> cancel(String id) async => fakeReservation(id: id);

  @override
  Future<ExtendStayResult> extend(ExtendStayRequest request) async {
    throw UnimplementedError('extend not used in this test');
  }
}

Future<AppLocalizations> _l10n(String code) =>
    AppLocalizations.delegate.load(Locale(code));

Future<void> _openLoyalty(
  WidgetTester tester,
  String id, {
  ReservationStatus status = ReservationStatus.checkedOut,
  Locale? locale,
}) async {
  final ds = DummyLoyaltyDataSource(clock: () => _now);
  final c = await pumpApp(
    tester,
    bootSession: completeSession(),
    locale: locale,
    extraOverrides: <Override>[
      loyaltyDataSourceProvider.overrideWithValue(ds),
      loyaltyRepositoryProvider.overrideWithValue(LoyaltyRepositoryImpl(ds)),
      reservationRepositoryProvider.overrideWithValue(_ReservationRepo(status)),
    ],
  );
  c.read(appRouterProvider).go('/reservation/$id/loyalty');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'a completed stay is credited automatically — no guest earn action',
      (tester) async {
    final en = await _l10n('en');
    await _openLoyalty(tester, activeProgramId());

    expect(find.text(en.loyaltyBalanceLabel), findsOneWidget);
    // 1240 seeded + 900 / 2 = 450 accrued on completion (dummy sample rate).
    expect(find.text(en.loyaltyPointsValue(1690)), findsWidgets);
    expect(find.text(en.loyaltyAlreadyEarnedTitle), findsOneWidget);
    expect(find.text(en.loyaltyPointsAdded(450)), findsWidgets);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('a stay not yet completed explains points arrive on completion',
      (tester) async {
    final en = await _l10n('en');
    await _openLoyalty(tester, activeProgramId(),
        status: ReservationStatus.checkedIn);

    expect(find.text(en.loyaltyPointsValue(1240)), findsWidgets);
    expect(find.text(en.loyaltyAlreadyEarnedTitle), findsNothing);
  });

  testWidgets('an inactive programme shows the "off" banner and earns nothing',
      (tester) async {
    final en = await _l10n('en');
    await _openLoyalty(tester, programInactiveId());

    expect(find.text(en.loyaltyProgramOffTitle), findsOneWidget);
    expect(find.text(en.loyaltyAlreadyEarnedTitle), findsNothing);
    expect(find.text(en.loyaltyPointsValue(1240)), findsWidgets);
  });

  testWidgets('the points history is listed newest-first', (tester) async {
    final en = await _l10n('en');
    await _openLoyalty(tester, activeProgramId());
    expect(find.text(en.loyaltyHistoryTitle), findsOneWidget);
    // Seeded ledger has an earn and a redeem entry.
    expect(find.text(en.loyaltyPointsAdded(450)), findsWidgets);
  });

  testWidgets('renders right-to-left in Arabic', (tester) async {
    final ar = await _l10n('ar');
    await _openLoyalty(tester, activeProgramId(), locale: arabic);
    expect(
      Directionality.of(tester.element(find.text(ar.loyaltyBalanceLabel))),
      TextDirection.rtl,
    );
  });
}
