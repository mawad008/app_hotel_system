import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';

import '../../support/pump_app.dart';

Future<AppLocalizations> _openPhone(WidgetTester tester) async {
  await pumpSignIn(tester);
  return tester.l10n();
}

void main() {
  testWidgets('renders the heading, helper and terms', (WidgetTester tester) async {
    final AppLocalizations en = await _openPhone(tester);
    expect(find.text(en.authPhoneHeading), findsOneWidget);
    expect(find.text(en.authPhoneHelper), findsOneWidget);
    expect(find.text(en.authPhoneTerms), findsOneWidget);
  });

  testWidgets('submitting an empty number surfaces a validation message',
      (WidgetTester tester) async {
    final AppLocalizations en = await _openPhone(tester);

    await tester.tap(find.text(en.authPhoneSubmit));
    await tester.pump();

    expect(find.text(en.authPhoneEmpty), findsOneWidget);
    expect(find.text(en.authOtpHeading), findsNothing);
  });

  testWidgets('an invalid number shows a validation message and stays put',
      (WidgetTester tester) async {
    final AppLocalizations en = await _openPhone(tester);

    await tester.enterText(find.byType(TextField), '12');
    await tester.pump();
    await tester.tap(find.text(en.authPhoneSubmit));
    await tester.pump();

    expect(find.text(en.authPhoneInvalid), findsOneWidget);
    expect(find.text(en.authOtpHeading), findsNothing);
  });

  testWidgets('a valid number advances to the OTP screen',
      (WidgetTester tester) async {
    final AppLocalizations en = await _openPhone(tester);

    await tester.enterText(find.byType(TextField), '0512345678');
    await tester.pump();
    await tester.tap(find.text(en.authPhoneSubmit));
    await tester.pumpAndSettle();

    expect(find.text(en.authOtpHeading), findsOneWidget);
  });
}
