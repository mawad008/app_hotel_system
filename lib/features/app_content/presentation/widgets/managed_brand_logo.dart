import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/brand_logo.dart';
import '../../domain/entities/app_content.dart';
import '../state/app_content_providers.dart';

/// [BrandLogo] fed with the dashboard-managed logo + app name.
///
/// Reads [brandingProvider]: the logo / name this device last received shows
/// from the first frame, then the fresh content once loaded. On a first
/// launch nothing is drawn until the content arrives, so the app name never
/// flips to the uploaded logo in front of the guest.
class ManagedBrandLogo extends ConsumerWidget {
  const ManagedBrandLogo({
    super.key,
    this.variant = BrandLogoVariant.markOnly,
    this.markSize = 120,
    this.entrance,
  });

  final BrandLogoVariant variant;
  final double markSize;

  /// See [BrandLogo.entrance].
  final Animation<double>? entrance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(brandingKnownProvider)) {
      return SizedBox.square(dimension: markSize);
    }
    final AppContent content = ref.watch(brandingProvider);
    return BrandLogo(
      variant: variant,
      markSize: markSize,
      entrance: entrance,
      logoUrl: content.logoUrl,
      wordmark: content.appName.resolve(Localizations.localeOf(context)),
    );
  }
}
