import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/widgets/build_when_visible.dart';

void main() {
  testWidgets('builds the child only once it scrolls near the screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 3000),
                SizedBox(
                  height: 200,
                  child: BuildWhenVisible(
                    margin: 100,
                    placeholder: const Text('placeholder'),
                    child: const Text('live map'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('live map'), findsNothing);
    expect(find.text('placeholder'), findsOneWidget);

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -2400));
    await tester.pump();
    expect(find.text('live map'), findsOneWidget);
  });

  testWidgets('builds at once when already on screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          height: 200,
          child: BuildWhenVisible(child: Text('live map')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('live map'), findsOneWidget);
  });
}
