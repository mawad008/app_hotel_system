import 'package:flutter/material.dart';

/// Type scale for the Guest App — the Figma `Typography` collection + the
/// `text/ar/*`, `text/en/*`, `text/num/*` styles (`design-system-tokens.md` §6).
///
/// ## Font
///
/// **Tajawal** for the whole UI — the approved font (decision 2026-09-26:
/// Tajawal only). The v2 Figma library names another Arabic family; that is a
/// documented design-file deviation, not a pending swap.
///
/// The design system also specifies `font/family/latin
/// = Inter` and `font/family/mono = Google Sans Code`; both are **accepted
/// deviations** here — Latin copy in this RTL app is minimal (wordmark, codes)
/// and Tajawal carries a complete Latin set plus tabular figures, so a
/// second/third family isn't worth the weight. The `num*` ramp therefore uses
/// Tajawal with `FontFeature.tabularFigures()`.
///
/// ## Rules (from the design system)
///
/// * **No `letterSpacing`, ever** — Arabic is cursive; tracking breaks the
///   joins. Every style ships at 0 (no exceptions, including numerals).
/// * Line-heights are the **Arabic** values (`/line` column) — Arabic needs
///   extra leading to clear diacritics. The `/line-en` variants are intentionally
///   unused (Tajawal-only).
/// * Tajawal has no Semi Bold: the Arabic weight ladder is
///   ExtraBold / Bold / Medium / Regular, so `w600` collapses to `bold`.
/// * Widgets read from `Theme.of(context).textTheme` or the helpers below —
///   never inline `TextStyle(fontFamily: ...)`.
abstract final class AppTypography {
  /// The bundled family (see `pubspec.yaml`). Applied globally through
  /// [ThemeData.fontFamily] so it also reaches Material-internal text.
  static const String fontFamily = 'Tajawal';

  /// Fallback chain — Tajawal covers both scripts, so nothing normally resolves
  /// here; kept for symmetry with call sites.
  static const List<String> fontFamilyFallback = <String>['Tajawal'];

  /// Weight tokens. `semiBold` maps to `w700` — Tajawal ships no 600.
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w700;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  static TextStyle _base(
    double size,
    FontWeight weight, {
    required double height,
    Color? color,
    List<FontFeature>? features,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
      letterSpacing: 0,
      fontFeatures: features,
    );
  }

  static const List<FontFeature> _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  /// The Material [TextTheme]. `primary` colours headings + primary body;
  /// `secondary` colours the muted body/label slots.
  ///
  /// Slot → Figma style (`design-system-tokens.md` §6.3):
  ///
  /// | slot | Figma | size / line |
  /// |---|---|---|
  /// | displayLarge  | display-xl | 44 / 56 |
  /// | displayMedium | display-lg | 32 / 44 |
  /// | displaySmall / headlineLarge | display | 28 / 40 |
  /// | headlineMedium | title-lg | 24 / 36 |
  /// | headlineSmall | title | 20 / 32 |
  /// | titleLarge | headline | 18 / 28 |
  /// | titleMedium | body-lg strong | 17 / 28 |
  /// | titleSmall | body strong | 15 / 26 |
  /// | bodyLarge | body-lg | 17 / 28 |
  /// | bodyMedium | body | 15 / 26 |
  /// | bodySmall | body-sm | 14 / 24 |
  /// | labelLarge | body-sm strong | 14 / 22 |
  /// | labelMedium | label | 13 / 20 |
  /// | labelSmall | caption | 12 / 18 |
  static TextTheme textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: _base(44, extraBold, height: 56 / 44, color: primary),
      displayMedium: _base(32, extraBold, height: 44 / 32, color: primary),
      displaySmall: _base(28, extraBold, height: 40 / 28, color: primary),
      headlineLarge: _base(28, extraBold, height: 40 / 28, color: primary),
      headlineMedium: _base(24, bold, height: 36 / 24, color: primary),
      headlineSmall: _base(20, bold, height: 32 / 20, color: primary),
      titleLarge: _base(18, bold, height: 28 / 18, color: primary),
      titleMedium: _base(17, bold, height: 28 / 17, color: primary),
      titleSmall: _base(15, bold, height: 26 / 15, color: primary),
      bodyLarge: _base(17, regular, height: 28 / 17, color: primary),
      bodyMedium: _base(15, regular, height: 26 / 15, color: secondary),
      bodySmall: _base(14, regular, height: 24 / 14, color: secondary),
      labelLarge: _base(14, bold, height: 22 / 14, color: primary),
      labelMedium: _base(13, medium, height: 20 / 13, color: secondary),
      labelSmall: _base(12, regular, height: 18 / 12, color: secondary),
    );
  }

  // ── `*-strong` / `*-regular` overrides (not part of TextTheme) ────────────

  /// `text/*/body-strong` — 15 / 24, Bold. Emphasised inline body.
  static TextStyle bodyStrong(Color color) =>
      _base(15, bold, height: 24 / 15, color: color);

  /// `text/*/body-sm-strong` — 14 / 22, Bold.
  static TextStyle bodySmStrong(Color color) =>
      _base(14, bold, height: 22 / 14, color: color);

  /// `text/*/label-strong` — 13 / 18, Bold.
  static TextStyle labelStrong(Color color) =>
      _base(13, bold, height: 18 / 13, color: color);

  /// Button label, `Size=Large` — 16 / 20, Medium (v2: was Bold).
  static TextStyle buttonLarge(Color? color) =>
      _base(16, medium, height: 20 / 16, color: color);

  /// Button label, `Size=Medium` / `Small` — 14 / 18, Medium (v2: was 15 Bold).
  static TextStyle button(Color? color) =>
      _base(14, medium, height: 18 / 14, color: color);

  /// `text/*/label-regular` — 13 / 18, Regular. De-emphasised label.
  static TextStyle labelRegular(Color color) =>
      _base(13, regular, height: 18 / 13, color: color);

  // ── `text/num/*` — tabular figures (room numbers, amounts, codes, points) ──

  static TextStyle numDisplay(Color color) =>
      _base(64, bold, height: 68 / 64, color: color, features: _tabular);
  static TextStyle numXl(Color color) =>
      _base(30, bold, height: 36 / 30, color: color, features: _tabular);
  static TextStyle numLg(Color color) =>
      _base(24, medium, height: 30 / 24, color: color, features: _tabular);
  static TextStyle numMd(Color color, {double size = 17}) =>
      _base(size, medium, height: 24 / 17, color: color, features: _tabular);
  static TextStyle numSm(Color color) =>
      _base(15, medium, height: 22 / 15, color: color, features: _tabular);
  static TextStyle numXs(Color color) =>
      _base(12, medium, height: 16 / 12, color: color, features: _tabular);

  /// Price / money style — tabular figures. Pair with `MoneyText`.
  /// Thin wrapper over [numMd] kept for its historical call sites.
  static TextStyle price(Color color, {double size = 17}) =>
      numMd(color, size: size);
}
