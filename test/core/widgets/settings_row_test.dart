import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/theme/app_theme.dart';
import 'package:hotel_guest_app/core/widgets/settings_row.dart';

void main() {
  testWidgets('a long value never wraps the label (البريد الإلكتروني)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SettingsCard(
              children: <Widget>[
                SettingsRow(
                  label: 'البريد الإلكتروني',
                  value: 'abdelrahmanelhossieny7.long.address@gmail.com',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final RenderParagraph label = tester.renderObject<RenderParagraph>(
      find.text('البريد الإلكتروني'),
    );
    final RenderParagraph value = tester.renderObject<RenderParagraph>(
      find.text('abdelrahmanelhossieny7.long.address@gmail.com'),
    );

    // One line each: the label keeps its width, the value ellipsizes.
    final double lineHeight = label.getFullHeightForCaret(
      const TextPosition(offset: 0),
    );
    expect(label.size.height, lessThan(lineHeight * 1.5));
    expect(label.didExceedMaxLines, isFalse);
    expect(value.didExceedMaxLines, isTrue);
    expect(tester.takeException(), isNull);
  });
}
