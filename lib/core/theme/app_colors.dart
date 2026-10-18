import 'package:flutter/material.dart';

/// Colour tokens for the Hotel Guest App.
///
/// Three layers, mirroring `mobile/Design/Hotel Design System.fig` exactly
/// (extracted verbatim in `mobile/docs/design-system-tokens.md`):
///
/// 1. [AppPrimitives] — the raw ramps (`oud`, `gold`, `stone`, `ink` + state
///    hues). Never referenced by widgets; the Figma `Primitives` collection is
///    scope-hidden for the same reason.
/// 2. [AppColorTokens] — the semantic layer (`color/bg|text|border|state|accent/*`),
///    resolved per [Brightness]. A [ThemeExtension]; widgets read it through
///    `context.colors` (see [AppColorTokensX]).
/// 3. [AppColors] / [AppSemanticColors] — **deprecated** compatibility shims that
///    keep pre-token call sites compiling while they migrate to `context.colors`.
///
/// This is the only place literal colours are allowed
/// (`mobile/docs/architecture.md` §9, `mobile/docs/coding_rules.md` §8).

// ─────────────────────────────────────────────────────────────────────────────
// 1. Primitives — raw ramps (design-system-tokens.md §2). Internal.
// ─────────────────────────────────────────────────────────────────────────────

/// Raw colour ramps. Bind components to [AppColorTokens], never to these — they
/// exist only so the semantic layer has a single source for every hue.
abstract final class AppPrimitives {
  // oud — warm brown. Since the v2 library (2026-09-23) it no longer drives the
  // primary action (now `ink/950`); it survives in the subtle/focus/hover slots.
  static const Color oud50 = Color(0xFFF8F1EC);
  static const Color oud100 = Color(0xFFEDDCD0);
  static const Color oud200 = Color(0xFFDBBCA6);
  static const Color oud300 = Color(0xFFC2977A);
  static const Color oud400 = Color(0xFFA5765A);
  static const Color oud500 = Color(0xFF855A42);
  static const Color oud600 = Color(0xFF6B4632);
  static const Color oud700 = Color(0xFF513425);
  static const Color oud900 = Color(0xFF241610);

  // gold — accent
  static const Color gold25 = Color(0xFFFAF7F0);
  static const Color gold100 = Color(0xFFEEE0C0);
  static const Color gold200 = Color(0xFFE2CB98);
  static const Color gold300 = Color(0xFFD2AE65);
  static const Color gold400 = Color(0xFFBF933C);
  static const Color gold500 = Color(0xFFA17A2D);
  static const Color gold600 = Color(0xFF836324);
  static const Color gold700 = Color(0xFF654C1C);
  static const Color gold800 = Color(0xFF493715);
  static const Color gold900 = Color(0xFF2C210C);

  // stone — neutral (light ground)
  static const Color stone0 = Color(0xFFFFFFFF);
  static const Color stone50 = Color(0xFFF7F4EF);
  static const Color stone100 = Color(0xFFEFEBE4);
  static const Color stone200 = Color(0xFFE5E0D7);
  static const Color stone300 = Color(0xFFCEC8BC);
  static const Color stone400 = Color(0xFFA49D8F);
  static const Color stone500 = Color(0xFF736C5F);
  static const Color stone600 = Color(0xFF5A544A);
  static const Color stone700 = Color(0xFF443F37);
  static const Color stone800 = Color(0xFF2E2A24);
  static const Color stone900 = Color(0xFF1D1A16);
  static const Color stone950 = Color(0xFF110F0C);

  // ink — near-black neutrals: the v2 primary action + inverse surfaces, and the
  // dark-mode ground.
  static const Color ink50 = Color(0xFFF2EFE9);
  static const Color ink100 = Color(0xFFE9E5DF);
  static const Color ink300 = Color(0xFFCAC4BB);
  static const Color ink700 = Color(0xFF38312B);
  static const Color ink800 = Color(0xFF241F1B);
  static const Color ink900 = Color(0xFF171412);
  static const Color ink950 = Color(0xFF0E0C0A);

  // state hues — only the steps the design system defines
  static const Color green50 = Color(0xFFEAF3EF);
  static const Color green200 = Color(0xFFA9CFBD);
  static const Color green500 = Color(0xFF2F7D62);
  static const Color green600 = Color(0xFF256349);
  static const Color green900 = Color(0xFF14261C);

  static const Color amber50 = Color(0xFFF9F1E4);
  static const Color amber200 = Color(0xFFE4CDA3);
  static const Color amber500 = Color(0xFFC58A32);
  static const Color amber600 = Color(0xFF8A5F1E);
  static const Color amber900 = Color(0xFF2A2113);

  static const Color red50 = Color(0xFFFAEBEB);
  static const Color red200 = Color(0xFFE8B9B9);
  static const Color red500 = Color(0xFFC65454);
  static const Color red600 = Color(0xFFA33A3A);
  static const Color red700 = Color(0xFF8A3131);
  static const Color red800 = Color(0xFF6E2727);
  static const Color red900 = Color(0xFF2B1713);

  static const Color blue50 = Color(0xFFEAF1F5);
  static const Color blue200 = Color(0xFFB3CBD8);
  static const Color blue500 = Color(0xFF397A9B);
  static const Color blue600 = Color(0xFF2C6079);
  static const Color blue900 = Color(0xFF14212D);

  /// Pure white — a genuine literal (on-primary text, ink on inverse cards).
  static const Color white = Color(0xFFFFFFFF);

  /// `#2D264B` — the v2 Figma overrides every status badge's small icon
  /// (shield-tick / check in "متاحة", "مؤكد", booking & payment pills) to
  /// this dark indigo, while the badge label keeps its state colour. Light
  /// theme only; on dark the icon follows the label. Not in the token library.
  static const Color badgeIcon = Color(0xFF2D264B);

  /// `#F6F6F6` — a raw fill the v2 screens use for soft icon tiles and
  /// facility pills (Hotel/Room detail *Premium*). Not in the token library.
  static const Color mist = Color(0xFFF6F6F6);

  /// `#F1E7D3` — the 1px warm hairline around the Hotel Detail "why choose"
  /// feature cards (on `gold/25`). Not in the token library.
  static const Color goldHairline = Color(0xFFF1E7D3);
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Semantic layer — AppColorTokens (design-system-tokens.md §3).
// ─────────────────────────────────────────────────────────────────────────────

/// The semantic colour set — every `color/*` variable from the Figma `Color`
/// collection, resolved for one [Brightness]. Registered on [ThemeData] via
/// `extensions:`; read it through `context.colors`.
@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.bgCanvas,
    required this.bgSurface,
    required this.bgSurfaceRaised,
    required this.bgSubtle,
    required this.bgPrimary,
    required this.bgPrimaryHover,
    required this.bgPrimaryPressed,
    required this.bgPrimarySubtle,
    required this.bgDisabled,
    required this.bgInverse,
    required this.bgDestructive,
    required this.bgDestructiveHover,
    required this.bgDestructivePressed,
    required this.textPrimary,
    required this.textSecondary,
    required this.textLabel,
    required this.textPlaceholder,
    required this.textOnPrimary,
    required this.textOnInverse,
    required this.textAccent,
    required this.textDisabled,
    required this.borderDefault,
    required this.borderStrong,
    required this.borderFocus,
    required this.borderAccentSubtle,
    required this.borderOnInverse,
    required this.borderSubIcon,
    required this.successFg,
    required this.successBg,
    required this.successBorder,
    required this.warningFg,
    required this.warningBg,
    required this.warningBorder,
    required this.errorFg,
    required this.errorBg,
    required this.errorBorder,
    required this.infoFg,
    required this.infoBg,
    required this.infoBorder,
    required this.accentWarm,
    required this.accentWarmFg,
    required this.accentWarmBg,
    required this.accentWarmBorder,
  });

  final Color bgCanvas;
  final Color bgSurface;
  final Color bgSurfaceRaised;
  final Color bgSubtle;
  final Color bgPrimary;
  final Color bgPrimaryHover;
  final Color bgPrimaryPressed;
  final Color bgPrimarySubtle;
  final Color bgDisabled;
  final Color bgInverse;
  final Color bgDestructive;
  final Color bgDestructiveHover;
  final Color bgDestructivePressed;

  final Color textPrimary;
  final Color textSecondary;
  final Color textLabel;
  final Color textPlaceholder;
  final Color textOnPrimary;
  final Color textOnInverse;
  final Color textAccent;
  final Color textDisabled;

  final Color borderDefault;
  final Color borderStrong;
  final Color borderFocus;
  final Color borderAccentSubtle;
  final Color borderOnInverse;

  /// `color/border/sub icon` — muted glyph/outline for secondary icons (v2).
  final Color borderSubIcon;

  final Color successFg;
  final Color successBg;
  final Color successBorder;
  final Color warningFg;
  final Color warningBg;
  final Color warningBorder;
  final Color errorFg;
  final Color errorBg;
  final Color errorBorder;
  final Color infoFg;
  final Color infoBg;
  final Color infoBorder;

  final Color accentWarm;
  final Color accentWarmFg;
  final Color accentWarmBg;
  final Color accentWarmBorder;

  /// `Color` collection, `Light` mode — the v2 library (screens file exported
  /// 2026-09-23): a neutral black/white palette. The primary action, pressed and
  /// inverse slots moved from `oud` brown to `ink`; canvas went pure white.
  /// `primary-hover`, `primary-subtle`, `border/focus` and `border/accent-subtle`
  /// still alias `oud/*` in the Figma and are mirrored verbatim.
  static const AppColorTokens light = AppColorTokens(
    bgCanvas: AppPrimitives.stone0,
    bgSurface: AppPrimitives.stone0,
    bgSurfaceRaised: AppPrimitives.stone0,
    bgSubtle: AppPrimitives.stone100,
    bgPrimary: AppPrimitives.ink950,
    bgPrimaryHover: AppPrimitives.oud600,
    bgPrimaryPressed: AppPrimitives.ink900,
    bgPrimarySubtle: AppPrimitives.oud50,
    bgDisabled: AppPrimitives.stone200,
    bgInverse: AppPrimitives.ink900,
    bgDestructive: AppPrimitives.red600,
    bgDestructiveHover: AppPrimitives.red700,
    bgDestructivePressed: AppPrimitives.red800,
    textPrimary: AppPrimitives.stone950,
    textSecondary: AppPrimitives.stone500,
    textLabel: AppPrimitives.stone700,
    textPlaceholder: AppPrimitives.stone500,
    textOnPrimary: AppPrimitives.white,
    textOnInverse: AppPrimitives.white,
    textAccent: AppPrimitives.ink700,
    textDisabled: AppPrimitives.stone400,
    borderDefault: AppPrimitives.stone200,
    borderStrong: AppPrimitives.stone300,
    borderFocus: AppPrimitives.oud500,
    borderAccentSubtle: AppPrimitives.oud100,
    borderOnInverse: AppPrimitives.white,
    borderSubIcon: AppPrimitives.stone600,
    successFg: AppPrimitives.green600,
    successBg: AppPrimitives.green50,
    successBorder: AppPrimitives.green200,
    warningFg: AppPrimitives.amber600,
    warningBg: AppPrimitives.amber50,
    warningBorder: AppPrimitives.amber200,
    errorFg: AppPrimitives.red600,
    errorBg: AppPrimitives.red50,
    errorBorder: AppPrimitives.red200,
    infoFg: AppPrimitives.blue600,
    infoBg: AppPrimitives.blue50,
    infoBorder: AppPrimitives.blue200,
    accentWarm: AppPrimitives.gold400,
    accentWarmFg: AppPrimitives.gold600,
    accentWarmBg: AppPrimitives.gold25,
    accentWarmBorder: AppPrimitives.gold200,
  );

  /// `Color` collection, `Dark` mode — fully specified in the Figma, so this is
  /// a real theme, not a guess. Unchanged by the v2 library (still `oud`-led).
  static const AppColorTokens dark = AppColorTokens(
    bgCanvas: AppPrimitives.ink950,
    bgSurface: AppPrimitives.stone900,
    bgSurfaceRaised: AppPrimitives.stone800,
    bgSubtle: AppPrimitives.stone800,
    bgPrimary: AppPrimitives.oud300,
    bgPrimaryHover: AppPrimitives.oud200,
    bgPrimaryPressed: AppPrimitives.oud400,
    bgPrimarySubtle: AppPrimitives.oud900,
    bgDisabled: AppPrimitives.stone700,
    bgInverse: AppPrimitives.oud900,
    bgDestructive: AppPrimitives.red500,
    bgDestructiveHover: AppPrimitives.red600,
    bgDestructivePressed: AppPrimitives.red700,
    textPrimary: AppPrimitives.stone50,
    textSecondary: AppPrimitives.stone400,
    textLabel: AppPrimitives.stone300,
    textPlaceholder: AppPrimitives.stone400,
    textOnPrimary: AppPrimitives.oud900,
    textOnInverse: AppPrimitives.white,
    textAccent: AppPrimitives.oud300,
    textDisabled: AppPrimitives.stone600,
    borderDefault: AppPrimitives.stone700,
    borderStrong: AppPrimitives.stone600,
    borderFocus: AppPrimitives.oud300,
    borderAccentSubtle: AppPrimitives.oud700,
    borderOnInverse: AppPrimitives.white,
    borderSubIcon: AppPrimitives.stone400,
    successFg: AppPrimitives.green200,
    successBg: AppPrimitives.green900,
    successBorder: AppPrimitives.green500,
    warningFg: AppPrimitives.amber200,
    warningBg: AppPrimitives.amber900,
    warningBorder: AppPrimitives.amber500,
    errorFg: AppPrimitives.red200,
    errorBg: AppPrimitives.red900,
    errorBorder: AppPrimitives.red500,
    infoFg: AppPrimitives.blue200,
    infoBg: AppPrimitives.blue900,
    infoBorder: AppPrimitives.blue500,
    accentWarm: AppPrimitives.gold300,
    accentWarmFg: AppPrimitives.gold300,
    accentWarmBg: AppPrimitives.gold900,
    accentWarmBorder: AppPrimitives.gold700,
  );

  static AppColorTokens of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  @override
  AppColorTokens copyWith({
    Color? bgCanvas,
    Color? bgSurface,
    Color? bgSurfaceRaised,
    Color? bgSubtle,
    Color? bgPrimary,
    Color? bgPrimaryHover,
    Color? bgPrimaryPressed,
    Color? bgPrimarySubtle,
    Color? bgDisabled,
    Color? bgInverse,
    Color? bgDestructive,
    Color? bgDestructiveHover,
    Color? bgDestructivePressed,
    Color? textPrimary,
    Color? textSecondary,
    Color? textLabel,
    Color? textPlaceholder,
    Color? textOnPrimary,
    Color? textOnInverse,
    Color? textAccent,
    Color? textDisabled,
    Color? borderDefault,
    Color? borderStrong,
    Color? borderFocus,
    Color? borderAccentSubtle,
    Color? borderOnInverse,
    Color? borderSubIcon,
    Color? successFg,
    Color? successBg,
    Color? successBorder,
    Color? warningFg,
    Color? warningBg,
    Color? warningBorder,
    Color? errorFg,
    Color? errorBg,
    Color? errorBorder,
    Color? infoFg,
    Color? infoBg,
    Color? infoBorder,
    Color? accentWarm,
    Color? accentWarmFg,
    Color? accentWarmBg,
    Color? accentWarmBorder,
  }) {
    return AppColorTokens(
      bgCanvas: bgCanvas ?? this.bgCanvas,
      bgSurface: bgSurface ?? this.bgSurface,
      bgSurfaceRaised: bgSurfaceRaised ?? this.bgSurfaceRaised,
      bgSubtle: bgSubtle ?? this.bgSubtle,
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgPrimaryHover: bgPrimaryHover ?? this.bgPrimaryHover,
      bgPrimaryPressed: bgPrimaryPressed ?? this.bgPrimaryPressed,
      bgPrimarySubtle: bgPrimarySubtle ?? this.bgPrimarySubtle,
      bgDisabled: bgDisabled ?? this.bgDisabled,
      bgInverse: bgInverse ?? this.bgInverse,
      bgDestructive: bgDestructive ?? this.bgDestructive,
      bgDestructiveHover: bgDestructiveHover ?? this.bgDestructiveHover,
      bgDestructivePressed: bgDestructivePressed ?? this.bgDestructivePressed,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textLabel: textLabel ?? this.textLabel,
      textPlaceholder: textPlaceholder ?? this.textPlaceholder,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      textOnInverse: textOnInverse ?? this.textOnInverse,
      textAccent: textAccent ?? this.textAccent,
      textDisabled: textDisabled ?? this.textDisabled,
      borderDefault: borderDefault ?? this.borderDefault,
      borderStrong: borderStrong ?? this.borderStrong,
      borderFocus: borderFocus ?? this.borderFocus,
      borderAccentSubtle: borderAccentSubtle ?? this.borderAccentSubtle,
      borderOnInverse: borderOnInverse ?? this.borderOnInverse,
      borderSubIcon: borderSubIcon ?? this.borderSubIcon,
      successFg: successFg ?? this.successFg,
      successBg: successBg ?? this.successBg,
      successBorder: successBorder ?? this.successBorder,
      warningFg: warningFg ?? this.warningFg,
      warningBg: warningBg ?? this.warningBg,
      warningBorder: warningBorder ?? this.warningBorder,
      errorFg: errorFg ?? this.errorFg,
      errorBg: errorBg ?? this.errorBg,
      errorBorder: errorBorder ?? this.errorBorder,
      infoFg: infoFg ?? this.infoFg,
      infoBg: infoBg ?? this.infoBg,
      infoBorder: infoBorder ?? this.infoBorder,
      accentWarm: accentWarm ?? this.accentWarm,
      accentWarmFg: accentWarmFg ?? this.accentWarmFg,
      accentWarmBg: accentWarmBg ?? this.accentWarmBg,
      accentWarmBorder: accentWarmBorder ?? this.accentWarmBorder,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColorTokens(
      bgCanvas: c(bgCanvas, other.bgCanvas),
      bgSurface: c(bgSurface, other.bgSurface),
      bgSurfaceRaised: c(bgSurfaceRaised, other.bgSurfaceRaised),
      bgSubtle: c(bgSubtle, other.bgSubtle),
      bgPrimary: c(bgPrimary, other.bgPrimary),
      bgPrimaryHover: c(bgPrimaryHover, other.bgPrimaryHover),
      bgPrimaryPressed: c(bgPrimaryPressed, other.bgPrimaryPressed),
      bgPrimarySubtle: c(bgPrimarySubtle, other.bgPrimarySubtle),
      bgDisabled: c(bgDisabled, other.bgDisabled),
      bgInverse: c(bgInverse, other.bgInverse),
      bgDestructive: c(bgDestructive, other.bgDestructive),
      bgDestructiveHover: c(bgDestructiveHover, other.bgDestructiveHover),
      bgDestructivePressed: c(bgDestructivePressed, other.bgDestructivePressed),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textLabel: c(textLabel, other.textLabel),
      textPlaceholder: c(textPlaceholder, other.textPlaceholder),
      textOnPrimary: c(textOnPrimary, other.textOnPrimary),
      textOnInverse: c(textOnInverse, other.textOnInverse),
      textAccent: c(textAccent, other.textAccent),
      textDisabled: c(textDisabled, other.textDisabled),
      borderDefault: c(borderDefault, other.borderDefault),
      borderStrong: c(borderStrong, other.borderStrong),
      borderFocus: c(borderFocus, other.borderFocus),
      borderAccentSubtle: c(borderAccentSubtle, other.borderAccentSubtle),
      borderOnInverse: c(borderOnInverse, other.borderOnInverse),
      borderSubIcon: c(borderSubIcon, other.borderSubIcon),
      successFg: c(successFg, other.successFg),
      successBg: c(successBg, other.successBg),
      successBorder: c(successBorder, other.successBorder),
      warningFg: c(warningFg, other.warningFg),
      warningBg: c(warningBg, other.warningBg),
      warningBorder: c(warningBorder, other.warningBorder),
      errorFg: c(errorFg, other.errorFg),
      errorBg: c(errorBg, other.errorBg),
      errorBorder: c(errorBorder, other.errorBorder),
      infoFg: c(infoFg, other.infoFg),
      infoBg: c(infoBg, other.infoBg),
      infoBorder: c(infoBorder, other.infoBorder),
      accentWarm: c(accentWarm, other.accentWarm),
      accentWarmFg: c(accentWarmFg, other.accentWarmFg),
      accentWarmBg: c(accentWarmBg, other.accentWarmBg),
      accentWarmBorder: c(accentWarmBorder, other.accentWarmBorder),
    );
  }
}

/// `context.colors.bgSubtle` — the canonical way for a widget to read a semantic
/// colour. Throws if the extension is missing so a mis-wired theme fails loudly
/// in tests rather than rendering wrong.
extension AppColorTokensX on BuildContext {
  AppColorTokens get colors => Theme.of(this).extension<AppColorTokens>()!;
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Deprecated compatibility shims. Remove once call sites read context.colors.
// ─────────────────────────────────────────────────────────────────────────────

/// Legacy flat palette — **prefer `context.colors.*` ([AppColorTokens])**. Every
/// name here now resolves to the correct design-system primitive so pre-token
/// call sites keep compiling during the migration; `@Deprecated` annotations
/// land once the last read is gone. Only [white] survives the cut.
abstract final class AppColors {
  // Names are historical: "brown" now resolves to the v2 near-black primary.
  static const Color brown700 = AppPrimitives.ink950;
  static const Color brown900 = AppPrimitives.ink900;
  static const Color brown500 = AppPrimitives.oud600;
  static const Color brown300 = AppPrimitives.oud300;

  static const Color bronze500 = AppPrimitives.gold600;
  static const Color bronze400 = AppPrimitives.gold400;
  static const Color bronze200 = AppPrimitives.gold200;

  static const Color ink900 = AppPrimitives.stone950;
  static const Color ink600 = AppPrimitives.stone500;
  static const Color ink400 = AppPrimitives.stone400;
  static const Color paper = AppPrimitives.stone0;
  static const Color surface = AppPrimitives.stone0;
  static const Color hairline = AppPrimitives.stone200;

  static const Color darkBackground = AppPrimitives.ink950;
  static const Color darkSurface = AppPrimitives.stone900;
  static const Color darkHairline = AppPrimitives.stone700;
  static const Color darkInk = AppPrimitives.stone50;

  static const Color success = AppPrimitives.green600;
  static const Color successContainer = AppPrimitives.green50;
  static const Color warning = AppPrimitives.amber600;
  static const Color warningContainer = AppPrimitives.amber50;
  static const Color error = AppPrimitives.red600;
  static const Color errorContainer = AppPrimitives.red50;
  static const Color info = AppPrimitives.blue600;
  static const Color infoContainer = AppPrimitives.blue50;

  /// Pure white — still a legitimate literal (on-primary ink).
  static const Color white = AppPrimitives.white;
}

/// Legacy semantic extension — **superseded by [AppColorTokens]**
/// (`context.colors`), which carries the full set for both modes. Kept one
/// release so existing `Theme.of(context).extension<AppSemanticColors>()` reads
/// keep working; values now track `design-system-tokens.md` §3.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.info,
    required this.infoContainer,
    required this.accent,
    required this.hairline,
  });

  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color info;
  final Color infoContainer;
  final Color accent;
  final Color hairline;

  static const AppSemanticColors light = AppSemanticColors(
    success: AppPrimitives.green600,
    successContainer: AppPrimitives.green50,
    warning: AppPrimitives.amber600,
    warningContainer: AppPrimitives.amber50,
    info: AppPrimitives.blue600,
    infoContainer: AppPrimitives.blue50,
    accent: AppPrimitives.gold400,
    hairline: AppPrimitives.stone200,
  );

  static const AppSemanticColors dark = AppSemanticColors(
    success: AppPrimitives.green200,
    successContainer: AppPrimitives.green900,
    warning: AppPrimitives.amber200,
    warningContainer: AppPrimitives.amber900,
    info: AppPrimitives.blue200,
    infoContainer: AppPrimitives.blue900,
    accent: AppPrimitives.gold300,
    hairline: AppPrimitives.stone700,
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? info,
    Color? infoContainer,
    Color? accent,
    Color? hairline,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      accent: accent ?? this.accent,
      hairline: hairline ?? this.hairline,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
    );
  }
}
