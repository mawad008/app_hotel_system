import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/presentation/latin_digits_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/bottom_action_bar.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/state/reservation_detail_provider.dart';
import '../../domain/entities/payment_request.dart';
import '../state/payment_controller.dart';

/// `03 · Pay & Verify` — collect a new card's display fields before
/// confirming the deposit hold (`PAYMENT_CardDetails`).
///
/// The card number and cardholder name are local, display-only input: they
/// are validated for shape only, never transmitted or persisted. The approved
/// hold contract (`PaymentHoldRequest`) carries no card data at all — the MVP
/// dummy gateway needs none (mobile/docs/architecture.md §8) — so confirming
/// here submits the exact same hold request the review/method screens do.
class PaymentCardDetailsPage extends ConsumerStatefulWidget {
  const PaymentCardDetailsPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  ConsumerState<PaymentCardDetailsPage> createState() =>
      _PaymentCardDetailsPageState();
}

class _PaymentCardDetailsPageState
    extends ConsumerState<PaymentCardDetailsPage> {
  final TextEditingController _cardNumber = TextEditingController();
  final TextEditingController _cardholderName = TextEditingController();

  @override
  void dispose() {
    _cardNumber.dispose();
    _cardholderName.dispose();
    super.dispose();
  }

  bool get _canConfirm =>
      _cardNumber.text.replaceAll(' ', '').length >= 12 &&
      _cardholderName.text.trim().isNotEmpty;

  void _confirm(Reservation reservation) {
    ref
        .read(paymentControllerProvider.notifier)
        .submit(PaymentHoldRequest.forReservation(reservation));
    context.pushNamed(
      AppRoutes.paymentProcessingName,
      pathParameters: <String, String>{'reservationId': widget.reservationId},
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final AsyncValue<Reservation> reservationAsync = ref.watch(
      reservationDetailProvider(widget.reservationId),
    );

    return Scaffold(
      appBar: HotelAppBar(title: l10n.paymentCardDetailsTitle),
      body: SafeArea(
        child: reservationAsync.maybeWhen(
          data: (Reservation reservation) => ListView(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            children: <Widget>[
              // `PAYMENT_CardDetails`: the deposit (not the stay total), then
              // the "held, not charged" notice pill.
              if (reservation.depositAmount != null) ...<Widget>[
                Text(l10n.paymentCardDepositLabel, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xxs),
                MoneyText(
                  reservation.depositAmount!.amount,
                  currency: reservation.depositAmount!.currency,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _HoldNotice(text: l10n.paymentHoldNotice),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.paymentCardNumberLabel, style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xxs),
              TextField(
                controller: _cardNumber,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  const LatinDigitsFormatter(),
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                  LengthLimitingTextInputFormatter(23),
                ],
                decoration: InputDecoration(hintText: l10n.paymentCardNumberHint),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.paymentCardholderNameLabel,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              TextField(
                controller: _cardholderName,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.paymentCardNotStoredNote,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          orElse: () => Center(child: LoadingView(label: l10n.stateLoadingTitle)),
        ),
      ),
      bottomNavigationBar: BottomActionBar.actions(
        primary: PrimaryButton(
          label: l10n.paymentConfirmCta,
          onPressed: (_canConfirm && reservationAsync.valueOrNull != null)
              ? () => _confirm(reservationAsync.valueOrNull!)
              : null,
        ),
      ),
    );
  }
}

/// The info-tone pill under the amount: shield glyph + one line.
class _HoldNotice extends StatelessWidget {
  const _HoldNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: c.infoBg,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: c.infoBorder),
      ),
      child: Row(
        children: <Widget>[
          Icon(AppIcons.shieldTickOutline, size: 18, color: c.textPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    color: c.infoFg,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
