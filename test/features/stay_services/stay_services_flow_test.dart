import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/extend_stay.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';
import 'package:hotel_guest_app/features/stay_services/data/datasources/dummy_stay_services_data_source.dart';
import 'package:hotel_guest_app/features/stay_services/presentation/state/stay_services_providers.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';
import 'stay_services_test_support.dart';

class _ReservationRepo implements ReservationRepository {
  _ReservationRepo(this.id);
  final String id;
  @override
  Future<Reservation> create(CreateReservationRequest request) async =>
      fakeReservation(id: id);
  @override
  Future<Reservation> getById(String id) async => fakeReservation(id: id);
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
  Locale? locale,
  DummyStayServicesDataSource? source,
}) async {
  final c = await pumpApp(
    tester,
    bootSession: completeSession(),
    locale: locale,
    extraOverrides: <Override>[
      reservationRepositoryProvider
          .overrideWithValue(_ReservationRepo(reservationId)),
      if (source != null)
        stayServicesDataSourceProvider.overrideWithValue(source),
    ],
  );
  c.read(appRouterProvider).go('/reservation/$reservationId/services');
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('catalogue → detail → request → order detail (EN)',
      (tester) async {
    final en = await _l10n('en');
    final rid = reservationIdWithCancellableOrder();
    await _open(tester, rid);

    expect(find.text(en.servicesTitle), findsWidgets);
    expect(find.text('Room cleaning'), findsWidgets);

    await tester.tap(find.text('Room cleaning').first);
    await tester.pumpAndSettle();
    expect(find.text(en.serviceDetailTitle), findsWidgets);

    await tester
        .tap(find.widgetWithText(FilledButton, en.serviceRequestCta));
    await tester.pumpAndSettle();

    // Landed on the request/order detail screen.
    expect(find.text(en.serviceOrderDetailTitle), findsWidgets);
    expect(find.textContaining('SR-'), findsWidgets);
    expect(find.text(en.serviceStatusRequested), findsWidgets);
  });

  testWidgets('a requested order can be cancelled from its detail screen',
      (tester) async {
    final en = await _l10n('en');
    final rid = reservationIdWithCancellableOrder();
    await _open(tester, rid);

    await tester.tap(find.text('Room cleaning').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, en.serviceRequestCta));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, en.serviceCancelCta));
    await tester.pumpAndSettle();
    // Confirm dialog.
    await tester.tap(find.widgetWithText(FilledButton, en.serviceCancelConfirmCta));
    await tester.pumpAndSettle();

    // Popped back to the catalogue (design: return after cancelling).
    expect(find.text(en.servicesTitle), findsWidgets);
  });

  testWidgets('the requests list shows an empty state with a new-request CTA',
      (tester) async {
    final en = await _l10n('en');
    final rid = reservationIdWithCancellableOrder();
    final c = await _open(tester, rid);

    c.read(appRouterProvider).go('/reservation/$rid/service-orders');
    await tester.pumpAndSettle();
    expect(find.text(en.myRequestsEmptyTitle), findsOneWidget);
    expect(find.widgetWithText(FilledButton, en.newRequestCta), findsOneWidget);
  });

  testWidgets('the catalogue renders right-to-left in Arabic', (tester) async {
    final ar = await _l10n('ar');
    final rid = reservationIdWithCancellableOrder();
    await _open(tester, rid, locale: arabic);

    expect(
      Directionality.of(tester.element(find.text('تنظيف الغرفة').first)),
      TextDirection.rtl,
    );
    await tester.tap(find.text('تنظيف الغرفة').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, ar.serviceRequestCta));
    await tester.pumpAndSettle();
    expect(find.text(ar.serviceOrderDetailTitle), findsWidgets);
  });
}
