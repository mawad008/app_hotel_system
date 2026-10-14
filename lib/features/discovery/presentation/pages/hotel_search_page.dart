import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/presentation/ui_state.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/ui_state_view.dart';
import '../../domain/entities/hotel_search_result.dart';
import '../state/hotel_search_controller.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/hotel_search_field.dart';
import '../widgets/hotel_summary_card.dart';
import '../widgets/sort_chip_bar.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/pull_to_refresh.dart';

/// `15 · Search, filters & sort` — the search screen: a live search field, the
/// quick-sort chips, a filter button, the result count and the hotel list with
/// its loading / empty / no-results / error states.
class HotelSearchPage extends ConsumerStatefulWidget {
  const HotelSearchPage({super.key});

  @override
  ConsumerState<HotelSearchPage> createState() => _HotelSearchPageState();
}

class _HotelSearchPageState extends ConsumerState<HotelSearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(hotelSearchControllerProvider).query;
    _controller.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(hotelSearchControllerProvider.notifier).ensureLoaded(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  HotelSearchController get _controllerNotifier =>
      ref.read(hotelSearchControllerProvider.notifier);

  Future<void> _openFilters(HotelSearchState state) async {
    final UiState<HotelSearchResult> results = state.results;
    final int matchCount = results is UiSuccess<HotelSearchResult>
        ? results.data.totalCount
        : 0;
    final result = await showFilterSheet(
      context,
      current: state.filters,
      matchCount: matchCount,
    );
    if (result != null) _controllerNotifier.applyFilters(result);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final HotelSearchState state = ref.watch(hotelSearchControllerProvider);

    return Scaffold(
      appBar: HotelAppBar(title: l10n.discoverFeaturedSection),
      bottomNavigationBar: AppBottomNav(
        current: AppNavTab.home,
        onSelected: (AppNavTab tab) {
          if (tab == AppNavTab.home) {
            context.go(AppRoutes.discover);
            return;
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.navComingSoon)));
        },
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageGutter,
                AppSpacing.sm,
                AppSpacing.pageGutter,
                AppSpacing.xs,
              ),
              child: HotelSearchField(
                controller: _controller,
                autofocus: state.query.isEmpty,
                onChanged: _controllerNotifier.setQuery,
                onClear: () {
                  _controller.clear();
                  _controllerNotifier.clearQuery();
                },
                onFilterTap: () => _openFilters(state),
                filterBadgeCount: state.filters.activeCount,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageGutter,
              ),
              child: SortChipBar(
                selected: state.sort,
                onSelected: _controllerNotifier.setSort,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: PullToRefresh(
                onRefresh: _controllerNotifier.refresh,
                child: _Results(state: state),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.state});

  final HotelSearchState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    return UiStateView<HotelSearchResult>(
      state: state.results,
      onRetry: () => ref.read(hotelSearchControllerProvider.notifier).retry(),
      onSuccess: (HotelSearchResult result) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageGutter,
          0,
          AppSpacing.pageGutter,
          AppSpacing.xl,
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(
              l10n.searchResultsCount(result.totalCount),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          for (final hotel in result.hotels) ...<Widget>[
            HotelSummaryCard(
              hotel: hotel,
              onTap: () => context.pushNamed(
                AppRoutes.hotelDetailName,
                pathParameters: <String, String>{'hotelId': hotel.id},
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
      // Empty == the query / filters matched nothing.
      emptyTitle: l10n.searchNoResultsTitle,
      emptyMessage: l10n.searchNoResultsBody,
    );
  }
}
