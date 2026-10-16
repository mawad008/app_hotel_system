import 'package:flutter/services.dart';

bool _loaded = false;

/// Loads the app's real Tajawal font into the test engine.
///
/// Tests otherwise render text in the square-glyph test font, which is far
/// wider than Tajawal — fine for logic tests, but layout checks at a real
/// phone width (overflow, safe area) need real text metrics.
Future<void> loadAppFonts() async {
  if (_loaded) return;
  final FontLoader tajawal = FontLoader('Tajawal');
  for (final String weight in <String>[
    'Light',
    'Regular',
    'Medium',
    'Bold',
    'ExtraBold',
  ]) {
    tajawal.addFont(rootBundle.load('assets/fonts/Tajawal-$weight.ttf'));
  }
  await tajawal.load();
  _loaded = true;
}
