import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../localization/l10n.dart';
import '../theme/app_colors.dart';

/// How the brand lock-up is arranged.
enum BrandLogoVariant {
  /// The logo above the app name (v2 `ENTRY_Splash`).
  stacked,

  /// The logo only (v2 onboarding avatar).
  markOnly,
}

/// The brand lock-up: the dashboard-managed logo and app name
/// (`GET /guest/app-content`).
///
/// There is no bundled logo: with a [logoUrl] the uploaded logo is drawn
/// `contain` in the [markSize] box; without one (or when it fails to load)
/// only the app name ([wordmark], else the bundled "Hotel System" string)
/// shows.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.variant = BrandLogoVariant.markOnly,
    this.markSize = 120,
    this.ringColor = AppPrimitives.gold400,
    this.wordmarkColor = AppPrimitives.stone950,
    this.logoUrl,
    this.wordmark,
    this.entrance,
  });

  /// Drives the splash entrance (0 → 1): the logo breathes, gold ripples
  /// radiate from it and a sheen sweeps across it, then the wordmark rises in.
  /// At 1 the lock-up is the static layout. `null` draws the static lock-up.
  final Animation<double>? entrance;

  /// A dashboard-uploaded logo, drawn `contain` in the [markSize] box.
  final String? logoUrl;

  /// The dashboard-managed app name.
  final String? wordmark;

  final BrandLogoVariant variant;

  /// Edge of the square logo box (Splash 120, Avatar 50).
  final double markSize;

  /// The entrance ripples (`gold/400`).
  final Color ringColor;

  /// The app name text.
  final Color wordmarkColor;

  @override
  Widget build(BuildContext context) {
    final TextStyle? nameStyle = Theme.of(context).textTheme.headlineMedium
        ?.copyWith(color: wordmarkColor);
    final String name = wordmark ?? context.l10n.brandWordmark;
    final Widget text = Text(
      name,
      textAlign: TextAlign.center,
      style: nameStyle,
    );
    final Animation<double>? entrance = this.entrance;
    final Widget animatedText = entrance == null
        ? text
        : _WordmarkEntrance(animation: entrance, child: text);

    // Mark-only without a logo: the name, scaled down to fit the box.
    final Widget nameInBox = SizedBox.square(
      dimension: markSize,
      child: Center(
        child: FittedBox(fit: BoxFit.scaleDown, child: text),
      ),
    );

    final String? url = logoUrl;
    if (url == null || url.isEmpty) {
      return variant == BrandLogoVariant.markOnly ? nameInBox : animatedText;
    }

    final Widget mark = SizedBox.square(
      dimension: markSize,
      child: Image.network(
        url,
        fit: BoxFit.contain,
        // Web: storage files may be served without CORS headers (nginx serves
        // `/storage` directly, bypassing Laravel's CORS middleware), which
        // makes the default fetch fail — fall back to an <img> element.
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        // Fade in once decoded; nothing shows meanwhile.
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
        // A broken logo leaves just the name (stacked already shows it).
        errorBuilder: (BuildContext context, Object error, StackTrace? st) =>
            variant == BrandLogoVariant.markOnly
            ? nameInBox
            : const SizedBox.shrink(),
      ),
    );
    final Widget animatedMark = entrance == null
        ? mark
        : _MarkEntrance(
            animation: entrance,
            size: markSize,
            ringColor: ringColor,
            child: mark,
          );
    switch (variant) {
      case BrandLogoVariant.markOnly:
        return animatedMark;
      case BrandLogoVariant.stacked:
        // v2 splash: 120 logo, 5px gap, the app name at `title-lg` 24/36.
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            animatedMark,
            const SizedBox(height: 5),
            animatedText,
          ],
        );
    }
  }
}

/// The mark's share of [BrandLogo.entrance]: a gentle breath (1 → 1.05 → 1),
/// two gold ripples expanding behind it, and a light sheen sweeping across
/// the artwork. Paints outside its box (ripples) without changing layout.
class _MarkEntrance extends StatelessWidget {
  const _MarkEntrance({
    required this.animation,
    required this.size,
    required this.ringColor,
    required this.child,
  });

  final Animation<double> animation;
  final double size;
  final Color ringColor;
  final Widget child;

  static const Curve _breath = Interval(0, 0.45, curve: Curves.easeInOut);
  static const Curve _sheen = Interval(0.2, 0.7, curve: Curves.easeInOutCubic);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (BuildContext context, Widget? child) {
        final double t = animation.value;
        // sin over [0, π] → 0 → 1 → 0: swell and settle back to rest.
        final double scale =
            1 + 0.05 * math.sin(math.pi * _breath.transform(t));
        Widget mark = Transform.scale(scale: scale, child: child);
        if (t > 0.2 && t < 0.7) {
          final double p = _sheen.transform(t);
          // A soft white band travels corner to corner; `srcATop` keeps it on
          // the artwork's own pixels, so the white field stays untouched.
          mark = ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (Rect rect) => LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.55),
                Colors.white.withValues(alpha: 0),
              ],
              stops: <double>[
                (p * 1.6 - 0.5).clamp(0, 1),
                (p * 1.6 - 0.3).clamp(0, 1),
                (p * 1.6 - 0.1).clamp(0, 1),
              ],
            ).createShader(rect),
            child: mark,
          );
        }
        return CustomPaint(
          painter: _RipplePainter(t, ringColor),
          child: SizedBox.square(
            dimension: size,
            child: Center(child: mark),
          ),
        );
      },
    );
  }
}

/// Two staggered gold rings that grow out of the mark and fade away.
class _RipplePainter extends CustomPainter {
  const _RipplePainter(this.t, this.color);

  final double t;
  final Color color;

  static const List<Interval> _rings = <Interval>[
    Interval(0.1, 0.65, curve: Curves.easeOutCubic),
    Interval(0.25, 0.8, curve: Curves.easeOutCubic),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double base = size.shortestSide * 0.42;
    for (final Interval ring in _rings) {
      if (t <= ring.begin || t >= ring.end) continue;
      final double p = ring.transform(t);
      canvas.drawCircle(
        center,
        base * (0.9 + 0.9 * p),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * (1 - p) + 0.5
          ..color = color.withValues(alpha: 0.45 * (1 - p)),
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.t != t || old.color != color;
}

/// The wordmark's share of [BrandLogo.entrance]: it fades in while rising
/// 14px and its tracking tightens to the resting value.
class _WordmarkEntrance extends StatelessWidget {
  const _WordmarkEntrance({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  static const Curve _curve = Interval(0.35, 0.85, curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (BuildContext context, Widget? child) {
        final double p = _curve.transform(animation.value);
        return Opacity(
          opacity: p,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - p)),
            child: Transform.scale(scale: 0.96 + 0.04 * p, child: child),
          ),
        );
      },
    );
  }
}
