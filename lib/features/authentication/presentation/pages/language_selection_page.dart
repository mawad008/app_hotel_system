import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/localization/supported_locales.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/button_spinner.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../state/language_selection_controller.dart';
import '../widgets/entry_splash_backdrop.dart';
import '../widgets/language_glyph.dart';

/// `01 · Entry` — the first-run language choice.
///
/// v2 Figma: the language `sheet` (`14 · Entry, loyalty & completion`) is a
/// **centred modal overlay on `ENTRY_Splash`** (prototype: AFTER_TIMEOUT 1.6s →
/// OVERLAY, default Center position, background black @25%) — a white card
/// titled `اختر لغة التطبيق` with the globe glyph, a hairline, and one outlined
/// button per language. Either button applies that language and goes
/// straight on to onboarding (the prototype wires both to `ENTRY_Onboarding`);
/// there is no separate "continue" step.
///
/// Arabic stays the default locale until the guest picks (committed in
/// [initState] when nothing is set), so the sheet renders Arabic-first.
class LanguageSelectionPage extends ConsumerStatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  ConsumerState<LanguageSelectionPage> createState() =>
      _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends ConsumerState<LanguageSelectionPage> {
  /// Figma `overlayBackgroundAppearance`: solid black at 25%.
  static const Color _scrim = Color(0x40000000);

  @override
  void initState() {
    super.initState();
    // No preference stored yet → commit to Arabic so the sheet (and the
    // onboarding after it) render Arabic-first, matching the design.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(localeControllerProvider) == null) {
        ref
            .read(localeControllerProvider.notifier)
            .set(SupportedLocales.arabic);
      }
    });
  }

  void _choose(Locale locale) {
    ref.read(localeControllerProvider.notifier).set(locale);
    ref.read(languageSelectedProvider.notifier).markSelected();
    context.goNamed(AppRoutes.welcomeName);
  }

  @override
  Widget build(BuildContext context) {
    // Figma overlay: centred, 8px in from the screen edges (377 of 393), over
    // a black @25% scrim. The whole overlay (scrim + card) dissolves in. It is
    // modal: nothing behind it is interactive, so only a language choice moves
    // on.
    return EntrySplashBackdrop(
      overlay: _DissolveIn(
        child: ColoredBox(
          color: _scrim,
          child: SafeArea(
            minimum: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
            child: Center(
              child: _LanguageSheet(
                onArabic: () => _choose(SupportedLocales.arabic),
                onEnglish: () => _choose(SupportedLocales.english),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The v2 language `sheet`: white, radius 37, the soft two-layer tile shadow,
/// 16px padding and a 20px rhythm between header, hairline and actions.
class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.onArabic, required this.onEnglish});

  final VoidCallback onArabic;
  final VoidCallback onEnglish;

  /// Figma `sheet` corner radius — off the radius scale, specific to this card.
  static const double _radius = 37;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final AppColorTokens c = context.colors;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppPrimitives.stone0,
        borderRadius: BorderRadius.all(Radius.circular(_radius)),
        boxShadow: AppShadows.tile,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Header: translate glyph + title (20 Medium, 32 line), centred.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Figma `lan 1`: the exact 33px globe-and-bubbles glyph.
                LanguageGlyph(color: c.textPrimary),
                const SizedBox(width: AppSpacing.space2),
                Flexible(
                  child: Text(
                    l10n.languageScreenHeading,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: AppTypography.medium,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space5),
            Divider(height: 0.5, thickness: 0.5, color: c.borderDefault),
            const SizedBox(height: AppSpacing.space5),
            // Each language is named in its own script. Figma buttons are 49
            // tall (a Small override); Medium 48 is the nearest system size.
            SecondaryButton(
              label: l10n.languageArabic,
              size: AppButtonSize.medium,
              onPressed: onArabic,
            ),
            const SizedBox(height: AppSpacing.space4),
            SecondaryButton(
              label: l10n.languageEnglish,
              size: AppButtonSize.medium,
              onPressed: onEnglish,
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades the sheet in over the splash once — the prototype overlay's
/// transition: DISSOLVE, 220ms, ease-out-cubic. Purely presentational.
class _DissolveIn extends StatelessWidget {
  const _DissolveIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (BuildContext context, double t, Widget? child) =>
          Opacity(opacity: t, child: child),
    );
  }
}
