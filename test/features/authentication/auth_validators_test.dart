import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/authentication/domain/entities/guest_phone.dart';
import 'package:hotel_guest_app/features/authentication/domain/validators/auth_validators.dart';

void main() {
  group('phone', () {
    test('empty → empty error', () {
      expect(
        AuthValidators.phone(
          GuestPhone.fromInput(rawNationalNumber: ''),
        ),
        PhoneInputError.empty,
      );
    });

    test('too short → invalid error', () {
      expect(
        AuthValidators.phone(
          GuestPhone.fromInput(rawNationalNumber: '123'),
        ),
        PhoneInputError.invalid,
      );
    });

    test('well-formed → no error', () {
      expect(
        AuthValidators.phone(
          GuestPhone.fromInput(rawNationalNumber: '512345678'),
        ),
        isNull,
      );
    });
  });

  group('saudi phone', () {
    test('accepts the usual ways of typing a Saudi mobile number', () {
      for (final String typed in <String>[
        '0512345678',
        '05 1234 5678',
        '512345678',
        '٠٥١٢٣٤٥٦٧٨',
        '+966 51 234 5678',
        '00966512345678',
      ]) {
        expect(AuthValidators.saudiPhone(typed), isNull, reason: typed);
      }
    });

    test('rejects numbers that are not Saudi mobiles', () {
      for (final String typed in <String>[
        '0612345678', // not a mobile prefix
        '051234567', // one digit short
        '05123456789', // one digit long
        '12',
      ]) {
        expect(
          AuthValidators.saudiPhone(typed),
          PhoneInputError.invalid,
          reason: typed,
        );
      }
    });

    test('empty or digit-free input is reported as empty', () {
      expect(AuthValidators.saudiPhone(''), PhoneInputError.empty);
      expect(AuthValidators.saudiPhone(' - '), PhoneInputError.empty);
    });
  });

  group('full name', () {
    test('empty → empty error', () {
      expect(AuthValidators.fullName('   '), NameInputError.empty);
    });

    test('single word → tooShort error', () {
      expect(AuthValidators.fullName('Mahmoud'), NameInputError.tooShort);
    });

    test('two words → no error', () {
      expect(AuthValidators.fullName('Mahmoud Nabil'), isNull);
    });
  });

  group('email', () {
    test('empty → empty error', () {
      expect(AuthValidators.email(''), EmailInputError.empty);
    });

    test('malformed → invalid error', () {
      expect(AuthValidators.email('not-an-email'), EmailInputError.invalid);
      expect(AuthValidators.email('a@b'), EmailInputError.invalid);
    });

    test('valid → no error', () {
      expect(AuthValidators.email('name@example.com'), isNull);
    });
  });

  group('otp format', () {
    test('only an exact-length digit string is valid', () {
      expect(AuthValidators.isOtpFormatValid('123456', length: 6), isTrue);
      expect(AuthValidators.isOtpFormatValid('12345', length: 6), isFalse);
      expect(AuthValidators.isOtpFormatValid('12345a', length: 6), isFalse);
      expect(AuthValidators.isOtpFormatValid('1234567', length: 6), isFalse);
    });
  });
}
