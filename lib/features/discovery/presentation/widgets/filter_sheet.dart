import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/hotel_filters.dart';
import '../discovery_l10n.dart';
import '../state/cities_provider.dart';
import '../state/price_bounds_provider.dart';
import 'sheet_scaffold.dart';

/// `15 · Search, filters & sort` — "تصفية النتائج". Returns the composed
/// [HotelFilters], or `null` if dismissed. City (multi-select), price range
/// and facilities are real, server-applied filters. "التقييم" (rating) is
/// rendered locked, matching the reference exactly — no approved threshold
/// rule exists to filter by yet.
Future<HotelFilters?> showFilterSheet(
  BuildContext context, {
  required HotelFilters current,
  required int matchCount,
}) {
  return showModalBottomSheet<HotelFilters>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) =>
        _FilterSheet(current: current, matchCount: matchCount),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.current, required this.matchCount});

  final HotelFilters current;
  final int matchCount;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late Set<String> _cityIds = Set<String>.of(widget.current.cityIds);
  late Set<HotelAmenity> _facilities = Set<HotelAmenity>.of(widget.current.facilities);
  RangeValues? _price;

  void _syncPrice(PriceRange bounds) {
    _price ??= RangeValues(
      (widget.current.priceRange?.min ?? bounds.min).toDouble(),
      (widget.current.priceRange?.max ?? bounds.max).toDouble(),
    );
  }

  HotelFilters _compose(PriceRange bounds) {
    final RangeValues price = _price ??
        RangeValues(bounds.min.toDouble(), bounds.max.toDouble());
    final bool priceTouched =
        price.start.round() != bounds.min || price.end.round() != bounds.max;
    return HotelFilters(
      cityIds: _cityIds,
      priceRange: priceTouched
          ? PriceRange(min: price.start.round(), max: price.end.round())
          : null,
      facilities: _facilities,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<City>> cities = ref.watch(citiesProvider);
    final AsyncValue<PriceRange> bounds = ref.watch(priceBoundsProvider);
    final Locale locale = Localizations.localeOf(context);

    final PriceRange? resolvedBounds = bounds.value;
    if (resolvedBounds != null) _syncPrice(resolvedBounds);

    return SheetScaffold(
      title: l10n.filterTitle,
      body: <Widget>[
        Text(
          l10n.filterMatchCount(widget.matchCount),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(l10n.filterHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.lg),

        // ── City ─────────────────────────────────────────────────────────
        Text(l10n.filterCityLabel, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        cities.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: LinearProgressIndicator(),
          ),
          error: (Object _, StackTrace _) =>
              Text(l10n.errorGeneric, style: Theme.of(context).textTheme.bodySmall),
          data: (List<City> list) => Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              for (final City city in list)
                FilterChip(
                  label: Text(
                    '${city.name.resolve(locale)} · ${l10n.cityHotelCount(city.hotelCount)}',
                  ),
                  selected: _cityIds.contains(city.id),
                  onSelected: (bool value) => setState(() {
                    if (value) {
                      _cityIds = <String>{..._cityIds, city.id};
                    } else {
                      _cityIds = _cityIds.where((String id) => id != city.id).toSet();
                    }
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Price range ──────────────────────────────────────────────────
        Text(l10n.filterPriceLabel, style: Theme.of(context).textTheme.titleSmall),
        bounds.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: LinearProgressIndicator(),
          ),
          error: (Object _, StackTrace _) =>
              Text(l10n.errorGeneric, style: Theme.of(context).textTheme.bodySmall),
          data: (PriceRange b) {
            if (b.min >= b.max) {
              return Text(
                l10n.priceRangeValue(b.min, b.max),
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
            final RangeValues value = _price!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.priceRangeValue(value.start.round(), value.end.round()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                RangeSlider(
                  min: b.min.toDouble(),
                  max: b.max.toDouble(),
                  divisions: (b.max - b.min).clamp(1, 100),
                  values: value,
                  labels: RangeLabels('${value.start.round()}', '${value.end.round()}'),
                  onChanged: (RangeValues next) => setState(() => _price = next),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Facilities ───────────────────────────────────────────────────
        Text(l10n.filterFacilitiesLabel, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            for (final HotelAmenity amenity in HotelAmenity.values)
              FilterChip(
                label: Text(l10n.hotelAmenityLabel(amenity)),
                selected: _facilities.contains(amenity),
                onSelected: (bool value) => setState(() {
                  if (value) {
                    _facilities = <HotelAmenity>{..._facilities, amenity};
                  } else {
                    _facilities =
                        _facilities.where((HotelAmenity a) => a != amenity).toSet();
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Rating — locked (no approved threshold rule) ────────────────────
        _LockedFilterRow(label: l10n.filterRatingLabel),
      ],
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PrimaryButton(
            label: l10n.filterApply,
            onPressed: () => Navigator.of(context).pop(
              _compose(resolvedBounds ?? const PriceRange(min: 0, max: 0)),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SecondaryButton(
            label: l10n.filterClearAll,
            onPressed: () => Navigator.of(context).pop(HotelFilters.none),
          ),
        ],
      ),
    );
  }
}

/// A disabled filter row with a lock icon — matches `15 · Search, filters &
/// sort`'s treatment of "التقييم" (rating): shown, not hidden, but
/// non-interactive, since no approved rating-threshold rule exists yet.
class _LockedFilterRow extends StatelessWidget {
  const _LockedFilterRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    return Opacity(
      opacity: 0.5,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),
          Icon(AppIcons.locked, size: 18, color: c.textSecondary),
        ],
      ),
    );
  }
}
