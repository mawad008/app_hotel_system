import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/theme/app_theme.dart';
import 'package:hotel_guest_app/core/widgets/money_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment.dart';
import 'package:hotel_guest_app/features/payment/presentation/widgets/payment_summary_card.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';

import 'payment_test_support.dart';

Future<AppLocalizations> _pump(WidgetTester tester, Reservation reservation) async {
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: PaymentSummaryCard(
          reservation: reservation,
          payment: Payment.none(
            reservationId: reservation.id,
            hotelId: reservation.hotelId,
            amount: const Money(amount: 0, currency: 'SAR'),
          ),
        ),
      ),
    ),
  ));
  return AppLocalizations.of(tester.element(find.byType(PaymentSummaryCard)));
}

/// The amount shown on the breakdown line labelled [label].
num? _amountOn(WidgetTester tester, String label) {
  final Finder row = find.ancestor(of: find.text(label), matching: find.byType(Row)).first;
  final Finder money = find.descendant(of: row, matching: find.byType(MoneyText));
  return money.evaluate().isEmpty ? null : tester.widget<MoneyText>(money.first).amount;
}

void main() {
  testWidgets('shows rate, nights, subtotal, taxes, service fee, total and deposit separately',
      (WidgetTester tester) async {
    final AppLocalizations l10n = await _pump(
      tester,
      fakeReservation(
        amount: 900,
        nightlyRate: 450,
        serviceFee: 45,
        depositAmount: 270,
        pricesIncludeTaxes: false,
      ),
    );

    expect(find.text(l10n.paymentBreakdownHeading), findsOneWidget);
    expect(_amountOn(tester, l10n.roomNightlyPriceLabel), 450);
    expect(find.text(l10n.stayNights(2)), findsOneWidget);
    expect(_amountOn(tester, l10n.bookingRoomSubtotal), 900);
    expect(_amountOn(tester, l10n.roomTaxesLabel), 0);
    expect(_amountOn(tester, l10n.bookingServiceFee), 45);
    expect(_amountOn(tester, l10n.paymentBookingTotalLabel), 945);
    expect(find.text(l10n.paymentDepositHint), findsOneWidget);
    expect(find.text(l10n.reviewRoomLabel), findsOneWidget);
  });

  testWidgets('taxes read "included" when the hotel rate includes them; no fee shows zero',
      (WidgetTester tester) async {
    final AppLocalizations l10n = await _pump(
      tester,
      fakeReservation(amount: 900, depositAmount: 270, pricesIncludeTaxes: true),
    );

    expect(_amountOn(tester, l10n.roomTaxesLabel), isNull);
    expect(find.text(l10n.roomPriceIncludedValue), findsOneWidget);
    expect(_amountOn(tester, l10n.bookingServiceFee), 0);
    expect(_amountOn(tester, l10n.paymentBookingTotalLabel), 900);
  });

  testWidgets('hides the tax line when the backend did not say', (WidgetTester tester) async {
    final AppLocalizations l10n = await _pump(tester, fakeReservation(depositAmount: 270));
    expect(find.text(l10n.roomTaxesLabel), findsNothing);
  });
}
