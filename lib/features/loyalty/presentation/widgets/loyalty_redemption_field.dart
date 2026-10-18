import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/numerals.dart';
import '../../../../core/presentation/latin_digits_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/button_spinner.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/loyalty_program.dart';
import '../state/loyalty_providers.dart';

/// `loyalty-redemption-field` on `BOOKING_Summary` (Figma v2):
///
/// * **Default** — the redeemable points (16 bold) + "يعادل ⟨value⟩" (12,
///   secondary) with a 35px "استبدال" pill;
/// * **opened** — the same header, a hairline, the points ⇄ discount fields
///   (each converts to the other with the backend rate) and a small primary
///   "تطبيق".
///
/// Everything is read from `GET /guest/hotels/{hotel}/loyalty`. When the
/// program is off (launch) or the guest has nothing redeemable, the field
/// shows its disabled state. The chosen points are only *applied* here; they
/// are redeemed against the reservation once it is created, and the server
/// decides the final discount.
class LoyaltyRedemptionField extends ConsumerStatefulWidget {
  const LoyaltyRedemptionField({
    super.key,
    required this.hotelId,
    required this.stayTotal,
    this.currency,
  });

  final String hotelId;

  /// Currency of [stayTotal] (the discount is in the same currency).
  final String? currency;

  /// The stay total the discount is capped at (as the backend caps it).
  final num stayTotal;

  @override
  ConsumerState<LoyaltyRedemptionField> createState() =>
      _LoyaltyRedemptionFieldState();
}

class _LoyaltyRedemptionFieldState
    extends ConsumerState<LoyaltyRedemptionField> {
  bool _open = false;
  final TextEditingController _points = TextEditingController();
  final TextEditingController _discount = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _points.dispose();
    _discount.dispose();
    super.dispose();
  }

  static String _fmt(num v) =>
      v == v.truncate() ? v.toInt().toString() : v.toStringAsFixed(2);

  void _onPoints(LoyaltyProgram program, String raw) {
    final int points = int.tryParse(raw) ?? 0;
    _discount.text = points <= 0
        ? ''
        : _fmt(program.discountFor(points, stayTotal: widget.stayTotal));
    setState(() => _error = null);
  }

  void _onDiscount(LoyaltyProgram program, String raw) {
    final num discount = num.tryParse(raw) ?? 0;
    final int points = program.pointsFor(discount);
    _points.text = points <= 0 ? '' : '$points';
    setState(() => _error = null);
  }

  void _apply(LoyaltyProgram program) {
    final AppLocalizations l10n = context.l10n;
    final int points = int.tryParse(_points.text) ?? 0;
    if (points < 1 || points > program.redeemablePoints) {
      setState(() => _error = l10n.bookingLoyaltyMaxHint(context.localDigits('${program.redeemablePoints}')));
      return;
    }
    ref.read(bookingRedeemPointsProvider.notifier).apply(widget.hotelId, points);
    setState(() {
      _open = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<LoyaltyProgram> async =
        ref.watch(loyaltyProgramProvider(widget.hotelId));
    // A failed / pending read never blocks the booking — the field simply
    // isn't offered until the program is known.
    final LoyaltyProgram? program = async.value;
    if (program == null) return const SizedBox.shrink();

    final AppLocalizations l10n = context.l10n;
    final int applied =
        ref.watch(bookingRedeemPointsProvider)[widget.hotelId] ?? 0;

    if (!program.canRedeem) {
      return _Card(
        child: _Header(
          title: program.enabled
              ? l10n.bookingLoyaltyNoPoints
              : l10n.bookingLoyaltyDisabled,
          trailing: _Pill(label: l10n.bookingLoyaltyRedeem, onTap: null),
          muted: true,
        ),
      );
    }

    final int shownPoints = applied > 0 ? applied : program.redeemablePoints;
    final Widget header = _Header(
      title: l10n.loyaltyPointsValue(shownPoints),
      worth: program.discountFor(shownPoints, stayTotal: widget.stayTotal),
      currency: widget.currency,
      subtitle: applied > 0 ? l10n.bookingLoyaltyAppliedNote : null,
      trailing: _open
          ? null
          : applied > 0
              ? _Pill(
                  label: l10n.bookingLoyaltyRemove,
                  onTap: () => ref
                      .read(bookingRedeemPointsProvider.notifier)
                      .clear(widget.hotelId),
                )
              : _Pill(
                  label: l10n.bookingLoyaltyRedeem,
                  onTap: () => setState(() => _open = true),
                ),
    );

    if (!_open) return _Card(child: header);

    final ThemeData theme = Theme.of(context);
    final AppColorTokens c = context.colors;
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          header,
          const SizedBox(height: 24),
          Divider(height: 0.5, thickness: 0.5, color: c.borderDefault),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: _NumberField(
                  key: const ValueKey('loyaltyPointsField'),
                  label: l10n.bookingLoyaltyPointsField,
                  hint: l10n.bookingLoyaltyPointsHint,
                  controller: _points,
                  decimal: false,
                  onChanged: (String v) => _onPoints(program, v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Icon(AppIcons.arrowSwap, size: 24, color: c.textPrimary),
              ),
              Expanded(
                child: _NumberField(
                  key: const ValueKey('loyaltyDiscountField'),
                  label: l10n.bookingLoyaltyDiscountField,
                  hint: l10n.bookingLoyaltyDiscountField,
                  controller: _discount,
                  decimal: true,
                  onChanged: (String v) => _onDiscount(program, v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _error ?? l10n.bookingLoyaltyMaxHint(context.localDigits('${program.redeemablePoints}')),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: _error != null ? c.errorFg : c.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            key: const ValueKey('loyaltyApplyButton'),
            label: l10n.bookingLoyaltyApply,
            size: AppButtonSize.small,
            onPressed: () => _apply(program),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) =>
      AppCard(padding: padding, shadow: false, child: child);
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    this.worth,
    this.subtitle,
    this.trailing,
    this.muted = false,
    this.currency,
  });

  final String title;
  final num? worth;
  final String? subtitle;
  final Widget? trailing;
  final bool muted;
  final String? currency;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorTokens c = context.colors;
    final TextStyle? sub = theme.textTheme.bodySmall?.copyWith(
      fontSize: 12,
      height: 15 / 12,
      color: c.textSecondary,
    );
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: muted ? 14 : 16,
                  height: 20 / 16,
                  fontWeight: muted ? FontWeight.w500 : FontWeight.w700,
                  color: muted ? c.textSecondary : c.textPrimary,
                ),
              ),
              if (worth != null) ...<Widget>[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('${context.l10n.bookingLoyaltyWorth} ', style: sub),
                    MoneyText(worth!, currency: currency, style: sub, color: c.textSecondary),
                  ],
                ),
              ],
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(subtitle!, style: sub),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// The 35px "استبدال" pill — `#fffdfb` fill, 0.5 `#cec8bc` stroke, bold 14.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    final bool enabled = onTap != null;
    return Material(
      color: enabled ? c.bgSurface : c.bgDisabled,
      shape: StadiumBorder(side: BorderSide(color: c.borderStrong, width: 0.5)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  height: 18 / 14,
                  fontWeight: FontWeight.w700,
                  color: enabled ? c.textLabel : c.textDisabled,
                ),
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.decimal,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool decimal;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontSize: 13,
            height: 16 / 13,
            fontWeight: FontWeight.w500,
            color: context.colors.textLabel,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: <TextInputFormatter>[
            const LatinDigitsFormatter(),
            FilteringTextInputFormatter.allow(
              decimal ? RegExp(r'^\d*\.?\d{0,2}') : RegExp(r'\d*'),
            ),
          ],
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
