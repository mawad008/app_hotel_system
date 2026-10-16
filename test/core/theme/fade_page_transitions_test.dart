import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/theme/app_theme.dart';

Widget _app(TargetPlatform platform) {
  return MaterialApp(
    theme: AppTheme.light.copyWith(platform: platform),
    home: Builder(
      builder: (BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('second')),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('pages fade in — no slide or zoom — by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app(TargetPlatform.android));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final Finder second = find.text('second');
    final FadeTransition fade = tester.widget<FadeTransition>(
      find.ancestor(of: second, matching: find.byType(FadeTransition)).first,
    );
    expect(fade.opacity.value, inExclusiveRange(0.0, 1.0));
    expect(
      find.ancestor(of: second, matching: find.byType(SlideTransition)),
      findsNothing,
    );
    expect(
      find.ancestor(of: second, matching: find.byType(ScaleTransition)),
      findsNothing,
    );

    await tester.pumpAndSettle();
    expect(second, findsOneWidget);
  });

  testWidgets('iOS keeps the edge swipe-back gesture', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app(TargetPlatform.iOS));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('second'), findsOneWidget);

    final TestGesture swipe = await tester.startGesture(const Offset(5, 300));
    await swipe.moveBy(const Offset(400, 0));
    await swipe.up();
    await tester.pumpAndSettle();

    expect(find.text('second'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
