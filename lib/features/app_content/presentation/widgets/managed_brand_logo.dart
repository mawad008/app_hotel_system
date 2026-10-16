import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/brand_logo.dart';
import '../../domain/entities/app_content.dart';
import '../state/app_content_providers.dart';

/// [BrandLogo] fed with the dashboard-managed logo + app name.
///
/// The bundled mark is visible immediately while content loads. Once resolved
/// (or on failure → [AppContent.empty]) it shows the uploaded logo / name, or
/// the bundled defaults for anything not configured.
class ManagedBrandLogo extends ConsumerWidget {
  const ManagedBrandLogo({
    super.key,
    this.variant = BrandLogoVariant.markOnly,
    this.markSize = 120,
  });

  final BrandLogoVariant variant;
  final double markSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppContent? content = ref.watch(appContentProvider).valueOrNull;
    return BrandLogo(
      variant: variant,
      markSize: markSize,
      logoUrl: content?.logoUrl,
      wordmark: content?.appName.resolve(Localizations.localeOf(context)),
    );
  }
}
