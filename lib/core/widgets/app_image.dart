import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import 'app_icons.dart';

/// The real Figma imagery, addressed by *purpose* rather than by path.
///
/// Filenames keep the original Figma content hash (see
/// `mobile/Design/assets/manifest.json`) so every asset stays traceable to
/// the source. Nothing outside this file references an image path.
abstract final class AppImages {
  static const String _dir = 'assets/images';

  // ── Named slots (mapped from the Figma frames) ───────────────────────────

  /// Hotel tower at dusk — the full-bleed onboarding photo (v2 Figma
  /// `ENTRY_Onboarding` frame fill, image `3964702c…`).
  static const String entryHero = '$_dir/entry_onboarding.jpg';

  /// The Figma's own mini-map illustration (`location-section` → `mini-map`)
  /// — a decorative backdrop behind the Hotel Detail location pin, shown only
  /// when the hotel has real coordinates. Not a map of the actual location.
  static const String locationMiniMap = '$_dir/location_mini_map.jpg';

  /// AlUla landscape — the flagship hotel hero ("فندق الواحة").
  static const String hotelHero =
      '$_dir/02_32407aee78875a7aafe46054f84a7e671bb98208.png';

  /// Warm room interior — the room-detail hero.
  static const String roomHero =
      '$_dir/04_89cb64d400bf6ecb804e4f2f7eadac4f30379a08.jpg';

  // ── The full pool, in manifest order ────────────────────────────────────

  static const List<String> all = <String>[
    '$_dir/01_1ce2fe86e1210b2d74639ff3901e2fca59e4a352.jpg',
    '$_dir/02_32407aee78875a7aafe46054f84a7e671bb98208.png',
    '$_dir/03_6d2ba4197a4e33f4a782a334b5ea126ebd57dd8e.png',
    '$_dir/04_89cb64d400bf6ecb804e4f2f7eadac4f30379a08.jpg',
    '$_dir/05_8d58e59e0091620d43dacd928315f92c1e0fadae.png',
    '$_dir/06_8f904f899d29b6c869ca90ffabbbc79854937da3.jpg',
    '$_dir/07_a50049dcb99cc4319992ca90beeab0cb2766d0a3.jpg',
    '$_dir/08_aa952c3af5525787e169a59be6585c8c5e0280ee.jpg',
    '$_dir/09_b5b189f11426f1d30a9282ec354450e0d27e1775.jpg',
    '$_dir/10_b91e06ad771c30cd6f033e63ace539dd7249068b.jpg',
    '$_dir/11_d7f543b9397080a7e25c7302da8858468b895fc8.jpg',
    '$_dir/12_e68b89d483817b715f597b101253fc757e57c4d5.jpg',
    '$_dir/13_e93d92b52ce843caefc6d823839aec1880d67a3f.png',
  ];

  /// Landscape-ish subset for hotel / room cards and heroes.
  static const List<String> scenic = <String>[
    '$_dir/02_32407aee78875a7aafe46054f84a7e671bb98208.png',
    '$_dir/04_89cb64d400bf6ecb804e4f2f7eadac4f30379a08.jpg',
    '$_dir/09_b5b189f11426f1d30a9282ec354450e0d27e1775.jpg',
    '$_dir/10_b91e06ad771c30cd6f033e63ace539dd7249068b.jpg',
    '$_dir/01_1ce2fe86e1210b2d74639ff3901e2fca59e4a352.jpg',
    '$_dir/07_a50049dcb99cc4319992ca90beeab0cb2766d0a3.jpg',
    '$_dir/12_e68b89d483817b715f597b101253fc757e57c4d5.jpg',
  ];

  /// Small room-gallery thumbnails.
  static const List<String> roomThumbs = <String>[
    '$_dir/03_6d2ba4197a4e33f4a782a334b5ea126ebd57dd8e.png',
    '$_dir/05_8d58e59e0091620d43dacd928315f92c1e0fadae.png',
    '$_dir/13_e93d92b52ce843caefc6d823839aec1880d67a3f.png',
    '$_dir/06_8f904f899d29b6c869ca90ffabbbc79854937da3.jpg',
    '$_dir/08_aa952c3af5525787e169a59be6585c8c5e0280ee.jpg',
  ];

  /// Deterministically pick an image from [pool] for a stable [seed] (a hotel
  /// or room id). The same seed always maps to the same asset.
  static String forSeed(String seed, {List<String>? pool}) {
    final List<String> options = pool ?? scenic;
    final int hash = seed.codeUnits.fold<int>(7, (int a, int c) => a * 31 + c);
    return options[hash.abs() % options.length];
  }
}

/// Where every network image (hotel/room photos, the dashboard logo and
/// onboarding image) comes from, so they all share one cache.
///
/// In the app images are kept in a disk cache (`cached_network_image`): a
/// photo seen once loads instantly — and offline — on later screens and
/// launches instead of being downloaded again. Tests turn [diskCache] off
/// (no platform storage there) and get plain network images.
abstract final class AppNetworkImages {
  static bool diskCache = true;

  /// The longest edge an image is decoded at, in physical pixels: enough for
  /// a full-width hero on a 3x phone, without decoding 4K uploads.
  static const int maxDecodePx = 2048;

  /// [url] as an image provider, decoded at most [decodeWidth] physical
  /// pixels wide (height follows the aspect ratio) when given — decoding a
  /// large upload at thumbnail size saves memory and raster time.
  static ImageProvider provider(String url, {int? decodeWidth}) {
    final ImageProvider source =
        diskCache ? CachedNetworkImageProvider(url) : NetworkImage(url);
    if (decodeWidth == null) return source;
    return ResizeImage(
      source,
      width: math.min(decodeWidth, maxDecodePx),
      allowUpscaling: false,
    );
  }
}

/// Renders a Figma image asset with rounded clipping, a sensible [BoxFit], and a
/// graceful branded fallback if the asset is missing / fails to decode.
///
/// Use [AppImage.seeded] for cards/heroes that don't have a real per-entity
/// image yet — it maps a stable id to a deterministic Figma photo instead of a
/// gradient placeholder.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = AppRadius.allMd,
    this.fallbackIcon = AppIcons.hotel,
  }) : url = null;

  AppImage.seeded({
    super.key,
    required String seed,
    List<String>? pool,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = AppRadius.allMd,
    this.fallbackIcon = AppIcons.hotel,
  })  : asset = AppImages.forSeed(seed, pool: pool),
        url = null;

  /// Renders a **real, per-entity image URL** returned by the backend (a
  /// `logo_url` / `cover_url` / gallery `url`), never a local/Figma asset.
  ///
  /// `null`/empty [url] → the branded placeholder (no photograph). A
  /// non-empty [url] is shown via `Image.network` with a loading placeholder
  /// and, on any decode/network failure, the same branded placeholder — never
  /// a fake local asset. This is the only constructor real-API screens
  /// (hotel/room cards, hero, gallery) may use for per-entity imagery.
  const AppImage.network({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = AppRadius.allMd,
    this.fallbackIcon = AppIcons.hotel,
  }) : asset = null;

  final String? asset;
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final String? networkUrl = url;
    if (asset == null) {
      if (networkUrl == null || networkUrl.isEmpty) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: _Fallback(width: width, height: height, icon: fallbackIcon),
        );
      }
      return ClipRRect(
        borderRadius: borderRadius,
        child: _NetworkImage(
          url: networkUrl,
          width: width,
          height: height,
          fit: fit,
          fallbackIcon: fallbackIcon,
        ),
      );
    }
    return ClipRRect(
      borderRadius: borderRadius,
      // Bundled photos are large (up to a 1.4 MB PNG): decode them at the
      // size they are shown, like network images.
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int? decode = _decodeWidth(context, constraints, width, height);
          final ImageProvider image = decode == null
              ? AssetImage(asset!)
              : ResizeImage(
                  AssetImage(asset!),
                  width: math.min(decode, AppNetworkImages.maxDecodePx),
                  allowUpscaling: false,
                );
          return Image(
            image: image,
            width: width,
            height: height,
            fit: fit,
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stack) =>
                    _Fallback(width: width, height: height, icon: fallbackIcon),
          );
        },
      ),
    );
  }
}

/// A backend photo: decoded at the size it is shown, faded in over a
/// placeholder, and retried when a load fails (a dropped connection, a
/// timeout) — after 2 s, then 6 s — rather than leaving the slot empty until
/// the screen happens to rebuild. After the last attempt the placeholder
/// stays.
class _NetworkImage extends StatefulWidget {
  const _NetworkImage({
    required this.url,
    required this.width,
    required this.height,
    required this.fit,
    required this.fallbackIcon,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;

  /// The wait before each retry of a failed load.
  static const List<Duration> retryDelays = <Duration>[
    Duration(seconds: 2),
    Duration(seconds: 6),
  ];

  @override
  State<_NetworkImage> createState() => _NetworkImageState();
}

class _NetworkImageState extends State<_NetworkImage> {
  int _attempt = 0;
  Timer? _retry;

  @override
  void didUpdateWidget(_NetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _retry?.cancel();
      _retry = null;
      _attempt = 0;
    }
  }

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }

  void _scheduleRetry(ImageProvider failed) {
    if (_retry != null || _attempt >= _NetworkImage.retryDelays.length) {
      return;
    }
    _retry = Timer(_NetworkImage.retryDelays[_attempt], () async {
      // The failed load stays in the image cache while the widget listens
      // to it: drop it so the next attempt goes back to the network.
      await failed.evict();
      if (!mounted) return;
      setState(() {
        _retry = null;
        _attempt++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final String url = widget.url;
    final double? width = widget.width;
    final double? height = widget.height;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final ImageProvider image = AppNetworkImages.provider(
          url,
          decodeWidth: _decodeWidth(context, constraints, width, height),
        );
        return Image(
          // A fresh image state per attempt, so a retry resolves again.
          key: ValueKey<int>(_attempt),
          image: image,
          width: width,
          height: height,
          fit: widget.fit,
          // From memory: shown at once. Otherwise the placeholder until the
          // first frame, then a short fade-in instead of a pop.
          frameBuilder: (
            BuildContext context,
            Widget child,
            int? frame,
            bool wasSynchronouslyLoaded,
          ) {
            if (wasSynchronouslyLoaded) return child;
            return Stack(
              fit: StackFit.passthrough,
              children: <Widget>[
                Positioned.fill(
                  child: _Skeleton(width: width, height: height),
                ),
                AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: child,
                ),
              ],
            );
          },
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stack,
          ) {
            _scheduleRetry(image);
            // Debug-only diagnostics: a failed real image load must stay
            // visible to the developer instead of looking identical to "no
            // image field" — release builds never see this (kDebugMode is
            // compiled out of release binaries), so nothing leaks there.
            if (kDebugMode) {
              debugPrint('AppImage.network: failed to load "$url" — $error');
            }
            return _Fallback(
              width: width,
              height: height,
              icon: widget.fallbackIcon,
              debugFailedUrl: kDebugMode ? url : null,
              debugError: kDebugMode ? error : null,
            );
          },
        );
      },
    );
  }
}

/// Physical pixels to decode a network image at for the box it is shown in:
/// the longer edge, so `BoxFit.cover` stays sharp whichever way the photo
/// is cropped. `null` when the box is unbounded (decode as uploaded).
int? _decodeWidth(
  BuildContext context,
  BoxConstraints constraints,
  double? width,
  double? height,
) {
  final double w =
      width ?? (constraints.hasBoundedWidth ? constraints.maxWidth : 0);
  final double h =
      height ?? (constraints.hasBoundedHeight ? constraints.maxHeight : 0);
  final double edge = math.max(w, h);
  if (edge <= 0 || !edge.isFinite) return null;
  return (edge * MediaQuery.devicePixelRatioOf(context)).ceil();
}

/// A neutral shimmer-less loading box shown while a network image decodes —
/// the Figma-appropriate placeholder for imagery, not a full-screen spinner.
class _Skeleton extends StatelessWidget {
  const _Skeleton({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    return Container(width: width, height: height, color: c.bgSubtle);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    this.width,
    this.height,
    required this.icon,
    this.debugFailedUrl,
    this.debugError,
  });

  final double? width;
  final double? height;
  final IconData icon;

  /// Set only in debug builds, only when this fallback is standing in for a
  /// URL that actually failed to load (never for a simply-absent URL) — see
  /// [AppImage.network]'s `errorBuilder`.
  final String? debugFailedUrl;
  final Object? debugError;

  @override
  Widget build(BuildContext context) {
    // Figma renders unfilled image slots as a plain warm-grey box — match that
    // rather than a branded gradient.
    final AppColorTokens c = context.colors;
    final bool isDebugLoadFailure = kDebugMode && debugFailedUrl != null;
    final Widget box = Container(
      width: width,
      height: height,
      color: c.bgSubtle,
      child: Center(
        child: Icon(
          isDebugLoadFailure ? Icons.broken_image_outlined : icon,
          size: 26,
          color: isDebugLoadFailure ? c.errorFg : c.textSecondary,
        ),
      ),
    );
    if (!isDebugLoadFailure) return box;
    // Debug-only affordance so a real network/decode failure is visibly
    // distinct from "this entity has no photo" while developing — a hover
    // (desktop/web) or long-press (mobile) surfaces the failing URL and
    // error instead of a silent grey box. Compiled out of release builds.
    return Tooltip(
      message: 'Image failed to load:\n$debugFailedUrl\n$debugError',
      child: box,
    );
  }
}
