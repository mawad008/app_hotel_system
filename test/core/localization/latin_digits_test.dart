import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/localization/latin_digits.dart';
import 'package:hotel_guest_app/core/presentation/latin_digits_formatter.dart';

void main() {
  group('toLatinDigits', () {
    test('converts Arabic-Indic and Persian digits', () {
      expect(toLatinDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
      expect(toLatinDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
    });

    test('leaves letters, Latin digits and separators alone', () {
      expect(toLatinDigits('رقم ٠٥ 12-34'), 'رقم 05 12-34');
    });

    test('returns the same instance when there is nothing to convert', () {
      const String input = 'A1 b2';
      expect(identical(toLatinDigits(input), input), isTrue);
    });
  });

  test('LatinDigitsFormatter keeps the selection where it was', () {
    const LatinDigitsFormatter formatter = LatinDigitsFormatter();
    final TextEditingValue out = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '٠٥١',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    expect(out.text, '051');
    expect(out.selection, const TextSelection.collapsed(offset: 2));
  });
}
