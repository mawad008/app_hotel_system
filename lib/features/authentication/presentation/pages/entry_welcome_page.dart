import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/button_spinner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../app_content/domain/entities/app_content.dart';
import '../../../app_content/presentation/state/app_content_providers.dart';
import '../../../app_content/presentation/widgets/managed_brand_logo.dart';
import '../state/language_selection_controller.dart';

/// `01 · Entry` — onboarding (v2 Figma `ENTRY_Onboarding`).
///
/// A full-bleed hotel photo with a single floating **glass card** at the bottom:
/// the brand avatar in a white ring overlapping the card's top edge, a centred
/// white headline + sub-line, and one `ابدأ الآن` call to action. RTL-first.
///
/// Only defined in light in the Figma, so the subtree is pinned to
/// [AppTheme.light] (the CTA must stay near-black on the photo in dark mode).
///
/// The photo, avatar logo, headline, sub-line and button label are
/// dashboard-managed (`GET /guest/app-content`); anything not configured
/// keeps its bundled Figma default.
class EntryWelcomePage extends ConsumerWidget {
  const EntryWelcomePage({super.key});

  static final ThemeData _theme = AppTheme.light;

  /// Figma: the card sits 16px from the screen's bottom edge on a device with a
  /// 34px home indicator (it floats over the indicator zone). Larger system
  /// insets (e.g. a 3-button nav bar) push it up by the same offset so the CTA
  /// is never covered.
  static double _bottomGap(BuildContext context) => math.max(
    AppSpacing.space4,
    MediaQuery.viewPaddingOf(context).bottom - 18,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppContent> content = ref.watch(appContentProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Theme(
        data: _theme,
        child: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _OnboardingPhoto(content: content),
              Positioned(
                left: AppSpacing.space4,
                right: AppSpacing.space4,
                bottom: _bottomGap(context),
                child: _OnboardingCard(
                  content: content.value ?? AppContent.empty,
                  // Deferred auth: browsing is open. Sign-in is requested
                  // later, when the guest confirms a booking.
                  onStart: () {
                    // Remembered across launches: onboarding is first-run only.
                    ref.read(onboardingCompletedProvider.notifier).complete();
                    context.goNamed(AppRoutes.discoverName);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The full-bleed photo: the dashboard upload when there is one (precached by
/// the splash, so normally instant), else the bundled Figma photo. While the
/// content is still loading it shows a dark neutral ground rather than the
/// bundled photo, so the picture never switches in front of the guest; a
/// failed upload falls back to the bundled photo.
class _OnboardingPhoto extends StatelessWidget {
  const _OnboardingPhoto({required this.content});

  final AsyncValue<AppContent> content;

  static const Widget _bundled = AppImage(
    asset: AppImages.entryHero,
    fit: BoxFit.cover,
    borderRadius: BorderRadius.zero,
  );

  @override
  Widget build(BuildContext context) {
    final AppContent? value = content.value;
    if (value == null) {
      return const ColoredBox(color: AppPrimitives.stone950);
    }
    final String? url = value.onboardingImageUrl;
    if (url == null) return _bundled;
    return ColoredBox(
      color: AppPrimitives.stone950,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        frameBuilder:
            (
              BuildContext context,
              Widget child,
              int? frame,
              bool wasSynchronouslyLoaded,
            ) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 250),
                child: child,
              );
            },
        errorBuilder: (BuildContext context, Object error, StackTrace? st) =>
            _bundled,
      ),
    );
  }
}

/// Figma `Frame 36`: the 70px avatar ring overlapping the glass `sheet` by 44px
/// (a −44 auto-layout gap), so the card starts 26px below the ring's top.
class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.content, required this.onStart});

  final AppContent content;
  final VoidCallback onStart;

  static const double _ring = 70;
  static const double _overlap = 44;

  /// Figma `sheet` corner radius — off the radius scale, specific to this card.
  static const double _radius = 37;

  /// Figma `GLASS` effect radius 21 → a Gaussian sigma of about half that.
  static const double _blurSigma = 10.5;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme text = Theme.of(context).textTheme;
    final Locale locale = Localizations.localeOf(context);

    final Widget glass = ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(_radius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: ColoredBox(
          // White at 20% over the blurred photo.
          color: AppPrimitives.white.withValues(alpha: 0.2),
          child: Padding(
            // 50 on top clears the overlapping avatar ring.
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              50,
              AppSpacing.space4,
              AppSpacing.space4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // `display` 28/40 (ExtraBold Tajawal).
                Text(
                  content.onboardingTitle.resolve(locale) ?? l10n.entryHeadline,
                  textAlign: TextAlign.center,
                  style: text.displaySmall?.copyWith(
                    color: AppPrimitives.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                // `body-lg` 17/28 Regular.
                Text(
                  content.onboardingBody.resolve(locale) ?? l10n.entrySubtext,
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(color: AppPrimitives.white),
                ),
                // 8 gap + 1px `grow` spacer + 8 gap.
                const SizedBox(height: AppSpacing.space2 * 2 + 1),
                PrimaryButton(
                  label:
                      content.onboardingCta.resolve(locale) ??
                      l10n.entryStartAction,
                  size: AppButtonSize.small,
                  onPressed: onStart,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: _ring - _overlap),
          child: glass,
        ),
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(child: _AvatarRing(size: _ring)),
        ),
      ],
    );
  }
}

/// Figma `Frame 35`: a white 70px circle with a 2px `stone/300` @50% ring and
/// the soft tile shadow, holding the 50px brand avatar.
class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppPrimitives.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppPrimitives.stone300.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: AppShadows.tile,
      ),
      alignment: Alignment.center,
      child: const ManagedBrandLogo(markSize: 50),
    );
  }
}
