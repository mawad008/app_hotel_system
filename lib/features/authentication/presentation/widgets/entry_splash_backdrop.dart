import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../app_content/domain/entities/app_content.dart';
import '../../../app_content/presentation/state/app_content_providers.dart';
import '../../../app_content/presentation/widgets/managed_brand_logo.dart';

/// The v2 `ENTRY_Splash` composition: a plain white field with the brand
/// lock-up (120px mark, 5px gap, "Hotel System" wordmark) centred on the
/// screen.
///
/// Shared by the splash and the first-run language sheet, which the Figma
/// prototype opens as an **overlay on the splash** — so moving from one to the
/// other only slides the sheet in; the brand never jumps.
///
/// The splash renders before any user preference (theme, locale) is known, so
/// it commits to one fixed look: the subtree is pinned to [AppTheme.light]
/// (the Figma only defines these frames in light), and everything inside —
/// including the language sheet — reads the light tokens.
///
/// The logo and app name are dashboard-managed (`ManagedBrandLogo`). The splash
/// is the first screen, so it also warms the onboarding photo into the image
/// cache as soon as the content arrives — onboarding then paints it at once.
class EntrySplashBackdrop extends ConsumerWidget {
  const EntrySplashBackdrop({super.key, this.overlay});

  /// Painted above the lock-up (the language sheet).
  final Widget? overlay;

  static const Color background = AppPrimitives.stone0;

  static final ThemeData _theme = AppTheme.light;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<AppContent>>(appContentProvider, (
      AsyncValue<AppContent>? previous,
      AsyncValue<AppContent> next,
    ) {
      final String? url = next.value?.onboardingImageUrl;
      if (url != null) {
        precacheImage(
          AppNetworkImages.provider(url),
          context,
          onError: (Object _, StackTrace? _) {},
        );
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: background,
      ),
      child: Theme(
        data: _theme,
        child: Scaffold(
          backgroundColor: background,
          body: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const Center(
                child: ManagedBrandLogo(variant: BrandLogoVariant.stacked),
              ),
              ?overlay,
            ],
          ),
        ),
      ),
    );
  }
}
