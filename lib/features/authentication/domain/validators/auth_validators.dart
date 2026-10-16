import '../../../../core/localization/latin_digits.dart';
import '../entities/guest_phone.dart';

/// Local, user-experience validation for the authentication forms.
///
/// These checks only decide whether it is worth sending a request — the backend
/// stays authoritative (architecture.md §6). Each result is an enum so the
/// presentation layer picks the localized message; validators never build user
/// copy themselves (coding_rules.md §8).
abstract final class AuthValidators {
  const AuthValidators._();

  static PhoneInputError? phone(GuestPhone phone) {
    if (phone.nationalNumber.isEmpty) return PhoneInputError.empty;
    return phone.isValid ? null : PhoneInputError.invalid;
  }

  /// A Saudi mobile number: `5` + 8 digits once the trunk zero and any
  /// country code are removed, so `05 1234 5678`, `5 1234 5678`,
  /// `+966 5 1234 5678` and the same in Arabic-Indic digits are all accepted.
  static PhoneInputError? saudiPhone(String rawNationalNumber) {
    if (toLatinDigits(rawNationalNumber).replaceAll(RegExp(r'[^0-9]'), '').isEmpty) {
      return PhoneInputError.empty;
    }
    return RegExp(r'^5\d{8}$').hasMatch(GuestPhone.nationalDigits(rawNationalNumber))
        ? null
        : PhoneInputError.invalid;
  }

  static NameInputError? fullName(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return NameInputError.empty;
    // A name needs at least two words to plausibly match an ID document.
    if (trimmed.split(RegExp(r'\s+')).length < 2) return NameInputError.tooShort;
    return null;
  }

  static EmailInputError? email(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return EmailInputError.empty;
    final RegExp pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return pattern.hasMatch(trimmed) ? null : EmailInputError.invalid;
  }

  /// Whether [code] is shaped like an [length]-digit OTP. Correctness of the
  /// code is decided by verification, not here.
  static bool isOtpFormatValid(String code, {required int length}) {
    return RegExp('^[0-9]{$length}\$').hasMatch(code);
  }
}

enum PhoneInputError { empty, invalid }

enum NameInputError { empty, tooShort }

enum EmailInputError { empty, invalid }
