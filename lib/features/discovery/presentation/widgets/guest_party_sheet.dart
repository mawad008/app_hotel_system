import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/numerals.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/guest_party.dart';
import '../../domain/entities/room_selection.dart';
import '../state/guest_party_controller.dart';
import '../state/room_selection_controller.dart';
import 'guest_stepper.dart';
import 'sheet_scaffold.dart';

/// `16 · Stay dates & available rooms` — the "عدد الضيوف" sheet. Edits the
/// shared [guestPartyControllerProvider] directly and pops on confirm.
///
/// While a room is selected the steppers stop at that room's capacity and
/// say so, exactly like the booking-summary steppers — otherwise a party that
/// outgrows the room silently drops the selection (RoomSelectionController)
/// and the booking summary reports "no room selected".
Future<void> showGuestPartySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => const _GuestPartySheet(),
  );
}

class _GuestPartySheet extends ConsumerWidget {
  const _GuestPartySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final GuestParty party = ref.watch(guestPartyControllerProvider);
    final RoomSelection? selection = ref.watch(roomSelectionControllerProvider);
    final GuestPartyController controller =
        ref.read(guestPartyControllerProvider.notifier);

    final int maxAdults =
        selection?.maxAdultsWith(party.children) ?? GuestParty.maxAdults;
    final int maxChildren =
        selection?.maxChildrenWith(party.adults) ?? GuestParty.maxChildren;
    final bool atCapacity =
        selection != null && party.total >= selection.roomType.maxOccupancy;
    final ThemeData theme = Theme.of(context);

    return SheetScaffold(
      title: l10n.guestsTitle,
      body: <Widget>[
        GuestStepper(
          label: l10n.guestsAdults,
          value: party.adults,
          min: GuestParty.minAdults,
          max: maxAdults,
          onChanged: controller.setAdults,
        ),
        const SizedBox(height: AppSpacing.sm),
        GuestStepper(
          label: l10n.guestsChildren,
          value: party.children,
          min: GuestParty.minChildren,
          max: maxChildren,
          onChanged: controller.setChildren,
        ),
        if (atCapacity) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.localDigits(
              party.children == 0
                  ? l10n.roomMaxAdultsReached(maxAdults)
                  : l10n.roomMaxGuestsReached(selection.roomType.maxOccupancy),
            ),
            key: const ValueKey<String>('guest-sheet-capacity'),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.roomCapacityChangeRoomHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ],
      footer: PrimaryButton(
        label: l10n.guestsConfirm,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// The " · "-joined party summary, e.g. "2 adults · 1 child". The separator is a
/// visual glyph, not translatable copy.
String guestPartySummaryText(AppLocalizations l10n, GuestParty party) {
  final String adults = l10n.guestsAdultsCount(party.adults);
  if (party.children == 0) return adults;
  return '$adults · ${l10n.guestsChildrenCount(party.children)}';
}
