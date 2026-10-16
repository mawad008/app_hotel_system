/// Converts Arabic-Indic (`٠`–`٩`) and Extended Arabic-Indic / Persian
/// (`۰`–`۹`) digits to `0`–`9`, leaving every other character as it is.
///
/// Arabic keyboards — the default on many phones in Saudi Arabia — type
/// Arabic-Indic digits, while the API and the validators only understand
/// `0`–`9`. Returns [input] itself when there is nothing to convert.
String toLatinDigits(String input) {
  StringBuffer? out;
  for (int i = 0; i < input.length; i++) {
    final int unit = input.codeUnitAt(i);
    final int? latin = switch (unit) {
      >= 0x0660 && <= 0x0669 => 0x30 + unit - 0x0660,
      >= 0x06F0 && <= 0x06F9 => 0x30 + unit - 0x06F0,
      _ => null,
    };
    if (latin != null) {
      out ??= StringBuffer(input.substring(0, i));
      out.writeCharCode(latin);
    } else {
      out?.writeCharCode(unit);
    }
  }
  return out?.toString() ?? input;
}
