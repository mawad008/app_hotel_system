import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/guest_party.dart';
import '../../domain/entities/stay_range.dart';
import '../discovery_l10n.dart';
import '../state/guest_party_controller.dart';
import '../state/stay_dates_controller.dart';
import '../widgets/guest_party_sheet.dart';
import '../widgets/stay_range_calendar.dart';

/// `16 · Stay dates & available rooms` — the check-in / check-out picker plus
/// the guest count (the prototype's "R1 Dates & guests").
///
/// It only produces state (a [StayRange] plus the [GuestParty]); it does not
/// call an availability API or create a reservation. The guests field opens the
/// "عدد الضيوف" sheet so adults / children are set before the room list, which
/// only shows room types that can seat them. The CTA is disabled until both
/// dates are chosen and check-out is after check-in.
class StayDatesPage extends ConsumerWidget {
  const StayDatesPage({super.key, required this.hotelId});

  final String hotelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final MaterialLocalizations ml = MaterialLocalizations.of(context);

    final DateTime today = ref.today();
    final StayDatesDraft draft = ref.watch(stayDatesControllerProvider);
    final StayDatesController dates = ref.read(
      stayDatesControllerProvider.notifier,
    );

    final StayRange? range = draft.rangeAgainst(today);
    final GuestParty party = ref.watch(guestPartyControllerProvider);
    final String? errorText = l10n.stayDatesErrorLabel(
      draft.errorAgainst(today),
    );

    // Which field the next tap fills — gets the highlighted border.
    final bool checkInActive = draft.checkIn == null || draft.checkOut != null;

    final String guidance;
    final bool guidanceIsError;
    if (errorText != null) {
      guidance = errorText;
      guidanceIsError = true;
    } else if (range != null) {
      guidance =
          '${l10n.stayDatesSelectedRange(ml.formatMediumDate(range.checkIn), ml.formatMediumDate(range.checkOut))} · ${l10n.stayNights(range.nights)}';
      guidanceIsError = false;
    } else if (draft.checkIn != null) {
      guidance = l10n.stayDatesHintPickCheckOut(
        ml.formatMediumDate(draft.checkIn!),
      );
      guidanceIsError = false;
    } else {
      guidance = l10n.stayDatesHintPickCheckIn;
      guidanceIsError = false;
    }

    return Scaffold(
      appBar: HotelAppBar(
        title: l10n.stayDatesTitle,
        actions: <Widget>[
          if (!draft.isEmpty)
            TextButton(
              onPressed: dates.clear,
              child: Text(l10n.stayDatesClear),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageGutter,
                AppSpacing.sm,
                AppSpacing.pageGutter,
                AppSpacing.sm,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: _DateField(
                        label: l10n.stayDatesCheckIn,
                        value: draft.checkIn == null
                            ? null
                            : ml.formatMediumDate(draft.checkIn!),
                        active: checkInActive,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _DateField(
                        label: l10n.stayDatesCheckOut,
                        value: draft.checkOut == null
                            ? null
                            : ml.formatMediumDate(draft.checkOut!),
                        active: !checkInActive,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageGutter,
                0,
                AppSpacing.pageGutter,
                AppSpacing.sm,
              ),
              child: _GuestsField(
                summary: guestPartySummaryText(l10n, party),
                onTap: () => showGuestPartySheet(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageGutter,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  guidance,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: guidanceIsError ? theme.colorScheme.error : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageGutter,
                  AppSpacing.sm,
                  AppSpacing.pageGutter,
                  AppSpacing.xl,
                ),
                children: <Widget>[
                  StayRangeCalendar(
                    firstDay: today,
                    today: today,
                    checkIn: draft.checkIn,
                    checkOut: draft.checkOut,
                    onSelectDay: dates.selectDay,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.pageGutter),
        child: PrimaryButton(
          label: l10n.stayDatesShowRooms,
          onPressed: range == null
              ? null
              : () => context.pushNamed(
                  AppRoutes.availableRoomsName,
                  pathParameters: <String, String>{'hotelId': hotelId},
                ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.active,
  });

  final String label;
  final String? value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool filled = value != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? theme.colorScheme.primary : theme.colorScheme.outline,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              label,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              value ?? context.l10n.stayDatesFieldPlaceholder,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: theme.textTheme.titleMedium?.copyWith(
                color: filled
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.primary,
                fontWeight: filled ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "عدد الضيوف" field: the current party ("2 adults · 1 child") with an
/// edit affordance; tapping opens the guest-count sheet.
class _GuestsField extends StatelessWidget {
  const _GuestsField({required this.summary, required this.onTap});

  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;
    final BorderRadius radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      label: '${l10n.guestsTitle}: $summary',
      excludeSemantics: true,
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  AppIcons.guests,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(l10n.guestsTitle, style: theme.textTheme.bodySmall),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        summary,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.commonEdit,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
