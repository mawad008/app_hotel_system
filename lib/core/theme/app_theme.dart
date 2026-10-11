import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_sizes.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds the light and dark [ThemeData] for the Guest App from the design
/// tokens (`mobile/docs/design-system-tokens.md`). Single source of truth for
/// visual styling — widgets must not define their own colours or text styles.
///
/// Colour comes from [AppColorTokens] (registered as a [ThemeExtension] and read
/// via `context.colors`); the [ColorScheme] mirrors the subset Material's own
/// widgets consume. Both modes are fully specified in the Figma.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  /// [light] recoloured with the hotel's dashboard-managed brand colour
  /// (`primary_color`); `null` = the built-in palette.
  static ThemeData lightBranded(Color? brand) =>
      brand == null ? light : _build(Brightness.light, brand: brand);

  static ThemeData _build(Brightness brightness, {Color? brand}) {
    final bool isDark = brightness == Brightness.dark;
    final AppColorTokens base = AppColorTokens.of(brightness);
    final AppColorTokens c = brand == null ? base : _withBrand(base, brand);

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: c.bgPrimary,
      onPrimary: c.textOnPrimary,
      secondary: c.accentWarm,
      onSecondary: isDark ? AppPrimitives.stone900 : AppPrimitives.white,
      surface: c.bgSurface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerHighest: c.bgSubtle,
      error: c.errorFg,
      onError: AppPrimitives.white,
      errorContainer: c.errorBg,
      onErrorContainer: c.errorFg,
      outline: c.borderDefault,
      outlineVariant: c.bgSubtle,
    );

    final TextTheme textTheme = AppTypography.textTheme(
      c.textPrimary,
      c.textSecondary,
    );

    /// Secondary-button fill — transparent on light (v2 `Variant=Secondary`:
    /// no fill, 1.5px `border/accent-subtle` outline); a raised surface on dark.
    final Color secondaryFill = isDark ? c.bgSurfaceRaised : Colors.transparent;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bgCanvas,
      textTheme: textTheme,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      extensions: <ThemeExtension<dynamic>>[
        c,
        isDark ? AppSemanticColors.dark : AppSemanticColors.light,
      ],

      // ── App bar ──────────────────────────────────────────────────────────
      // Flat, background-aware, centred title, no Material tint/elevation.
      appBarTheme: AppBarTheme(
        backgroundColor: c.bgCanvas,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        // v2 `App Bar`: title 18 Medium (was Bold).
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: AppTypography.medium,
        ),
        foregroundColor: c.textPrimary,
        iconTheme: IconThemeData(
          color: c.textPrimary,
          size: AppIconSizes.appBar,
        ),
      ),

      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: c.bgSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allCard),
      ),

      dividerTheme: DividerThemeData(
        color: c.borderDefault,
        thickness: 1,
        space: AppSpacing.space4,
      ),

      // ── Inputs ───────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.bgSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.allInput,
          borderSide: BorderSide(color: c.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.allInput,
          borderSide: BorderSide(color: c.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.allInput,
          borderSide: BorderSide(color: c.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.allInput,
          borderSide: BorderSide(color: c.errorFg),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.allInput,
          borderSide: BorderSide(color: c.errorFg, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: c.textPlaceholder),
        labelStyle: textTheme.bodyMedium,
      ),

      // ── Buttons ──────────────────────────────────────────────────────────
      // Full-width pill CTAs (radius 999, Figma `Button` component). The
      // composed widgets (PrimaryButton / SecondaryButton / DangerButton) take a
      // `size` for the Small 40 / Medium 48 / Large 56 axis. The standing
      // full-width height is Medium 48 — the v2 `Page Footer` primary action —
      // with the 14 Medium label.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.bgPrimary,
          foregroundColor: c.textOnPrimary,
          disabledBackgroundColor: c.bgDisabled,
          disabledForegroundColor: c.textDisabled,
          minimumSize: const Size.fromHeight(AppSizes.buttonMedium),
          textStyle: AppTypography.button(null),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allPill),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textAccent,
          backgroundColor: secondaryFill,
          disabledForegroundColor: c.textDisabled,
          minimumSize: const Size.fromHeight(AppSizes.buttonMedium),
          textStyle: AppTypography.button(null),
          side: BorderSide(color: c.borderAccentSubtle, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allPill),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.textAccent,
          textStyle: AppTypography.button(null),
        ),
      ),

      // ── Chips ────────────────────────────────────────────────────────────
      // Primary-filled (v2 near-black) when selected, white pill with a hairline
      // when not.
      chipTheme: ChipThemeData(
        backgroundColor: c.bgSurface,
        selectedColor: c.bgPrimary,
        checkmarkColor: c.textOnPrimary,
        showCheckmark: false,
        side: BorderSide(color: c.borderDefault),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelLarge?.copyWith(color: c.textPrimary),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: c.textOnPrimary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space2,
        ),
        elevation: 0,
        pressElevation: 0,
      ),

      // ── Toggle (Figma `Toggle` component) ────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          if (s.contains(WidgetState.disabled)) return c.textDisabled;
          return AppPrimitives.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          if (s.contains(WidgetState.disabled)) return c.bgDisabled;
          if (s.contains(WidgetState.selected)) return c.bgPrimary;
          return c.borderStrong;
        }),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
      ),

      // ── Bottom sheets ────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.bgSurface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.bgSurface,
        showDragHandle: true,
        dragHandleColor: c.borderStrong,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.topSheet),
      ),

      // ── Bottom navigation (Figma's persistent 4-tab bar) ─────────────────
      // v2 `Tab Bar`: 12px labels — selected Medium in text-primary, the rest
      // Regular in text-secondary.
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: c.bgSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: AppIconSizes.nav,
            color: selected ? c.textPrimary : c.textSecondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
          final bool selected = s.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? c.textPrimary : c.textSecondary,
            fontWeight: selected ? AppTypography.medium : AppTypography.regular,
          );
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.bgInverse,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: c.textOnInverse,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.bgPrimary),
    );
  }

  /// The primary-action tokens re-pointed at [brand]: fill, hover/pressed
  /// (8% / 16% darker), focus ring, and a readable label (near-black on a
  /// light brand colour, white otherwise).
  static AppColorTokens _withBrand(AppColorTokens c, Color brand) {
    final bool lightBrand = brand.computeLuminance() > 0.4;
    return c.copyWith(
      bgPrimary: brand,
      bgPrimaryHover: Color.lerp(brand, const Color(0xFF000000), 0.08),
      bgPrimaryPressed: Color.lerp(brand, const Color(0xFF000000), 0.16),
      textOnPrimary: lightBrand ? AppPrimitives.stone950 : AppPrimitives.white,
      borderFocus: brand,
    );
  }
}
