import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/authentication/domain/entities/guest_phone.dart';

void main() {
  group('GuestPhone.fromInput', () {
    test('strips spaces, dashes and a single leading zero', () {
      final GuestPhone phone =
          GuestPhone.fromInput(rawNationalNumber: '0 51-234 5678');
      expect(phone.nationalNumber, '512345678');
      expect(phone.dialCode, '+966');
    });

    test('accepts Arabic-Indic digits and a pasted country code', () {
      for (final String typed in <String>[
        '٠٥١٢٣٤٥٦٧٨',
        '+966 51 234 5678',
        '00966512345678',
        '966512345678',
        '512345678',
      ]) {
        expect(
          GuestPhone.fromInput(rawNationalNumber: typed).e164,
          '+966512345678',
          reason: typed,
        );
      }
    });

    test('keeps the default dialling code', () {
      expect(
        GuestPhone.fromInput(rawNationalNumber: '512345678').e164,
        '+966512345678',
      );
    });
  });

  group('validity', () {
    test('accepts a plausible national number', () {
      expect(
        const GuestPhone(dialCode: '+966', nationalNumber: '512345678').isValid,
        isTrue,
      );
    });

    test('rejects too-short and non-numeric input', () {
      expect(
        const GuestPhone(dialCode: '+966', nationalNumber: '123').isValid,
        isFalse,
      );
      expect(
        const GuestPhone(dialCode: '966', nationalNumber: '512345678').isValid,
        isFalse,
      );
    });
  });

  test('display groups the national digits and stays LTR-friendly', () {
    const GuestPhone phone =
        GuestPhone(dialCode: '+966', nationalNumber: '512345678');
    expect(phone.display, '+966 51 234 5678');
  });

  test('value equality', () {
    expect(
      const GuestPhone(dialCode: '+966', nationalNumber: '512345678'),
      const GuestPhone(dialCode: '+966', nationalNumber: '512345678'),
    );
  });
}
