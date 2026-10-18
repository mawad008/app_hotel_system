import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../../core/widgets/bottom_action_bar.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/state/reservation_detail_provider.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_request.dart';
import '../state/payment_controller.dart';

/// `03 · Pay & Verify` — choose how to pay the deposit hold
/// (`PAYMENT_Method`).
///
/// Purely a device-local choice ([PaymentMethodChoice]) that decides whether
/// the guest is sent straight to confirming the hold or through the
/// card-details step first — no card data is ever collected here for a saved
/// method, and "add a new card" collects display-only fields that are never
/// sent to the backend (mobile/docs/architecture.md §8). Choosing Apple Pay
/// or the saved card requests the same [PaymentHoldRequest] the review screen
/// always used; nothing about the hold contract changes.
class PaymentMethodPage extends ConsumerStatefulWidget {
  const PaymentMethodPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  ConsumerState<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends ConsumerState<PaymentMethodPage> {
  /// A deterministic placeholder "saved card" — no real card vault exists yet
  /// (mirrors the dummy-first pattern used across the app).
  static const String _savedCardLast4 = '4242';

  PaymentMethodChoice _selected = PaymentMethodChoice.applePay;

  void _continue(Reservation reservation) {
    if (_selected.needsCardDetails) {
      context.pushNamed(
        AppRoutes.paymentCardDetailsName,
        pathParameters: <String, String>{'reservationId': widget.reservationId},
      );
      return;
    }
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
    final AsyncValue<Reservation> reservationAsync = ref.watch(
      reservationDetailProvider(widget.reservationId),
    );

    return Scaffold(
      appBar: HotelAppBar(title: l10n.paymentMethodTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pageGutter),
          children: <Widget>[
            InfoBanner(
              tone: InfoBannerTone.info,
              title: l10n.paymentMethodBannerTitle,
              message: l10n.paymentMethodBannerBody,
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsCard(
              borderWidth: 1,
              children: <Widget>[
                _MethodRow(
                  icon: AppIcons.wallet,
                  label: l10n.paymentMethodApplePay,
                  selected: _selected.kind == PaymentMethodKind.applePay,
                  onTap: () => setState(
                    () => _selected = PaymentMethodChoice.applePay,
                  ),
                ),
                _MethodRow(
                  icon: AppIcons.payment,
                  label: l10n.paymentMethodSavedCard,
                  value: '$_savedCardLast4 ••••',
                  selected: _selected.kind == PaymentMethodKind.savedCard,
                  onTap: () => setState(
                    () => _selected =
                        PaymentMethodChoice.savedCard(_savedCardLast4),
                  ),
                ),
                _MethodRow(
                  icon: AppIcons.add,
                  label: l10n.paymentMethodAddNewCard,
                  selected: _selected.kind == PaymentMethodKind.newCard,
                  onTap: () => setState(
                    () => _selected = PaymentMethodChoice.newCard,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar.actions(
        primary: PrimaryButton(
          label: l10n.commonContinue,
          onPressed: reservationAsync.value == null
              ? null
              : () => _continue(reservationAsync.value!),
        ),
      ),
    );
  }
}

/// A v2 list-card row (icon tile · label · value) plus the selection mark
/// the payment choice needs.
class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: SettingsRow(
        icon: icon,
        label: label,
        value: value,
        onTap: onTap,
        trailing: Icon(
          selected ? AppIcons.success : AppIcons.radioOff,
          size: 20,
          color: selected ? c.textPrimary : c.borderStrong,
        ),
      ),
    );
  }
}
