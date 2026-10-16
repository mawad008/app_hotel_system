import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';

import '../support/auth_test_support.dart';
import '../support/pump_app.dart';

String _location(ProviderContainer c) =>
    c.read(appRouterProvider).routerDelegate.currentConfiguration.uri.path;

void main() {
  for (final String tab in <String>[
    AppRoutes.bookingsName,
    AppRoutes.stayHomeName,
    AppRoutes.accountName,
  ]) {
    testWidgets('Android back on the $tab tab returns to Home instead of '
        'closing the app', (WidgetTester tester) async {
      final ProviderContainer c =
          await pumpApp(tester, bootSession: completeSession());
      c.read(appRouterProvider).goNamed(tab);
      await tester.pumpAndSettle();

      final bool handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(handled, isTrue);
      expect(_location(c), AppRoutes.discover);
    });
  }

  testWidgets('Android back on Home is left to the system (exits the app)',
      (WidgetTester tester) async {
    final ProviderContainer c =
        await pumpApp(tester, bootSession: completeSession());
    c.read(appRouterProvider).goNamed(AppRoutes.discoverName);
    await tester.pumpAndSettle();

    expect(await tester.binding.handlePopRoute(), isFalse);
  });
}
