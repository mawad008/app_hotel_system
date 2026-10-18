import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../app_content/domain/entities/app_content.dart';
import '../../../app_content/presentation/state/app_content_providers.dart';

/// The splash composition: the brand navy field with the STDY HOTELS lock-up
/// ([BrandLockup]: app icon over the wordmark) centred on the screen — the
/// same ground and icon position as the native splash screens, so the
/// hand-over from the OS is seamless.
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
/// The lock-up is the bundled artwork rather than the dashboard-managed logo:
/// it has to match the native splash, which can't load anything. The splash
/// is the first screen, so it warms the onboarding photo into the image cache
/// as soon as the dashboard content arrives — onboarding then paints it at
/// once.
class EntrySplashBackdrop extends ConsumerWidget {
  const EntrySplashBackdrop({super.key, this.overlay});

  /// Painted above the lock-up (the language sheet).
  final Widget? overlay;

  static const Color background = AppPrimitives.brandNavy;

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
      value: SystemUiOverlayStyle.light.copyWith(
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
              const Center(child: BrandLockup()),
              ?overlay,
            ],
          ),
        ),
      ),
    );
  }
}
