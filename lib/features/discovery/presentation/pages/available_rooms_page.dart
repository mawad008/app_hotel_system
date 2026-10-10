import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/presentation/ui_state.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/ui_state_view.dart';
import '../../domain/entities/availability_request.dart';
import '../../domain/entities/availability_result.dart';
import '../../domain/entities/available_room.dart';
import '../../domain/entities/guest_party.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/entities/room_selection.dart';
import '../../domain/entities/room_sort.dart';
import '../../domain/entities/stay_range.dart';
import '../discovery_l10n.dart';
import '../room_list_filter.dart';
import '../state/guest_party_controller.dart';
import '../state/hotel_detail_provider.dart';
import '../state/room_availability_controller.dart';
import '../state/room_selection_controller.dart';
import '../state/stay_dates_controller.dart';
import '../widgets/guest_party_sheet.dart';
import '../widgets/room_sort_sheet.dart';
import '../widgets/room_filter_sheet.dart';
import '../widgets/room_summary_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/pull_to_refresh.dart';

/// `16 · Stay dates & available rooms` — the available-rooms list.
///
/// Availability is dummy data only — the mobile app never computes authoritative
/// availability (a later phase's Laravel API does). Tapping a room opens its
/// detail screen where it can be selected; nothing is booked here.
class AvailableRoomsPage extends ConsumerStatefulWidget {
  const AvailableRoomsPage({super.key, required this.hotelId});

  final String hotelId;

  @override
  ConsumerState<AvailableRoomsPage> createState() => _AvailableRoomsPageState();
}

class _AvailableRoomsPageState extends ConsumerState<AvailableRoomsPage> {
  bool _selectionClearedNotice = false;
  RoomListFilter _roomFilter = const RoomListFilter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  /// (Re)loads availability for the guest's current dates + party. A no-op when
  /// the dates are incomplete or the controller already holds a fresh result.
  void _sync() {
    final AvailabilityRequest? request = _currentRequest();
    if (request == null) return;
    ref.read(roomAvailabilityControllerProvider.notifier).load(request);
  }

  AvailabilityRequest? _currentRequest() {
    final StayRange? stay = ref
        .read(stayDatesControllerProvider)
        .rangeAgainst(ref.today());
    if (stay == null) return null;
    return AvailabilityRequest(
      hotelId: widget.hotelId,
      stay: stay,
      party: ref.read(guestPartyControllerProvider),
    );
  }

  void _openRoom(String roomTypeId) {
    context.pushNamed(
      AppRoutes.roomDetailName,
      pathParameters: <String, String>{
        'hotelId': widget.hotelId,
        'roomTypeId': roomTypeId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    ref.listen<StayDatesDraft>(stayDatesControllerProvider, (_, _) => _sync());
    ref.listen<GuestParty>(guestPartyControllerProvider, (_, _) => _sync());
    ref.listen<RoomSelection?>(roomSelectionControllerProvider, (
      RoomSelection? prev,
      RoomSelection? next,
    ) {
      if (prev != null && next == null && mounted) {
        setState(() => _selectionClearedNotice = true);
      }
    });

    final AvailabilityRequest? request = _currentRequest();
    final RoomAvailabilityState availability = ref.watch(
      roomAvailabilityControllerProvider,
    );
    if (request != null &&
        !availability.isFreshFor(request) &&
        availability.result is! UiLoading<AvailabilityResult>) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sync();
      });
    }

    final AsyncValue<Hotel> hotelAsync = ref.watch(
      hotelDetailProvider(widget.hotelId),
    );

    return hotelAsync.when(
      loading: () => Scaffold(
        appBar: HotelAppBar(title: l10n.roomsTitle),
        body: Center(child: LoadingView(label: l10n.stateLoadingTitle)),
      ),
      error: (Object error, StackTrace _) => Scaffold(
        appBar: HotelAppBar(title: l10n.roomsTitle),
        body: Center(
          child: ErrorView(
            title: l10n.stateErrorTitle,
            message: ErrorMapper.toFailure(error).localizedMessage(l10n),
            actionLabel: l10n.commonBack,
            onAction: () => context.pop(),
          ),
        ),
      ),
      data: (Hotel hotel) => _Loaded(
        hotel: hotel,
        selectionClearedNotice: _selectionClearedNotice,
        roomFilter: _roomFilter,
        onRoomFilterChanged: (RoomListFilter value) =>
            setState(() => _roomFilter = value),
        onDismissNotice: () => setState(() => _selectionClearedNotice = false),
        onOpenRoom: _openRoom,
      ),
    );
  }
}

class _Loaded extends ConsumerWidget {
  const _Loaded({
    required this.hotel,
    required this.selectionClearedNotice,
    required this.roomFilter,
    required this.onRoomFilterChanged,
    required this.onDismissNotice,
    required this.onOpenRoom,
  });

  final Hotel hotel;
  final bool selectionClearedNotice;
  final RoomListFilter roomFilter;
  final ValueChanged<RoomListFilter> onRoomFilterChanged;
  final VoidCallback onDismissNotice;
  final ValueChanged<String> onOpenRoom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final DateTime today = ref.today();
    final StayRange? range = ref
        .watch(stayDatesControllerProvider)
        .rangeAgainst(today);
    final GuestParty party = ref.watch(guestPartyControllerProvider);
    final RoomAvailabilityState state = ref.watch(
      roomAvailabilityControllerProvider,
    );
    final RoomSelection? selection = ref.watch(roomSelectionControllerProvider);

    if (range == null) {
      return Scaffold(
        appBar: HotelAppBar(title: l10n.roomsTitle),
        body: MessageView(
          icon: AppIcons.calendar,
          title: l10n.roomsNoResultsTitle,
          message: l10n.roomsNoResultsBody,
          actionLabel: l10n.roomsChangeDates,
          onAction: () => context.pop(),
        ),
      );
    }

    final AvailabilityRequest request = AvailabilityRequest(
      hotelId: hotel.id,
      stay: range,
      party: party,
    );
    final bool selectionMatches =
        selection != null && selection.matches(request);

    // Figma `content`: 12 top / 24 sides / 32 bottom, 16 between blocks — the
    // summary, the chips and the list all scroll together.
    final List<Widget> header = <Widget>[
      _StaySummaryCard(
        hotel: hotel,
        range: range,
        party: party,
        onEditDates: () => context.pop(),
        onEditGuests: () => showGuestPartySheet(context),
      ),
      const SizedBox(height: AppSpacing.space4),
      _SortRow(
        sort: state.sort,
        filter: roomFilter,
        onFilter: (RoomListFilter next) => onRoomFilterChanged(next),
        onPick: (RoomSort next) =>
            ref.read(roomAvailabilityControllerProvider.notifier).setSort(next),
      ),
      if (selectionClearedNotice) ...<Widget>[
        const SizedBox(height: AppSpacing.space4),
        GestureDetector(
          onTap: onDismissNotice,
          child: InfoBanner(
            tone: InfoBannerTone.warning,
            title: l10n.roomsSelectionClearedNotice,
          ),
        ),
      ],
    ];
    const EdgeInsets contentPadding = EdgeInsets.fromLTRB(
      AppSpacing.pageGutter,
      AppSpacing.space3,
      AppSpacing.pageGutter,
      AppSpacing.space7,
    );

    final UiState<AvailabilityResult> result = state.result;
    return Scaffold(
      // v2: a ✕ at the end of the bar, no back arrow.
      appBar: HotelAppBar(
        title: l10n.roomsTitle,
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            icon: const Icon(AppIcons.dismiss, size: 22),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: AppSpacing.space3),
        ],
      ),
      body: SafeArea(
        child: PullToRefresh(
          onRefresh: () =>
              ref.read(roomAvailabilityControllerProvider.notifier).refresh(),
          child: result is UiSuccess<AvailabilityResult>
              ? ListView(
                  padding: contentPadding,
                  children: <Widget>[
                    ...header,
                    const SizedBox(height: AppSpacing.space4),
                    ..._roomListChildren(
                      context,
                      result: result.data,
                      nights: range.nights,
                      selectedRoomTypeId: selectionMatches
                          ? selection.roomTypeId
                          : null,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: contentPadding.copyWith(bottom: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: header,
                      ),
                    ),
                    Expanded(
                      child: UiStateView<AvailabilityResult>(
                        state: result,
                        onRetry: () => ref
                            .read(roomAvailabilityControllerProvider.notifier)
                            .retry(),
                        emptyTitle: l10n.roomsNoResultsTitle,
                        emptyMessage: l10n.roomsNoResultsBody,
                        onSuccess: (_) => const SizedBox.shrink(),
                      ),
                    ),
                    if (result is UiEmpty<AvailabilityResult>)
                      _NoResultsActions(
                        onChangeDates: () => context.pop(),
                        onChangeGuests: () => showGuestPartySheet(context),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Figma `rooms label` + the `room card`s, 16 apart.
  List<Widget> _roomListChildren(
    BuildContext context, {
    required AvailabilityResult result,
    required int nights,
    required String? selectedRoomTypeId,
  }) {
    final AppLocalizations l10n = context.l10n;
    final RoomCardPalette palette = RoomCardPalette.of(context);
    final List<AvailableRoom> visibleRooms = result.rooms
        .where(roomFilter.matches)
        .toList();
    return <Widget>[
      if (result.isSoldOut) ...<Widget>[
        InfoBanner(
          tone: InfoBannerTone.warning,
          title: l10n.roomsAllSoldOutTitle,
          message: l10n.roomsAllSoldOutBody,
        ),
        const SizedBox(height: AppSpacing.space4),
      ],
      // Figma `rooms label`: 18 Bold title, 13 Medium stone/500 count.
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text(
              l10n.roomsTitle,
              style: AppTypography.textTheme(
                palette.title,
                palette.subtitle,
              ).titleLarge,
            ),
          ),
          Text(
            l10n.roomsAvailableCount(
              visibleRooms
                  .where((AvailableRoom room) => room.isAvailable)
                  .length,
            ),
            style: AppTypography.textTheme(
              palette.title,
              palette.subtitle,
            ).labelMedium,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.space4),
      if (visibleRooms.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(child: Text(l10n.roomsNoFilterMatch)),
        ),
      for (int i = 0; i < visibleRooms.length; i++) ...<Widget>[
        if (i > 0) const SizedBox(height: AppSpacing.space4),
        RoomSummaryCard(
          room: visibleRooms[i],
          nights: nights,
          selected: visibleRooms[i].roomType.id == selectedRoomTypeId,
          onViewDetails: () => onOpenRoom(visibleRooms[i].roomType.id),
        ),
      ],
    ];
  }
}

/// Figma `stay summary` (`ROOMS_Available`): a white 20px card with a 0.5px
/// `stone/200` outline, 16 padding, 14 between rows — hotel name (18 Bold) +
/// "تعديل التواريخ"; a hairline; arrival / departure columns (13 Medium
/// label over an 18 Bold `٦ سبتمبر` date); a hairline; "ليلتان · ٢ ضيوف
/// (بالغان)" + "تعديل".
class _StaySummaryCard extends StatelessWidget {
  const _StaySummaryCard({
    required this.hotel,
    required this.range,
    required this.party,
    required this.onEditDates,
    required this.onEditGuests,
  });

  final Hotel hotel;
  final StayRange range;
  final GuestParty party;
  final VoidCallback onEditDates;
  final VoidCallback onEditGuests;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Locale locale = Localizations.localeOf(context);
    final RoomCardPalette palette = RoomCardPalette.of(context);
    final TextTheme text = AppTypography.textTheme(
      palette.title,
      palette.subtitle,
    );
    // `٦ سبتمبر` — day + month only; intl's `ar` symbols give the
    // Arabic-Indic day the v2 numeral rule asks for.
    final DateFormat dayMonth = DateFormat('d MMMM', locale.toLanguageTag());
    final Widget hairline = Divider(
      height: 1,
      thickness: 1,
      color: palette.outline,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.outline, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  hotel.summary.name.resolve(locale),
                  style: text.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              _LinkButton(label: l10n.stayDatesEditDates, onTap: onEditDates),
            ],
          ),
          const SizedBox(height: 14),
          hairline,
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _DateColumn(
                  label: l10n.stayDatesCheckIn,
                  value: dayMonth.format(range.checkIn),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: _DateColumn(
                  label: l10n.stayDatesCheckOut,
                  value: dayMonth.format(range.checkOut),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          hairline,
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${l10n.stayNights(range.nights)}  ·  '
                  '${l10n.stayGuestsCount(party.adults + party.children)} '
                  '(${guestPartySummaryText(l10n, party)})',
                  style: text.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              _LinkButton(label: l10n.commonEdit, onTap: onEditGuests),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateColumn extends StatelessWidget {
  const _DateColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final RoomCardPalette palette = RoomCardPalette.of(context);
    final TextTheme text = AppTypography.textTheme(
      palette.title,
      palette.subtitle,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: text.labelMedium),
        const SizedBox(height: 2),
        Text(value, style: text.titleLarge),
      ],
    );
  }
}

/// Figma: a plain 13 Medium `ink/700` text action (no underline, no tint).
class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.allSm,
      child: Text(
        label,
        style: AppTypography.textTheme(
          RoomCardPalette.of(context).title,
          RoomCardPalette.of(context).link,
        ).labelMedium,
      ),
    );
  }
}

/// Figma `filter & sort`: two 40px white pills, 8 apart, 16 side padding,
/// a 14 Medium label and the soft two-layer shadow — filter first.
class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.sort,
    required this.filter,
    required this.onFilter,
    required this.onPick,
  });

  final RoomSort sort;
  final RoomListFilter filter;
  final ValueChanged<RoomListFilter> onFilter;
  final ValueChanged<RoomSort> onPick;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Row(
      children: <Widget>[
        _ChipButton(
          label: l10n.roomsFilterCta,
          onTap: () async {
            final RoomListFilter? picked = await showRoomFilterSheet(
              context,
              current: filter,
            );
            if (picked != null) onFilter(picked);
          },
        ),
        const SizedBox(width: AppSpacing.space2),
        _ChipButton(
          label: l10n.roomsSortTrigger(l10n.roomSortLabel(sort)),
          onTap: () async {
            final RoomSort? picked = await showRoomSortSheet(
              context,
              current: sort,
            );
            if (picked != null) onPick(picked);
          },
        ),
      ],
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  static const List<BoxShadow> _shadow = <BoxShadow>[
    BoxShadow(color: Color(0x0A101517), blurRadius: 2),
    BoxShadow(color: Color(0x0F101517), blurRadius: 3),
  ];

  @override
  Widget build(BuildContext context) {
    final RoomCardPalette palette = RoomCardPalette.of(context);
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.allPill,
        boxShadow: _shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: AppTypography.textTheme(palette.title, palette.subtitle)
                    .labelLarge
                    ?.copyWith(
                      fontWeight: AppTypography.medium,
                      height: 17 / 14,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoResultsActions extends StatelessWidget {
  const _NoResultsActions({
    required this.onChangeDates,
    required this.onChangeGuests,
  });

  final VoidCallback onChangeDates;
  final VoidCallback onChangeGuests;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.all(AppSpacing.pageGutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          PrimaryButton(label: l10n.roomsChangeDates, onPressed: onChangeDates),
          const SizedBox(height: AppSpacing.xs),
          SecondaryButton(
            label: l10n.roomsChangeGuests,
            onPressed: onChangeGuests,
          ),
        ],
      ),
    );
  }
}
