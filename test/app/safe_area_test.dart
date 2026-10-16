import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';

import '../support/app_fonts.dart';
import '../support/auth_test_support.dart';
import '../support/pump_app.dart';

/// Every screen keeps its text and icons out of the system's unsafe areas:
/// the status bar / notch, the home indicator / gesture bar, and — in
/// landscape — the side notch. Android 15+ draws apps edge-to-edge, so a
/// screen that ignores the insets would put content under them.
///
/// Rules, checked on each screen at rest and again with each vertical
/// scrollable scrolled to its end:
/// * nothing visible starts inside the top band unless it sits in a scroll
///   view that has been scrolled away from its top;
/// * nothing visible ends inside the bottom band unless it sits in a scroll
///   view with more content below (content may pass under the home
///   indicator while scrolling, but the end of it must clear it);
/// * in landscape, nothing outside a horizontal carousel enters the side
///   bands.

const double _dpr = 3;

/// iPhone-class portrait insets: notch + home indicator.
const EdgeInsets _portraitInsets = EdgeInsets.only(top: 47, bottom: 34);

/// Landscape: side notch on both edges, home indicator below.
const EdgeInsets _landscapeInsets = EdgeInsets.only(
  left: 47,
  right: 47,
  bottom: 21,
);

const List<String> _signedInRoutes = <String>[
  '/discover',
  '/discover/search',
  '/discover/hotel/oasis',
  '/discover/hotel/oasis/dates',
  '/discover/hotel/oasis/rooms',
  '/discover/hotel/oasis/rooms/deluxe',
  '/discover/hotel/oasis/review',
  '/bookings',
  '/services',
  '/account',
  '/notifications',
  '/account/details',
  '/account/preferences',
  '/account/favorites',
  '/account/privacy',
  '/account/support',
  '/account/support/faq',
  '/account/support/cancellation-policy',
  '/account/logout',
  '/reservation/seed-verified',
  '/reservation/seed-in-stay',
  '/reservation/seed-pending',
  '/reservation/seed-verified/reception',
  '/reservation/seed-pending/payment',
  '/reservation/seed-verified/check-in',
  '/reservation/seed-in-stay/access',
  '/reservation/seed-in-stay/services',
  '/reservation/seed-in-stay/checkout',
  '/reservation/seed-completed-1/invoice',
  '/reservation/seed-in-stay/loyalty',
  '/reservation/seed-completed-1/review',
  '/reservation/seed-in-stay/extend',
  '/reservation/seed-in-stay/report',
  '/reservation/seed-in-stay/reports',
];

const List<String> _signedOutRoutes = <String>[
  '/welcome',
  '/auth/phone',
  '/discover',
  '/bookings',
  '/services',
];

void _useDevice(WidgetTester tester, Size logical, EdgeInsets insets) {
  tester.view.devicePixelRatio = _dpr;
  tester.view.physicalSize = logical * _dpr;
  final FakeViewPadding padding = FakeViewPadding(
    left: insets.left * _dpr,
    top: insets.top * _dpr,
    right: insets.right * _dpr,
    bottom: insets.bottom * _dpr,
  );
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
  addTearDown(tester.view.reset);
}

Iterable<RenderParagraph> _paragraphs(RenderObject node) sync* {
  if (node is RenderParagraph) yield node;
  final List<RenderObject> children = <RenderObject>[];
  node.visitChildren(children.add);
  for (final RenderObject child in children) {
    yield* _paragraphs(child);
  }
}

/// Vertical / horizontal scroll positions the paragraph sits inside.
({List<ViewportOffset> vertical, List<ViewportOffset> horizontal}) _scrollers(
  RenderObject node,
) {
  final List<ViewportOffset> vertical = <ViewportOffset>[];
  final List<ViewportOffset> horizontal = <ViewportOffset>[];
  RenderObject? current = node.parent;
  while (current != null) {
    if (current is RenderViewportBase) {
      (current.axis == Axis.vertical ? vertical : horizontal).add(current.offset);
    }
    current = current.parent;
  }
  return (vertical: vertical, horizontal: horizontal);
}

bool _atStart(ViewportOffset o) =>
    o is! ScrollPosition || o.pixels <= o.minScrollExtent + 0.5;
bool _atEnd(ViewportOffset o) =>
    o is! ScrollPosition || o.pixels >= o.maxScrollExtent - 0.5;

/// Visible text / icons that break the rules above.
List<String> _violations(WidgetTester tester, EdgeInsets insets) {
  final RenderView view = tester.binding.renderViews.first;
  final Size screen = view.size;
  final List<String> found = <String>[];
  for (final RenderParagraph p in _paragraphs(view)) {
    if (!p.attached || !p.hasSize || p.size.isEmpty) continue;
    final String text = p.text.toPlainText().trim();
    if (text.isEmpty) continue;
    final Rect rect = MatrixUtils.transformRect(
      p.getTransformTo(null),
      Offset.zero & p.size,
    );
    if (!rect.overlaps(Offset.zero & screen)) continue;
    // Only what the user can actually see / touch: offstage, covered and
    // fully transparent text never wins the hit test at its centre.
    final HitTestResult hit = HitTestResult();
    tester.binding.hitTestInView(hit, rect.center, view.flutterView.viewId);
    if (!hit.path.any((HitTestEntry e) => e.target == p)) continue;

    final scrollers = _scrollers(p);
    const double tolerance = 0.5;
    if (rect.top < insets.top - tolerance && scrollers.vertical.every(_atStart)) {
      found.add('"$text" under the top inset (top ${rect.top.toStringAsFixed(1)})');
    }
    if (rect.bottom > screen.height - insets.bottom + tolerance &&
        scrollers.vertical.every(_atEnd)) {
      found.add(
        '"$text" under the bottom inset '
        '(bottom ${rect.bottom.toStringAsFixed(1)} of ${screen.height})',
      );
    }
    if (scrollers.horizontal.isEmpty &&
        (rect.left < insets.left - tolerance ||
            rect.right > screen.width - insets.right + tolerance)) {
      found.add('"$text" under a side inset (${rect.left.toStringAsFixed(1)}–'
          '${rect.right.toStringAsFixed(1)} of ${screen.width})');
    }
  }
  return found;
}

/// Checks the screen at rest, then with each vertical scrollable at its end.
Future<List<String>> _check(WidgetTester tester, EdgeInsets insets) async {
  final Set<String> found = <String>{..._violations(tester, insets)};
  final List<ScrollableState> scrollables = tester
      .stateList<ScrollableState>(find.byType(Scrollable))
      .where(
        (ScrollableState s) =>
            s.position.axis == Axis.vertical &&
            s.position.hasContentDimensions &&
            s.position.maxScrollExtent > 0,
      )
      .toList();
  for (final ScrollableState s in scrollables) {
    if (!s.mounted) continue;
    s.position.jumpTo(s.position.maxScrollExtent);
    await tester.pump();
    found.addAll(_violations(tester, insets));
  }
  return found.toList();
}

Future<void> _visit(
  WidgetTester tester,
  ProviderContainer c,
  String route,
  EdgeInsets insets,
  Map<String, List<String>> report,
) async {
  c.read(appRouterProvider).go(route);
  await tester.pumpAndSettle();
  final List<String> found = await _check(tester, insets);
  if (found.isNotEmpty) report[route] = found;
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the checker itself catches content under the top and bottom '
      'insets', (WidgetTester tester) async {
    _useDevice(tester, const Size(390, 844), _portraitInsets);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            Positioned(top: 4, left: 40, child: Text('under the notch')),
            Positioned(bottom: 4, left: 40, child: Text('under the bar')),
            Positioned(top: 300, left: 40, child: Text('safe')),
          ],
        ),
      ),
    );
    final List<String> found = _violations(tester, _portraitInsets);
    expect(found, hasLength(2));
    expect(found.join(), allOf(contains('under the notch'), contains('under the bar')));
  });

  testWidgets('signed-in screens respect the portrait safe area', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c =
        await pumpApp(tester, bootSession: completeSession());
    _useDevice(tester, const Size(390, 844), _portraitInsets);
    await tester.pumpAndSettle();

    final Map<String, List<String>> report = <String, List<String>>{};
    for (final String route in _signedInRoutes) {
      await _visit(tester, c, route, _portraitInsets, report);
    }
    expect(report, isEmpty, reason: _format(report));
  });

  testWidgets('signed-out screens respect the portrait safe area', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c = await pumpApp(tester, languageChosen: true);
    _useDevice(tester, const Size(390, 844), _portraitInsets);
    await tester.pumpAndSettle();

    final Map<String, List<String>> report = <String, List<String>>{};
    for (final String route in _signedOutRoutes) {
      await _visit(tester, c, route, _portraitInsets, report);
    }
    expect(report, isEmpty, reason: _format(report));
  });

  testWidgets('main screens respect the landscape side insets', (
    WidgetTester tester,
  ) async {
    final ProviderContainer c =
        await pumpApp(tester, bootSession: completeSession());
    _useDevice(tester, const Size(844, 390), _landscapeInsets);
    await tester.pumpAndSettle();

    final Map<String, List<String>> report = <String, List<String>>{};
    for (final String route in <String>[
      '/discover',
      '/discover/search',
      '/discover/hotel/oasis',
      '/bookings',
      '/services',
      '/account',
      '/reservation/seed-in-stay',
    ]) {
      await _visit(tester, c, route, _landscapeInsets, report);
    }
    expect(report, isEmpty, reason: _format(report));
  });
}

String _format(Map<String, List<String>> report) => report.entries
    .map((MapEntry<String, List<String>> e) =>
        '${e.key}:\n  ${e.value.take(6).join('\n  ')}')
    .join('\n');
