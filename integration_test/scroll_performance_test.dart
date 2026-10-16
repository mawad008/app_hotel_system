// On-device performance run: scrolls the main screens and pushes/pops pages
// while recording the frame timeline. Uses the dummy data sources so network
// speed doesn't skew the numbers. See test_driver/perf_driver.dart for the
// command; results land in build/*.timeline_summary.json.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/app.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/auth_test_support.dart';

Future<void> _flingThrough(WidgetTester tester, {int times = 3}) async {
  final Finder list = find.byType(Scrollable).first;
  for (int i = 0; i < times; i++) {
    await tester.fling(list, const Offset(0, -900), 2500);
    await tester.pumpAndSettle();
    await tester.fling(list, const Offset(0, 900), 2500);
    await tester.pumpAndSettle();
  }
}

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Real frames while flinging, not the test binding's on-demand pumps.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  // Semantics off: testWidgets builds the accessibility tree by default,
  // which only screen-reader users pay for (it adds ~10 ms to each
  // transition frame on the emulator).
  testWidgets('scroll and transition performance', semanticsEnabled: false, (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = ProviderContainer(
      overrides: authOverrides(bootSession: completeSession()),
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const HotelGuestApp()),
    );
    await tester.pumpAndSettle();

    Future<void> open(String route) async {
      c.read(appRouterProvider).go(route);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    }

    await open('/discover');
    await binding.traceAction(
      () => _flingThrough(tester),
      reportKey: 'home_scroll',
    );

    await open('/discover/search');
    await binding.traceAction(
      () => _flingThrough(tester),
      reportKey: 'search_scroll',
    );

    await open('/discover/hotel/oasis');
    await binding.traceAction(
      () => _flingThrough(tester),
      reportKey: 'hotel_detail_scroll',
    );

    await open('/bookings');
    await binding.traceAction(
      () => _flingThrough(tester),
      reportKey: 'bookings_scroll',
    );

    // Fade transitions: open a hotel from Home and come back, a few times.
    await open('/discover');
    await binding.traceAction(() async {
      for (int i = 0; i < 4; i++) {
        c.read(appRouterProvider).push('/discover/hotel/oasis');
        await tester.pumpAndSettle();
        c.read(appRouterProvider).pop();
        await tester.pumpAndSettle();
      }
    }, reportKey: 'page_transitions');
  });
}
