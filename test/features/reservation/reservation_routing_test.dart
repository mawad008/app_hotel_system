import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_detail_provider.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';
import '../payment/payment_test_support.dart';

String _location(ProviderContainer c) =>
    c.read(appRouterProvider).routerDelegate.currentConfiguration.uri.path;

void main() {
  test('the reservation-detail route is registered alongside the earlier routes',
      () {
    final ProviderContainer c = ProviderContainer(overrides: authOverrides());
    addTearDown(c.dispose);
    final Iterable<String> paths = c
        .read(appRouterProvider)
        .configuration
        .routes
        .whereType<GoRoute>()
        .map((GoRoute r) => r.path);

    expect(
      paths,
      containsAll(<String>[
        AppRoutes.reservationDetail,
        // Phase 2/3 routes remain registered.
        AppRoutes.roomSelectionReview,
        AppRoutes.roomDetail,
        AppRoutes.availableRooms,
        AppRoutes.discover,
        // Phase 1 routes remain registered.
        AppRoutes.welcome,
        AppRoutes.signIn,
        AppRoutes.home,
      ]),
    );
  });

  testWidgets('an unauthenticated deep link to a reservation goes to welcome',
      (WidgetTester tester) async {
    final ProviderContainer c = await pumpApp(tester);
    c.read(appRouterProvider).go('/reservation/4821');
    await tester.pumpAndSettle();
    expect(_location(c), AppRoutes.welcome);
  });

  // Regression (device video 2026-10-07): identity verified → check-in "not
  // ready" → back → booking details → back landed on the router's error page
  // in the release APK, because the fallback was the debug-only /home route.
  testWidgets('back from booking details opened with go leads to the bookings list',
      (WidgetTester tester) async {
    final ProviderContainer c = await pumpApp(
      tester,
      bootSession: completeSession(),
      extraOverrides: <Override>[
        reservationDetailProvider.overrideWith(
          (Ref ref, String id) async => fakeReservation(id: id),
        ),
      ],
    );
    c.read(appRouterProvider).go('/reservation/9');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(const DefaultMaterialLocalizations().backButtonTooltip));
    await tester.pumpAndSettle();

    expect(_location(c), AppRoutes.bookings);
  });

  test('no screen navigates to the debug-only diagnostics route', () {
    final List<String> offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart') && !f.path.contains('app/router/'))
        .where((File f) => RegExp(r'AppRoutes\.home(Name)?\b').hasMatch(f.readAsStringSync()))
        .map((File f) => f.path)
        .toList();
    expect(offenders, isEmpty, reason: '/home exists only in debug builds');
  });
}
