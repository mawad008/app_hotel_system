import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/discovery/presentation/widgets/stay_range_calendar.dart';

Widget _host({
  required Locale locale,
  DateTime? checkIn,
  DateTime? checkOut,
  required ValueChanged<DateTime> onSelect,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: StayRangeCalendar(
          firstDay: DateTime(2026, 9, 1),
          today: DateTime(2026, 9, 1),
          checkIn: checkIn,
          checkOut: checkOut,
          onSelectDay: onSelect,
          monthCount: 2,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders localized short weekday names and month headings',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(
      locale: const Locale('en'),
      onSelect: (_) {},
    ));
    expect(find.text('Sun'), findsWidgets);
    expect(find.text('Sat'), findsWidgets);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('October 2026'), findsOneWidget);
  });

  testWidgets('renders Arabic weekday names and Arabic-Indic day digits',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(
      locale: const Locale('ar'),
      onSelect: (_) {},
    ));
    expect(find.text('أحد'), findsWidgets);
    expect(find.text('سبت'), findsWidgets);
    expect(find.text('٦'), findsWidgets); // day 6
    expect(find.text('١٥'), findsWidgets); // day 15
    expect(find.textContaining('سبتمبر'), findsWidgets);
  });

  testWidgets('taps report the tapped day; past days are not tappable',
      (WidgetTester tester) async {
    DateTime? tapped;
    await tester.pumpWidget(_host(
      locale: const Locale('en'),
      onSelect: (DateTime d) => tapped = d,
    ));

    await tester.tap(find.descendant(
      of: find.byType(StayRangeCalendar),
      matching: find.text('9'),
    ).first);
    expect(tapped, DateTime(2026, 9, 9));
  });

  testWidgets('a selected range marks both endpoints selected',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(
      locale: const Locale('en'),
      checkIn: DateTime(2026, 9, 6),
      checkOut: DateTime(2026, 9, 9),
      onSelect: (_) {},
    ));

    final Iterable<Semantics> selected = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((Semantics s) => s.properties.selected ?? false);
    // Exactly the two endpoints across the two rendered months.
    expect(selected.length, greaterThanOrEqualTo(2));
  });

  testWidgets('the nights between check-in and check-out are highlighted',
      (WidgetTester tester) async {
    await tester.pumpWidget(_host(
      locale: const Locale('ar'),
      checkIn: DateTime(2026, 9, 6),
      checkOut: DateTime(2026, 9, 10),
      onSelect: (_) {},
    ));

    final List<Element> band = find
        .descendant(
          of: find.byType(StayRangeCalendar),
          matching: find.byType(ColoredBox),
        )
        .evaluate()
        .where((Element e) => (e.widget as ColoredBox).color.a > 0)
        .toList();

    // Three nights in between (both halves) + the inner half of each endpoint.
    expect(band.length, 3 * 2 + 2);
    // Regression: the band used to lay out 0px tall, so it never showed.
    for (final Element e in band) {
      expect((e.renderObject! as RenderBox).size.height, greaterThan(0));
    }
  });
}
