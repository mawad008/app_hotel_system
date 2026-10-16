import 'package:flutter/services.dart';

import '../localization/latin_digits.dart';

/// Applies [toLatinDigits] while the user types, so digits from an Arabic
/// keyboard are kept instead of being dropped by a digits-only filter such as
/// [FilteringTextInputFormatter.digitsOnly]. Put it first in a field's
/// `inputFormatters`.
///
/// Every converted digit is a single UTF-16 unit, like the one it replaces,
/// so the selection and composing ranges stay valid unchanged.
class LatinDigitsFormatter extends TextInputFormatter {
  const LatinDigitsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = toLatinDigits(newValue.text);
    return identical(text, newValue.text)
        ? newValue
        : newValue.copyWith(text: text);
  }
}
