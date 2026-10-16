import '../../../../core/localization/latin_digits.dart';

/// A guest mobile number split into its dialling code and national part.
///
/// The approved SRS (§3.1) and the `09 · Authentication` reference show a fixed
/// `+966` country selector with a locally-entered national number. The backend
/// authentication contract for phone formatting is not approved yet, so this
/// value object only does the minimum, format-level checks needed for a good
/// user experience — the backend stays authoritative for whether a number can
/// actually receive a code.
class GuestPhone {
  const GuestPhone({required this.dialCode, required this.nationalNumber});

  /// E.164 dialling code including the leading `+`, e.g. `+966`.
  final String dialCode;

  /// Digits the guest typed, without spaces or a leading zero.
  final String nationalNumber;

  /// Default dialling code shown in the UI (`09 · Authentication`).
  static const String defaultDialCode = '+966';

  /// Builds a phone from raw field input — see [nationalDigits] for what is
  /// accepted.
  factory GuestPhone.fromInput({
    String dialCode = defaultDialCode,
    required String rawNationalNumber,
  }) {
    return GuestPhone(
      dialCode: dialCode,
      nationalNumber: nationalDigits(rawNationalNumber, dialCode: dialCode),
    );
  }

  /// The national part of what a guest typed or pasted: Arabic-Indic digits
  /// become `0`–`9`, spaces, dashes and `+` are dropped, the country code is
  /// removed when it was included (`+966 5…`, `00966 5…`, `966 5…`), and so is
  /// a single trunk zero (`05…` → `5…`).
  static String nationalDigits(
    String raw, {
    String dialCode = defaultDialCode,
  }) {
    String digits = toLatinDigits(raw).replaceAll(RegExp(r'[^0-9]'), '');
    final String country = dialCode.replaceAll(RegExp(r'[^0-9]'), '');
    if (country.isNotEmpty) {
      for (final String prefix in <String>['00$country', country]) {
        // Only when a full national number follows, so a national number
        // that merely starts with the same digits is left alone.
        if (digits.startsWith(prefix) && digits.length - prefix.length >= 8) {
          digits = digits.substring(prefix.length);
          break;
        }
      }
    }
    return digits.startsWith('0') ? digits.substring(1) : digits;
  }

  /// Best-effort split of a canonical E.164 string back into a dialling code
  /// and national number — used when restoring a session from the backend
  /// (`GET /guest/auth/me` returns only the combined `phone`). Recognises the
  /// GCC + a few common codes; otherwise assumes a 3-digit code.
  factory GuestPhone.fromE164(String e164) {
    final String digits = e164.replaceAll(RegExp(r'[^0-9]'), '');
    for (final String cc in <String>['966', '971', '973', '974', '965', '968', '20', '1']) {
      if (digits.startsWith(cc)) {
        return GuestPhone(dialCode: '+$cc', nationalNumber: digits.substring(cc.length));
      }
    }
    final int split = digits.length >= 3 ? 3 : 0;
    return GuestPhone(
      dialCode: '+${digits.substring(0, split)}',
      nationalNumber: digits.substring(split),
    );
  }

  /// `true` when the number looks well-formed enough to send to the backend:
  /// a `+` dialling code and 6–14 national digits.
  bool get isValid {
    final bool dialOk = RegExp(r'^\+\d{1,4}$').hasMatch(dialCode);
    final bool nationalOk = RegExp(r'^\d{6,14}$').hasMatch(nationalNumber);
    return dialOk && nationalOk;
  }

  /// Canonical E.164 string, e.g. `+96651234567`.
  String get e164 => '$dialCode$nationalNumber';

  /// Human-friendly form for headers and banners, e.g. `+966 51 234 567`.
  String get display {
    final StringBuffer buffer = StringBuffer(dialCode)..write(' ');
    for (int i = 0; i < nationalNumber.length; i++) {
      if (i == 2 || i == 5) buffer.write(' ');
      buffer.write(nationalNumber[i]);
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      other is GuestPhone &&
      other.dialCode == dialCode &&
      other.nationalNumber == nationalNumber;

  @override
  int get hashCode => Object.hash(dialCode, nationalNumber);

  @override
  String toString() => 'GuestPhone($e164)';
}
