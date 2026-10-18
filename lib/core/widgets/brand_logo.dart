import 'package:flutter/material.dart';

import '../localization/l10n.dart';
import '../theme/app_colors.dart';
import 'brand_paths.dart';

/// The splash lock-up: the app icon above the wordmark, centred as one block.
///
/// The native splash screens (Android `launch_background.xml` /
/// `splash_icon.xml`, iOS `LaunchScreen.storyboard`) draw only the 120px icon,
/// raised 20.5px; this block is 161px tall, so the icon lands on exactly the
/// same spot and the wordmark simply appears under it when Flutter takes over.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key});

  static const double _markSize = 120;
  static const double _wordmarkWidth = 220;

  /// Mark + gap + wordmark; the native splashes raise the icon by half of
  /// what exceeds the mark (`(161 - 120) / 2 = 20.5`).
  static const double _height = 161;

  static const double _gap =
      _height - _markSize - _wordmarkWidth / BrandPaths.wordmarkWidth;

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BrandMark(size: _markSize, tileColor: AppPrimitives.white),
        SizedBox(height: _gap),
        BrandWordmark(width: _wordmarkWidth),
      ],
    );
  }
}

/// The app icon (`Design/brand/stdy-hotels-logo.svg`): a rounded tile holding
/// the gold ring, in a square [size] box — navy on light grounds (as the
/// launcher icon), white on the navy splash. Drawn as vector paths, so it
/// stays crisp at every size and needs no raster asset.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 120,
    this.tileColor = AppPrimitives.brandNavy,
    this.ringColor = AppPrimitives.brandGold,
  });

  final double size;
  final Color tileColor;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _BrandMarkPainter(tileColor, ringColor),
    );
  }
}

/// The STDY HOTELS wordmark, [width] wide (its height follows the artwork).
/// The artwork is white with a gold "O", for the navy brand ground.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    required this.width,
    this.letterColor = AppPrimitives.white,
    this.accentColor = AppPrimitives.brandGold,
  });

  final double width;
  final Color letterColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.appName,
      excludeSemantics: true,
      child: CustomPaint(
        size: Size(width, width / BrandPaths.wordmarkWidth),
        painter: _BrandWordmarkPainter(letterColor, accentColor),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter(this.tileColor, this.ringColor);

  final Color tileColor;
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & const Size.square(1),
        const Radius.circular(BrandPaths.tileRadius),
      ),
      Paint()..color = tileColor,
    );
    canvas.drawPath(BrandPaths.ring, Paint()..color = ringColor);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BrandMarkPainter old) =>
      old.tileColor != tileColor || old.ringColor != ringColor;
}

class _BrandWordmarkPainter extends CustomPainter {
  const _BrandWordmarkPainter(this.letterColor, this.accentColor);

  final Color letterColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.height);
    canvas.drawPath(BrandPaths.wordmarkLetters, Paint()..color = letterColor);
    canvas.drawPath(BrandPaths.wordmarkAccent, Paint()..color = accentColor);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BrandWordmarkPainter old) =>
      old.letterColor != letterColor || old.accentColor != accentColor;
}
