import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/widgets/banner_screen.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../domain/entities/service_order.dart';
import '../../domain/entities/service_order_status.dart';
import '../state/service_request_controller.dart';
import '../state/service_review_providers.dart';
import '../state/stay_services_providers.dart';
import '../stay_services_l10n.dart';
import '../widgets/service_order_status_pill.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/pull_to_refresh.dart';

/// `11 · Services & requests` screens 2 & 4 — one service request: its status,
/// details, and (while still `requested`) the cancel action. Doubles as the
/// "request sent" confirmation right after ordering.
class ServiceOrderDetailPage extends ConsumerWidget {
  const ServiceOrderDetailPage({
    super.key,
    required this.reservationId,
    required this.orderId,
  });

  final String reservationId;
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ServiceOrderKey key = (
      reservationId: reservationId,
      orderId: orderId,
    );
    final AsyncValue<ServiceOrder> orderAsync = ref.watch(
      serviceOrderProvider(key),
    );

    return Scaffold(
      appBar: HotelAppBar(title: l10n.serviceOrderDetailTitle),
      body: SafeArea(
        child: PullToRefresh(
          onRefresh: () {
            ref.invalidate(serviceOrderReviewProvider(key));
            return ref.refresh(serviceOrderProvider(key).future);
          },
          child: orderAsync.when(
            // A failed refresh keeps the last good data on screen.
            skipError: true,
            loading: () =>
                Center(child: LoadingView(label: l10n.stateLoadingTitle)),
            error: (Object e, StackTrace _) => MessageView(
              icon: AppIcons.invoice,
              title: l10n.servicesUnavailableTitle,
              message: ErrorMapper.toFailure(e).localizedMessage(l10n),
              actionLabel: l10n.actionRetry,
              onAction: () => ref.invalidate(serviceOrderProvider(key)),
            ),
            data: (ServiceOrder order) => _Body(orderKey: key, order: order),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.orderKey, required this.order});

  final ServiceOrderKey orderKey;
  final ServiceOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final MaterialLocalizations ml = MaterialLocalizations.of(context);
    final Locale locale = Localizations.localeOf(context);
    final CancelOrderState cancel = ref.watch(
      cancelOrderControllerProvider(orderKey),
    );

    ref.listen<CancelOrderState>(cancelOrderControllerProvider(orderKey), (
      _,
      next,
    ) {
      if (next is CancelOrderDone && context.canPop()) {
        context.pop();
      } else if (next is CancelOrderFailed) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                next.failure.kind == FailureKind.conflict
                    ? l10n.serviceCancelNotAllowed
                    : next.failure.localizedMessage(l10n),
              ),
            ),
          );
      }
    });

    final bool canCancel =
        order.isGuestCancellable && cancel is! CancelOrderSubmitting;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            children: <Widget>[
              InfoBanner(
                tone: order.status.isCancelled
                    ? InfoBannerTone.error
                    : InfoBannerTone.info,
                title: order.serviceName.resolve(locale),
                message: l10n.serviceOrderStatusLabel(order.status),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            order.reference,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        ServiceOrderStatusPill(status: order.status),
                      ],
                    ),
                    const Divider(height: AppSpacing.lg),
                    _row(theme, l10n.serviceQuantityLabel, '${order.quantity}'),
                    if (order.totalAmount.amount > 0) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      _row(
                        theme,
                        l10n.serviceEstimatedTotalLabel,
                        l10n.moneyAmount(
                          order.totalAmount.currency,
                          MoneyText.digits(context, order.totalAmount.amount),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    _row(
                      theme,
                      l10n.serviceOrderRequestedAtLabel,
                      ml.formatMediumDate(order.requestedAt),
                    ),
                    if (order.confirmedAt != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      _row(
                        theme,
                        l10n.serviceOrderConfirmedAtLabel,
                        ml.formatMediumDate(order.confirmedAt!),
                      ),
                    ],
                    if (order.notes != null &&
                        order.notes!.isNotEmpty) ...<Widget>[
                      const Divider(height: AppSpacing.lg),
                      Text(
                        l10n.serviceNotesLabel,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(order.notes!, style: theme.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.serviceChargeNote, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.xs,
            AppSpacing.pageGutter,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (order.status == ServiceOrderStatus.fulfilled) ...<Widget>[
                _RateServiceButton(orderKey: orderKey),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (order.isGuestCancellable)
                PrimaryButton(
                  label: l10n.serviceCancelCta,
                  isLoading: cancel is CancelOrderSubmitting,
                  onPressed: canCancel
                      ? () => _confirmCancel(context, ref)
                      : null,
                ),
              if (order.isGuestCancellable)
                const SizedBox(height: AppSpacing.xs),
              SecondaryButton(
                label: l10n.serviceContactReception,
                icon: AppIcons.support,
                onPressed: () => context.pushNamed(
                  AppRoutes.contactReceptionName,
                  pathParameters: <String, String>{
                    'reservationId': orderKey.reservationId,
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// `STAY_ServiceCancel_Confirm_Overlay` — a full-screen confirmation
  /// (title "إلغاء الطلب", warning banner, "تأكيد الإلغاء" / "رجوع"). An
  /// order the hotel already accepted gets the in-progress warning.
  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    final String service = order.serviceName.resolve(
      Localizations.localeOf(context),
    );
    final bool? confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (BuildContext ctx) => BannerScreen(
          title: l10n.serviceCancelCta,
          tone: InfoBannerTone.warning,
          bannerTitle: l10n.serviceCancelConfirmTitleFor(service),
          bannerMessage: order.status == ServiceOrderStatus.confirmed
              ? l10n.serviceCancelInProgressBody
              : l10n.serviceCancelConfirmBody,
          primaryLabel: l10n.serviceCancelConfirmCta,
          onPrimary: () => Navigator.of(ctx).pop(true),
          secondaryLabel: l10n.commonBack,
          onSecondary: () => Navigator.of(ctx).pop(false),
        ),
      ),
    );
    if (confirmed == true) {
      await ref.read(cancelOrderControllerProvider(orderKey).notifier).cancel();
    }
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

/// Only shown once the order is `fulfilled` — the state a service review may
/// be submitted for (see `ServiceReviewEligibility`). Reads whether a review
/// already exists so the label never claims "rate" for an order the guest
/// already rated.
class _RateServiceButton extends ConsumerWidget {
  const _RateServiceButton({required this.orderKey});

  final ServiceOrderKey orderKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<Object?> reviewAsync = ref.watch(
      serviceOrderReviewProvider(orderKey),
    );
    final bool alreadyReviewed = reviewAsync.valueOrNull != null;

    return SecondaryButton(
      label: alreadyReviewed
          ? l10n.reviewYourRatingLabel
          : l10n.serviceReviewFormTitle,
      icon: AppIcons.rating,
      onPressed: () => context.pushNamed(
        AppRoutes.serviceReviewFormName,
        pathParameters: <String, String>{
          'reservationId': orderKey.reservationId,
          'serviceOrderId': orderKey.orderId,
        },
      ),
    );
  }
}
