import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';

String _location(ProviderContainer c) =>
    c.read(appRouterProvider).routerDelegate.currentConfiguration.uri.path;

void main() {
  test('every Phase 2 discovery route is registered', () {
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
        AppRoutes.discover,
        AppRoutes.hotelSearch,
        AppRoutes.hotelDetail,
        AppRoutes.stayDates,
        AppRoutes.availableRooms,
        // Phase 3 adds the room-detail and read-only selection-review screens.
        AppRoutes.roomDetail,
        AppRoutes.roomSelectionReview,
        // Phase 1 routes remain registered.
        AppRoutes.welcome,
        AppRoutes.signIn,
        AppRoutes.otp,
        AppRoutes.home,
      ]),
    );
  });

  testWidgets('an authenticated guest lands on discover',
      (WidgetTester tester) async {
    final ProviderContainer c =
        await pumpApp(tester, bootSession: completeSession());
    expect(_location(c), AppRoutes.discover);
  });

  testWidgets('a guest may browse discovery without an account (deferred auth)',
      (WidgetTester tester) async {
    final ProviderContainer c = await pumpApp(tester);
    c.read(appRouterProvider).go('/discover/hotel/oasis');
    await tester.pumpAndSettle();
    expect(_location(c), '/discover/hotel/oasis');
  });

  testWidgets('hotel detail back works with nothing to pop (reached with go)',
      (WidgetTester tester) async {
    final ProviderContainer c =
        await pumpApp(tester, bootSession: completeSession());
    // e.g. the post-sign-in return replaces the stack with `go`.
    c.read(appRouterProvider).go('/discover/hotel/oasis');
    await tester.pumpAndSettle();
    expect(_location(c), '/discover/hotel/oasis');

    await tester.tap(find.byTooltip('Back').first);
    await tester.pumpAndSettle();
    expect(_location(c), AppRoutes.discover);
  });

  // Sign-out moved from Discover's app bar to the Account tab in Mobile
  // Phase 11 (mobile/docs/design-system.md) — its redirect behavior is
  // covered by auth_routing_test.dart now.
}
