import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The page's main vertical scroll view (the first one in the tree).
final Finder pageScrollable = find
    .byWidgetPredicate(
      (Widget w) =>
          w is Scrollable && axisDirectionToAxis(w.axisDirection) == Axis.vertical,
    )
    .first;

/// Every text shown on the page, collected while scrolling it top to bottom.
///
/// Pages build their sections lazily, so a section below the fold isn't in
/// the tree until scrolled to — and one scrolled far away is dropped again.
/// Checking against what was seen over the whole scroll makes both "shown"
/// and "never shown" assertions cover the entire page.
Future<Set<String>> textsOnWholePage(WidgetTester tester) async {
  final ScrollableState state = tester.state<ScrollableState>(pageScrollable);
  final ScrollPosition position = state.position;
  final Set<String> seen = <String>{};
  void collect() {
    for (final Text text in tester.widgetList<Text>(find.byType(Text))) {
      final String? value = text.data ?? text.textSpan?.toPlainText();
      if (value != null) seen.add(value);
    }
  }

  position.jumpTo(position.minScrollExtent);
  await tester.pump();
  collect();
  while (position.pixels < position.maxScrollExtent) {
    position.jumpTo(math.min(position.pixels + 250, position.maxScrollExtent));
    await tester.pump();
    collect();
  }
  position.jumpTo(position.minScrollExtent);
  await tester.pump();
  return seen;
}
