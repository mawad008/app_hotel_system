import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/money_text.dart';
import '../../domain/entities/money.dart';
import '../state/booking_price.dart';

/// "15" for 15.00, "7.5" for 7.50 — the % shown in the tax row label.
String formatTaxRate(num? rate) {
  if (rate == null) return '';
  return rate == rate.roundToDouble()
      ? rate.toInt().toString()
      : rate.toString();
}

/// The stay-subtotal / service-fee / tax / total card on the booking summary
/// (`BOOKING_Summary`). The service-fee row is shown only when
/// [BookingPriceBreakdown.serviceFee] is non-null (design-only mock — see
/// `booking_price.dart`).
class PriceBreakdownCard extends StatelessWidget {
  const PriceBreakdownCard({super.key, required this.breakdown});

  final BookingPriceBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Row(label: l10n.bookingRoomSubtotal, amount: breakdown.roomSubtotal),
          if (breakdown.serviceFee != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            _Row(label: l10n.bookingServiceFee, amount: breakdown.serviceFee!),
          ],
          if (breakdown.tax != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            _Row(
              label: l10n.bookingTaxRow(formatTaxRate(breakdown.taxRate)),
              amount: breakdown.tax!,
            ),
          ],
          if (breakdown.loyaltyDiscount != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            _Row(
              label: l10n.bookingLoyaltyDiscountRow,
              amount: breakdown.loyaltyDiscount!,
              negative: true,
            ),
          ],
          const Divider(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                // v2 total row: 20 bold label, 17 bold amount.
                child: Text(l10n.bookingTotal, style: theme.textTheme.headlineSmall),
              ),
              MoneyText(
                breakdown.total.amount, currency: breakdown.total.currency,
                style: theme.textTheme.titleMedium,
                color: context.colors.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.amount, this.negative = false});

  final String label;
  final Money amount;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
        if (negative)
          Text('−', style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.successFg)),
        MoneyText(
          amount.amount, currency: amount.currency,
          style: theme.textTheme.bodyMedium,
          color: negative ? context.colors.successFg : context.colors.textPrimary,
        ),
      ],
    );
  }
}
