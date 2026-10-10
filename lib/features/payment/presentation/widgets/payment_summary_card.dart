import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../domain/entities/payment.dart';
import 'payment_status_pill.dart';
import '../../../discovery/domain/entities/money.dart';
import '../../../discovery/presentation/widgets/price_breakdown_card.dart' show formatTaxRate;

/// The payment-screen recap: reservation reference / hotel / room / stay
/// dates / payment status, then the full cost breakdown — room rate × nights,
/// stay subtotal, taxes, service fee, booking total — and, separately, the
/// deposit hold the guest is asked for now. Every figure comes from the
/// authoritative [Reservation] (`price_snapshot`, `service_fee_amount`,
/// `tax_rate` / `tax_amount`,
/// `room_type.base_price`, `hotel.deposit_amount`, `hotel.prices_include_taxes`)
/// or the placed [payment]; the app computes nothing but the displayed sum the
/// backend's `total_amount` already mirrors.
class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({
    super.key,
    required this.reservation,
    required this.payment,
  });

  final Reservation reservation;
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final MaterialLocalizations ml = MaterialLocalizations.of(context);
    final Locale locale = Localizations.localeOf(context);
    final String currency = reservation.priceSnapshot.currency;
    // The deposit hold — the placed hold's amount, else what the server says
    // it will be (`hotel.deposit_amount`); never the stay total.
    final Money? deposit = payment.exists && payment.amount.amount > 0
        ? payment.amount
        : reservation.depositAmount;
    final Money? nightlyRate = reservation.nightlyRate;
    final bool? taxesIncluded = reservation.pricesIncludeTaxes;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Row(
            label: l10n.paymentReservationLabel,
            value: reservation.reference,
          ),
          const Divider(height: AppSpacing.lg),
          _Row(
            label: l10n.reviewHotelLabel,
            value: reservation.hotelName.resolve(locale),
          ),
          const SizedBox(height: AppSpacing.xs),
          _Row(
            label: l10n.reviewRoomLabel,
            value: reservation.roomName.resolve(locale),
          ),
          const Divider(height: AppSpacing.lg),
          _Row(
            label: l10n.reviewCheckInLabel,
            value: ml.formatFullDate(reservation.stay.checkIn),
          ),
          const SizedBox(height: AppSpacing.xs),
          _Row(
            label: l10n.reviewCheckOutLabel,
            value: ml.formatFullDate(reservation.stay.checkOut),
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.paymentStatusFieldLabel,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              PaymentStatusPill(status: payment.status),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Text(l10n.paymentBreakdownHeading, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          if (nightlyRate != null)
            _AmountRow(
              label: l10n.roomNightlyPriceLabel,
              amount: nightlyRate,
              suffix: l10n.priceNightSuffix,
            ),
          _TextRow(
            label: l10n.paymentNightsLabel,
            value: l10n.stayNights(reservation.nights),
          ),
          _AmountRow(
            label: l10n.bookingRoomSubtotal,
            amount: reservation.priceSnapshot,
          ),
          if (taxesIncluded == true)
            _TextRow(
              label: l10n.roomTaxesLabel,
              value: l10n.roomPriceIncludedValue,
            )
          else if (taxesIncluded == false)
            _AmountRow(
              label: reservation.taxRate == null
                  ? l10n.roomTaxesLabel
                  : l10n.bookingTaxRow(formatTaxRate(reservation.taxRate)),
              amount: reservation.tax ?? Money(amount: 0, currency: currency),
            ),
          _AmountRow(
            label: l10n.bookingServiceFee,
            amount: reservation.serviceFee ?? Money(amount: 0, currency: currency),
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.paymentBookingTotalLabel,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              MoneyText(
                reservation.totalToPay.amount,
                currency: reservation.totalToPay.currency,
                style: theme.textTheme.titleSmall,
                color: context.colors.textPrimary,
              ),
            ],
          ),
          if (deposit != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.paymentCardDepositLabel,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        l10n.paymentDepositHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                MoneyText(
                  deposit.amount,
                  currency: deposit.currency,
                  style: theme.textTheme.titleMedium,
                  color: context.colors.textPrimary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A breakdown line: secondary label, amount at the end.
class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.amount, this.suffix});

  final String label;
  final Money amount;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return _Line(
      label: label,
      trailing: MoneyText(
        amount.amount,
        currency: amount.currency,
        suffix: suffix,
        markSize: 12,
        style: theme.textTheme.bodyMedium,
        color: context.colors.textPrimary,
      ),
    );
  }
}

/// A breakdown line whose value is text (night count, "included" taxes).
class _TextRow extends StatelessWidget {
  const _TextRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _Line(
      label: label,
      trailing: Text(value, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 110,
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
      ],
    );
  }
}
