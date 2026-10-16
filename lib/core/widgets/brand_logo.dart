import 'package:flutter/material.dart';

import '../localization/l10n.dart';
import '../theme/app_colors.dart';
import 'app_image.dart';

/// How the brand lock-up is arranged.
enum BrandLogoVariant {
  /// The mark above the "Hotel System" wordmark (v2 `ENTRY_Splash`).
  stacked,

  /// The mark only (v2 onboarding avatar).
  markOnly,
}

/// The brand lock-up — the v2 Figma `Logo Placeholder` component.
///
/// The mark is the **exact** Figma artwork, decoded from the vector network in
/// `Design/hotel_guest_app.fig` (`Logo Placeholder / Size=Splash`, 120×120
/// frame): three arched towers in `ink/700` with the gold "1" spire. It is drawn
/// as vector paths, so it stays crisp at every size and needs no raster asset.
///
/// v2 renders the mark on a **light** ground (splash, onboarding avatar); the
/// colours default to the design system's fixed brand values and can be
/// overridden per call site.
///
/// The logo and wordmark are dashboard-managed (`GET /guest/app-content`):
/// pass [logoUrl] / [wordmark] to show the uploaded logo and app name. `null`
/// keeps the bundled vector mark / "Hotel System" string, and an uploaded logo
/// that fails to load falls back to the vector mark.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.variant = BrandLogoVariant.markOnly,
    this.markSize = 120,
    this.towerColor = AppPrimitives.ink700,
    this.spireColor = AppPrimitives.gold400,
    this.wordmarkColor = AppPrimitives.stone950,
    this.logoUrl,
    this.wordmark,
  });

  /// A dashboard-uploaded logo, drawn `contain` in the [markSize] box.
  final String? logoUrl;

  /// The dashboard-managed app name shown under the mark in
  /// [BrandLogoVariant.stacked].
  final String? wordmark;

  final BrandLogoVariant variant;

  /// Edge of the square mark box (the Figma symbol frame: Splash 120, Avatar
  /// 44 — the artwork scales with it).
  final double markSize;

  /// The towers (`ink/700`).
  final Color towerColor;

  /// The gold "1" spire (`gold/400`).
  final Color spireColor;

  /// The wordmark under the mark in [BrandLogoVariant.stacked].
  final Color wordmarkColor;

  @override
  Widget build(BuildContext context) {
    final Widget vectorMark = BrandMark(
      size: markSize,
      towerColor: towerColor,
      spireColor: spireColor,
    );
    final String? url = logoUrl;
    final Widget mark = url == null || url.isEmpty
        ? vectorMark
        : SizedBox.square(
            dimension: markSize,
            child: Image(
              image: AppNetworkImages.provider(url),
              fit: BoxFit.contain,
              // Fade in once decoded; nothing (not the default mark) shows
              // meanwhile, so the brand never flips from one logo to another.
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
                      duration: const Duration(milliseconds: 200),
                      child: child,
                    );
                  },
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? st,
              ) => vectorMark,
            ),
          );
    switch (variant) {
      case BrandLogoVariant.markOnly:
        return mark;
      case BrandLogoVariant.stacked:
        // v2 splash: 120 mark, 5px gap, "Hotel System" at `title-lg` 24/36
        // Bold Tajawal (the approved font).
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            mark,
            const SizedBox(height: 5),
            Text(
              wordmark ?? context.l10n.brandWordmark,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: wordmarkColor),
            ),
          ],
        );
    }
  }
}

/// The two-tone brand mark alone, in a square [size] box.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 120,
    this.towerColor = AppPrimitives.ink700,
    this.spireColor = AppPrimitives.gold400,
  });

  final double size;
  final Color towerColor;
  final Color spireColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _BrandMarkPainter(towerColor, spireColor),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter(this.towerColor, this.spireColor);

  final Color towerColor;
  final Color spireColor;

  /// The Figma symbol frame the paths are authored in.
  static const double _box = 120;

  static final List<Path> _towers = <Path>[
    Path()
      ..moveTo(38.65, 30.73)
      ..cubicTo(39.86, 31.14, 42.16, 32.29, 43.37, 32.89)
      ..cubicTo(52.03, 37.23, 59.97, 42.89, 66.9, 49.67)
      ..cubicTo(74.08, 56.76, 73.12, 61.93, 73.11, 71.25)
      ..lineTo(73.12, 86.72)
      ..cubicTo(73.14, 88.67, 73.12, 90.74, 73.18, 92.67)
      ..lineTo(67.28, 92.69)
      ..lineTo(67.27, 74.95)
      ..lineTo(52.74, 74.96)
      ..lineTo(52.74, 92.68)
      ..lineTo(34.39, 92.68)
      ..lineTo(34.41, 69.07)
      ..cubicTo(34.41, 65.31, 34.57, 60.89, 34.2, 57.17)
      ..cubicTo(33.79, 53.14, 30.64, 50.97, 27.51, 48.73)
      ..cubicTo(26.78, 49.42, 26.05, 50.11, 25.34, 50.82)
      ..cubicTo(24.72, 51.43, 23.65, 52.67, 23.55, 53.51)
      ..cubicTo(23.16, 56.78, 23.32, 60.98, 23.32, 64.3)
      ..lineTo(23.33, 86.77)
      ..cubicTo(26.38, 86.76, 29.43, 86.77, 32.48, 86.8)
      ..lineTo(32.49, 92.68)
      ..lineTo(17.45, 92.68)
      ..lineTo(17.44, 67.82)
      ..cubicTo(17.44, 63.38, 16.95, 54.61, 18.28, 50.58)
      ..cubicTo(19.15, 47.96, 24.68, 43.33, 27, 41.2)
      ..cubicTo(30.07, 43.04, 33.31, 45.52, 35.91, 47.97)
      ..cubicTo(41.41, 53.16, 40.35, 61.49, 40.34, 68.36)
      ..lineTo(40.33, 86.77)
      ..lineTo(46.9, 86.77)
      ..lineTo(46.9, 71.28)
      ..cubicTo(46.89, 61.21, 45.98, 56.17, 54.11, 48.83)
      ..cubicTo(55.6, 50.04, 57.14, 51.25, 58.54, 52.56)
      ..cubicTo(58.36, 52.77, 57.52, 53.6, 57.28, 53.82)
      ..cubicTo(52.05, 58.74, 52.72, 62.5, 52.74, 69.08)
      ..lineTo(67.28, 69.08)
      ..cubicTo(67.27, 65.99, 67.65, 62.53, 66.67, 59.56)
      ..cubicTo(64.17, 51.99, 47.43, 41.55, 40.34, 37.96)
      ..lineTo(40.33, 50.82)
      ..cubicTo(38.57, 47.58, 37.2, 46.43, 34.4, 44.09)
      ..lineTo(34.39, 34.68)
      ..cubicTo(35.78, 33.33, 37.2, 32.01, 38.65, 30.73)
      ..close(),
    Path()
      ..moveTo(92.83, 41.3)
      ..cubicTo(93.54, 41.4, 98.15, 46.04, 99.07, 46.84)
      ..cubicTo(102.79, 50.06, 102.66, 54.62, 102.57, 59.1)
      ..cubicTo(102.52, 61.54, 102.57, 64.02, 102.57, 66.44)
      ..lineTo(102.57, 92.68)
      ..lineTo(87.54, 92.68)
      ..lineTo(87.55, 89.87)
      ..lineTo(87.55, 86.78)
      ..lineTo(96.68, 86.78)
      ..lineTo(96.69, 65.98)
      ..cubicTo(96.69, 62.32, 96.71, 58.65, 96.66, 54.99)
      ..cubicTo(96.61, 52.06, 94.53, 50.6, 92.47, 48.73)
      ..cubicTo(90.74, 50.04, 89.05, 51.28, 87.54, 52.87)
      ..lineTo(87.57, 45.03)
      ..cubicTo(89.08, 43.74, 91.16, 42.41, 92.83, 41.3)
      ..close(),
    Path()
      ..moveTo(59.93, 12.33)
      ..cubicTo(60.56, 12.39, 66.13, 16.93, 67.1, 17.61)
      ..cubicTo(73.33, 22.05, 73.16, 25.58, 73.1, 32.56)
      ..cubicTo(71.12, 33.66, 69.18, 34.81, 67.27, 36.02)
      ..cubicTo(67.29, 33.32, 67.37, 30.07, 67.23, 27.4)
      ..cubicTo(67.07, 24.37, 62.7, 21.62, 60.22, 19.69)
      ..cubicTo(59.59, 19.57, 55.38, 23.18, 54.71, 23.77)
      ..cubicTo(51.84, 26.35, 52.72, 32.26, 52.74, 36)
      ..cubicTo(50.87, 34.8, 48.83, 33.64, 46.91, 32.5)
      ..cubicTo(46.9, 30.7, 46.81, 27.68, 47.06, 26.04)
      ..cubicTo(47.31, 24.38, 47.96, 22.81, 48.94, 21.45)
      ..cubicTo(50.86, 18.79, 57.07, 14.43, 59.93, 12.33)
      ..close(),
  ];

  static final Path _spire = Path()
    ..moveTo(81.33, 30.71)
    ..cubicTo(82.81, 32, 84.19, 33.3, 85.62, 34.64)
    ..lineTo(85.61, 92.69)
    ..cubicTo(82.68, 92.69, 79.27, 92.78, 76.37, 92.69)
    ..cubicTo(75.49, 92.74, 74.09, 92.69, 73.18, 92.67)
    ..cubicTo(73.12, 90.74, 73.14, 88.67, 73.12, 86.72)
    ..cubicTo(74.54, 86.77, 78.61, 86.63, 79.66, 86.82)
    ..lineTo(79.66, 37.96)
    ..cubicTo(74.6, 40.59, 70.76, 42.89, 66.11, 46.27)
    ..cubicTo(64.91, 45.22, 62.62, 43.39, 61.58, 42.37)
    ..cubicTo(68.18, 37.34, 73.83, 34.09, 81.33, 30.71)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _box, size.height / _box);
    final Paint tower = Paint()..color = towerColor;
    for (final Path p in _towers) {
      canvas.drawPath(p, tower);
    }
    canvas.drawPath(_spire, Paint()..color = spireColor);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BrandMarkPainter old) =>
      old.towerColor != towerColor || old.spireColor != spireColor;
}
