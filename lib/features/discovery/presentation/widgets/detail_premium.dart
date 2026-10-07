import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_icons.dart';
import '../state/hotel_detail_provider.dart';
import 'hero_photo_carousel.dart';

/// Building blocks shared by the v2 *Premium* detail screens
/// (`HOTEL_Detail_Premium`, `ROOM_Detail_Premium`).

/// The rounded photo card at the top of a Premium detail screen (Figma
/// `hero` / `hero room`, radius 28): the swipeable [HeroPhotoCarousel] under a
/// black 0 → 15% → 78% gradient, a frosted back button at the reading start,
/// optional [actions] (Figma `right-actions`: share + favourite) at the
/// reading end, a `1/N` photo counter and optional [copy] at the bottom.
class DetailHeroCard extends ConsumerWidget {
  const DetailHeroCard({
    super.key,
    required this.entityId,
    required this.photos,
    required this.aspectRatio,
    this.copy,
    this.actions = const <Widget>[],
    this.centerCounter = false,
    this.backFallbackLocation = AppRoutes.discover,
  });

  final String entityId;
  final List<String> photos;

  /// Figma card box on the 393 frame (361×371 hotel, 361×358 room).
  final double aspectRatio;

  /// Bottom-start content (the hotel's name / location / rating).
  final Widget? copy;

  /// Top-end [DetailHeroButton]s, 8px apart, laid out in reading order —
  /// the last child sits at the outer edge (RTL: `[favourite][share] … [→]`).
  final List<Widget> actions;

  /// Room hero: the counter sits alone, centred. Hotel hero: at the end,
  /// beside [copy].
  final bool centerCounter;

  /// Where back goes when there is nothing to pop — the screen was reached
  /// with `go` (post-sign-in return, deep link, restored location), so it is
  /// the root of the stack.
  final String backFallbackLocation;

  static const double _radius = 28;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int index = ref.watch(heroPhotoIndexProvider(entityId));
    final Widget? counter = photos.length > 1
        ? _GlassPill(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${index + 1}/${photos.length}',
                style: AppTypography.numXs(AppPrimitives.white)
                    .copyWith(fontSize: 12, fontWeight: AppTypography.regular),
              ),
            ),
          )
        : null;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(_radius)),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                HeroPhotoCarousel(
                  entityId: entityId,
                  photos: photos,
                  height: box.maxHeight,
                ),
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Color(0x00000000),
                          Color(0x26000000),
                          Color(0xC7000000),
                        ],
                        stops: <double>[0, 0.5, 1],
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 12,
                  start: 12,
                  child: DetailHeroButton(
                    icon: AppIcons.heroBackFor(Directionality.of(context)),
                    tooltip: context.l10n.commonBack,
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(backFallbackLocation),
                  ),
                ),
                if (actions.isNotEmpty)
                  PositionedDirectional(
                    top: 12,
                    end: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        for (int i = 0; i < actions.length; i++) ...<Widget>[
                          if (i > 0) const SizedBox(width: AppSpacing.space2),
                          actions[i],
                        ],
                      ],
                    ),
                  ),
                if (copy != null || counter != null)
                  Positioned(
                    left: AppSpacing.space4,
                    right: AppSpacing.space4,
                    bottom: AppSpacing.space4,
                    child: centerCounter
                        ? Center(child: counter)
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Expanded(child: copy ?? const SizedBox.shrink()),
                              if (counter != null) ...<Widget>[
                                const SizedBox(width: 6),
                                counter,
                              ],
                            ],
                          ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Figma hero `back-button` / `favorite-button` / `share-button`: a 32px
/// frosted circle (white @90% over a 9.6px backdrop blur, 0.8px white @42%
/// ring) with a 14.4px glyph (`text/primary`, or [iconColor]).
class DetailHeroButton extends StatelessWidget {
  const DetailHeroButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor,
    this.selected,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? iconColor;

  /// Toggle buttons (favourite) expose their state to screen readers.
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: selected,
      child: Tooltip(
        message: tooltip,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4.8, sigmaY: 4.8),
            child: Material(
              color: AppPrimitives.white.withValues(alpha: 0.9),
              shape: CircleBorder(
                side: BorderSide(
                  color: AppPrimitives.white.withValues(alpha: 0.42),
                  width: 0.8,
                ),
              ),
              child: InkWell(
                onTap: onPressed,
                customBorder: const CircleBorder(),
                child: SizedBox.square(
                  dimension: 32,
                  child: Icon(
                    icon,
                    size: 14.4,
                    color: iconColor ?? context.colors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma hero pills: white @12% with a 1px white @20% ring, 10/6 padding.
class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppPrimitives.white.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        border: Border.all(color: AppPrimitives.white.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }
}

/// The hotel hero's bottom copy (Figma `hero-copy`): name (18 Medium),
/// location (12, white @85%) and — when the hotel has a guest rating — the
/// review count, a dot and a glass rating pill.
class HotelHeroCopy extends StatelessWidget {
  const HotelHeroCopy({
    super.key,
    required this.name,
    required this.location,
    this.rating,
    this.reviewCount,
  });

  final String name;
  final String location;
  final double? rating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.titleLarge?.copyWith(
            color: AppPrimitives.white,
            fontWeight: AppTypography.medium,
            height: 23 / 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          location,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.labelSmall?.copyWith(
            color: AppPrimitives.white.withValues(alpha: 0.85),
            height: 15 / 12,
          ),
        ),
        if (rating != null) ...<Widget>[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (reviewCount != null) ...<Widget>[
                Text(
                  l10n.hotelReviewCount(reviewCount!),
                  style: text.labelMedium?.copyWith(
                    color: AppPrimitives.white.withValues(alpha: 0.8),
                    height: 16 / 13,
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppPrimitives.white.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
              ],
              _GlassPill(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        l10n.hotelRatingValue(rating!),
                        style: AppTypography.numXs(AppPrimitives.white)
                            .copyWith(
                              fontSize: 13,
                              fontWeight: AppTypography.bold,
                            ),
                      ),
                      const SizedBox(width: 4),
                      // Figma: white Hicon `Bold / Star 1` in the glass pill.
                      const Icon(
                        AppIcons.homeRatingStar,
                        size: 14,
                        color: AppPrimitives.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A Premium section heading: title (16 Medium / 20) over an optional
/// subtitle (12 Regular, `text/label`), 8px apart.
class DetailSectionHeading extends StatelessWidget {
  const DetailSectionHeading({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppColorTokens c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(title, style: detailTitleStyle(context)),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: AppSpacing.space2),
          Text(
            subtitle!,
            style: text.labelSmall?.copyWith(color: c.textLabel, height: 1.25),
          ),
        ],
      ],
    );
  }
}

/// The Premium section/card title style: 16 Medium, `text/primary`.
TextStyle? detailTitleStyle(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: 16,
      height: 20 / 16,
      fontWeight: AppTypography.medium,
      color: context.colors.textPrimary,
    );

/// A Premium content card: white, radius 20, 0.5px `border/default`, 16px
/// padding.
class DetailCard extends StatelessWidget {
  const DetailCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: c.borderDefault, width: 0.5),
      ),
      child: child,
    );
  }
}

/// Figma quick-info row: a 36px `#F6F6F6` tile (radius 12) with an 18px
/// gold glyph at the start, then a label (14, `text/label`) over a value (12,
/// `text/secondary`).
class DetailInfoRow extends StatelessWidget {
  const DetailInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppColorTokens c = context.colors;
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppPrimitives.mist,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          // Figma: Lucide glyph in `gold/400` (1px stroke).
          child: Icon(icon, size: 18, color: c.accentWarm),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: text.bodySmall?.copyWith(
                  color: c.textLabel,
                  height: 18 / 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: text.labelSmall?.copyWith(
                  color: c.textSecondary,
                  height: 15 / 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Figma `Rating Row`: label (14, `text/label`) at the start, a 6px pill track
/// (`stone/200`) filled in `bg/primary` from the start, and the score (13
/// Medium, tabular) at the end — 12px gaps. Always one decimal (`5.0`).
class DetailRatingRow extends StatelessWidget {
  const DetailRatingRow({
    super.key,
    required this.label,
    required this.value,
    this.valueText,
    this.icon,
  });

  final String label;

  /// Score out of 5, or `null` for "no reviews yet" (then only [valueText]).
  final double? value;

  /// Overrides the formatted score (e.g. a count or "no reviews yet").
  final String? valueText;

  /// Optional dashboard-selected review-category icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppColorTokens c = context.colors;
    final NumberFormat format = NumberFormat('0.0', context.l10n.localeName);
    final Widget label = Row(
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 16, color: c.accentWarm),
          const SizedBox(width: AppSpacing.space2),
        ],
        Expanded(
          child: Text(
            this.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: c.textLabel, height: 1.2),
          ),
        ),
      ],
    );
    final Widget score = Text(
      valueText ?? format.format(value),
      style: AppTypography.numXs(c.textPrimary)
          .copyWith(fontSize: 13, height: 16 / 13),
    );
    return SizedBox(
      height: 28,
      child: Row(
        children: value == null
            // No score yet: no empty track — the label takes the room.
            ? <Widget>[
                Expanded(child: label),
                const SizedBox(width: AppSpacing.space3),
                score,
              ]
            : <Widget>[
                Expanded(flex: 3, child: label),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(999)),
                    child: LinearProgressIndicator(
                      value: (value! / 5).clamp(0, 1),
                      minHeight: 6,
                      color: c.bgPrimary,
                      backgroundColor: c.borderDefault,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                score,
              ],
      ),
    );
  }
}

/// Figma `facility-grid` / room-facts tile: `#F6F6F6`, radius 16, a gold
/// 18px glyph, 10px gap and a label (12). Laid out two per row by [DetailTileGrid]. An operator-set
/// [description] (not in the Figma, which shows none) goes on a second,
/// muted line when present.
class DetailFacilityPill extends StatelessWidget {
  const DetailFacilityPill({
    super.key,
    required this.icon,
    required this.label,
    this.description,
  });

  final IconData icon;
  final String label;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppColorTokens c = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppPrimitives.mist,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: c.accentWarm),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: text.labelSmall?.copyWith(
                    color: c.textPrimary,
                    height: 15 / 12,
                  ),
                ),
                if (description != null && description!.isNotEmpty)
                  Text(
                    description!,
                    style: text.labelSmall?.copyWith(
                      color: c.textSecondary,
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                      height: 14 / 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays [children] out two per row with 12px gaps (Figma 2-column grids).
class DetailTileGrid extends StatelessWidget {
  const DetailTileGrid({
    super.key,
    required this.children,
    this.columns = 2,
    this.gap = AppSpacing.space3,
  });

  final List<Widget> children;
  final int columns;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double width = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final Widget child in children)
              SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// The white bottom bar of a Premium screen: 1px `border/default` top hairline
/// and an upward soft shadow (black @7%, blur 18, y −6), over the device's
/// bottom safe area.
class DetailBottomBar extends StatelessWidget {
  const DetailBottomBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 8),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border(top: BorderSide(color: c.borderDefault)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
