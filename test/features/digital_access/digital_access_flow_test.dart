import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/digital_access/data/datasources/digital_access_data_source.dart';
import 'package:hotel_guest_app/features/digital_access/data/datasources/dummy_digital_access_data_source.dart';
import 'package:hotel_guest_app/features/digital_access/domain/entities/access_status.dart';
import 'package:hotel_guest_app/features/digital_access/presentation/state/digital_access_providers.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/extend_stay.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';
import 'package:hotel_guest_app/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';
import 'digital_access_test_support.dart';

class _ReservationRepo implements ReservationRepository {
  _ReservationRepo(this.status);
  final ReservationStatus status;

  @override
  Future<Reservation> create(CreateReservationRequest request) async =>
      fakeReservation(status: status);

  @override
  Future<Reservation> getById(String id) async =>
      fakeReservation(id: id, status: status);

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

Future<ProviderContainer> _open(
  WidgetTester tester,
  String reservationId, {
  ReservationStatus status = ReservationStatus.verified,
  Locale? locale,
  DigitalAccessDataSource? accessSource,
}) async {
  final c = await pumpApp(
    tester,
    bootSession: completeSession(),
    locale: locale,
    extraOverrides: <Override>[
      reservationRepositoryProvider.overrideWithValue(_ReservationRepo(status)),
      if (accessSource != null)
        digitalAccessDataSourceProvider.overrideWithValue(accessSource),
    ],
  );
  c.read(appRouterProvider).go('/reservation/$reservationId/check-in');
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('check-in → processing → active room key (EN)', (tester) async {
    final en = await _l10n('en');
    final id = reservationIdForCheckIn(DummyCheckInScenario.issuesActive);
    await _open(tester, id);

    expect(find.text(en.checkInReadyTitle), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, en.checkInCta));
    await tester.pumpAndSettle();

    // Landed on the digital-access screen with an active credential.
    expect(find.text(en.accessCheckedInTitle), findsOneWidget);
    expect(find.text(en.accessRoomNumberLabel), findsOneWidget);
    expect(find.text(en.accessEntryCodeLabel), findsOneWidget);
    expect(find.text(en.accessKeyNotWorking), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('access-credential')), findsOneWidget);

    await tester
        .tap(find.widgetWithText(FilledButton, en.bookingCtaMyCurrentStay));
    await tester.pumpAndSettle();
    expect(find.text(en.stayHomeTitle), findsWidgets);
  });

  testWidgets('not verified yet: no check-in CTA, a way back to the reservation instead',
      (tester) async {
    final en = await _l10n('en');
    final id = reservationIdForCheckIn(DummyCheckInScenario.issuesActive);
    await _open(tester, id, status: ReservationStatus.pending);

    expect(find.text(en.checkInNotReadyTitle), findsOneWidget);
    expect(find.widgetWithText(FilledButton, en.checkInCta), findsNothing);
    final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, en.identityBackToReservation));
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('issue failure shows a safe error + retry that recovers',
      (tester) async {
    final en = await _l10n('en');
    final id = reservationIdForCheckIn(DummyCheckInScenario.failsThenActive);
    await _open(tester, id);

    await tester.tap(find.widgetWithText(FilledButton, en.checkInCta));
    await tester.pumpAndSettle();

    expect(find.text(en.checkInFailedTitle), findsWidgets);
    // No provider internals leaked.
    expect(find.textContaining('provider_unavailable'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, en.checkInRetryCta));
    await tester.pumpAndSettle();
    expect(find.text(en.accessCheckedInTitle), findsOneWidget);
  });

  testWidgets('a revoked grant shows a safe notice, no credential',
      (tester) async {
    final en = await _l10n('en');
    final ds = DummyDigitalAccessDataSource(clock: () => DateTime(2026, 9, 8))
      ..seedGrant('res-revoked', AccessStatus.revoked);
    final c = await pumpApp(
      tester,
      bootSession: completeSession(),
      extraOverrides: <Override>[
        reservationRepositoryProvider
            .overrideWithValue(_ReservationRepo(ReservationStatus.checkedIn)),
        digitalAccessDataSourceProvider.overrideWithValue(ds),
      ],
    );
    c.read(appRouterProvider).go('/reservation/res-revoked/access');
    await tester.pumpAndSettle();

    expect(find.text(en.accessRevokedTitle), findsOneWidget);
    expect(find.text(en.accessEntryCodeLabel), findsNothing);
  });

  testWidgets('the flow renders right-to-left in Arabic', (tester) async {
    final ar = await _l10n('ar');
    final id = reservationIdForCheckIn(DummyCheckInScenario.issuesActive);
    await _open(tester, id, locale: arabic);

    expect(
      Directionality.of(tester.element(find.text(ar.checkInCta))),
      TextDirection.rtl,
    );
    await tester.tap(find.widgetWithText(FilledButton, ar.checkInCta));
    await tester.pumpAndSettle();
    expect(find.text(ar.accessCheckedInTitle), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text(ar.accessCheckedInTitle))),
      TextDirection.rtl,
    );
  });
}
