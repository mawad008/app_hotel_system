import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bookings/presentation/state/bookings_providers.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/numerals.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../reservation/domain/entities/extend_stay.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/state/reservation_detail_provider.dart';
import '../../../reservation/presentation/state/reservation_providers.dart';

/// The "تمديد الإقامة" flow from `STAY_Home`. Figma only designed the hub
/// screen, not a dedicated extend-stay board, so this follows the app's
/// standard single-screen review-and-confirm shape (date picker → primary
/// button → inline result) rather than inventing a multi-step flow. The
/// backend is authoritative for the price and the new checkout date — the
/// nights count shown before submitting is provisional display only.
class ExtendStayPage extends ConsumerStatefulWidget {
  const ExtendStayPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  ConsumerState<ExtendStayPage> createState() => _ExtendStayPageState();
}

class _ExtendStayPageState extends ConsumerState<ExtendStayPage> {
  DateTime? _newCheckOut;
  bool _submitting = false;
  ExtendStayResult? _result;
  Object? _error;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<Reservation> async =
        ref.watch(reservationDetailProvider(widget.reservationId));

    return Scaffold(
      appBar: HotelAppBar(title: l10n.extendStayTitle),
      body: SafeArea(
        child: async.when(
          loading: () => Center(child: LoadingView(label: l10n.stateLoadingTitle)),
          error: (Object error, StackTrace _) {
            final failure = ErrorMapper.toFailure(error);
            return MessageView(
              icon: AppIcons.warning,
              title: l10n.bookingNotFoundTitle,
              message: failure.localizedMessage(l10n),
            );
          },
          data: (Reservation reservation) => _Body(
            reservation: reservation,
            newCheckOut: _newCheckOut,
            submitting: _submitting,
            result: _result,
            error: _error,
            onPickDate: () => _pickDate(reservation),
            onSubmit: () => _submit(reservation),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(Reservation reservation) async {
    final DateTime initial = reservation.stay.checkOut.add(const Duration(days: 1));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: initial,
      lastDate: initial.add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _newCheckOut = picked);
  }

  Future<void> _submit(Reservation reservation) async {
    final DateTime? newCheckOut = _newCheckOut;
    if (newCheckOut == null || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final ExtendStayResult result = await ref.read(reservationRepositoryProvider).extend(
            ExtendStayRequest(
              reservationId: reservation.id,
              newCheckOut: newCheckOut,
            ),
          );
      refreshGuestReservations(ref.invalidate, reservationId: reservation.id);
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.reservation,
    required this.newCheckOut,
    required this.submitting,
    required this.result,
    required this.error,
    required this.onPickDate,
    required this.onSubmit,
  });

  final Reservation reservation;
  final DateTime? newCheckOut;
  final bool submitting;
  final ExtendStayResult? result;
  final Object? error;
  final VoidCallback onPickDate;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final MaterialLocalizations ml = MaterialLocalizations.of(context);

    if (result != null) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.pageGutter),
        children: <Widget>[
          InfoBanner(
            tone: InfoBannerTone.success,
            title: l10n.extendStaySuccessTitle,
            message: l10n.extendStaySuccessBody(
              ml.formatMediumDate(result!.newCheckOut),
              MoneyText.plain(context, result!.amount.amount, currency: result!.amount.currency),
            ),
          ),
        ],
      );
    }

    final int provisionalNights = newCheckOut == null
        ? 0
        : newCheckOut!.difference(reservation.stay.checkOut).inDays;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageGutter),
      children: <Widget>[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l10n.extendStayNewCheckOutLabel, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton(
                onPressed: onPickDate,
                child: Text(
                  newCheckOut == null
                      ? l10n.extendStayNewCheckOutLabel
                      : ml.formatMediumDate(newCheckOut!),
                ),
              ),
              if (newCheckOut != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.extendStayNightsAddedLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(context.localDigits('$provisionalNights'), style: Theme.of(context).textTheme.titleMedium),
              ],
            ],
          ),
        ),
        if (error != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          InfoBanner(
            tone: InfoBannerTone.error,
            title: l10n.stateErrorTitle,
            message: ErrorMapper.toFailure(error!).localizedMessage(l10n),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: l10n.extendStayCta,
          onPressed: newCheckOut == null || submitting ? null : onSubmit,
          isLoading: submitting,
        ),
      ],
    );
  }
}
