import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/service_order.dart';
import '../state/stay_services_providers.dart';
import '../widgets/service_order_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/pull_to_refresh.dart';

/// `11 · Services & requests` screen 3 — the guest's service requests.
class MyServiceRequestsPage extends ConsumerWidget {
  const MyServiceRequestsPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<ServiceOrder>> ordersAsync = ref.watch(
      serviceOrdersProvider(reservationId),
    );

    return Scaffold(
      appBar: HotelAppBar(title: l10n.myRequestsTitle),
      body: SafeArea(
        child: PullToRefresh(
          onRefresh: () =>
              ref.refresh(serviceOrdersProvider(reservationId).future),
          child: ordersAsync.when(
            // A failed refresh keeps the last good data on screen.
            skipError: true,
            loading: () =>
                Center(child: LoadingView(label: l10n.stateLoadingTitle)),
            error: (Object e, StackTrace _) => MessageView(
              icon: AppIcons.invoice,
              title: l10n.servicesUnavailableTitle,
              message: ErrorMapper.toFailure(e).localizedMessage(l10n),
              actionLabel: l10n.actionRetry,
              onAction: () =>
                  ref.invalidate(serviceOrdersProvider(reservationId)),
            ),
            data: (List<ServiceOrder> orders) =>
                _Body(reservationId: reservationId, orders: orders),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.reservationId, required this.orders});

  final String reservationId;
  final List<ServiceOrder> orders;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    void newRequest() => context.pushReplacementNamed(
      AppRoutes.stayServicesName,
      pathParameters: <String, String>{'reservationId': reservationId},
    );

    if (orders.isEmpty) {
      return Column(
        children: <Widget>[
          Expanded(
            child: EmptyView(
              title: l10n.myRequestsEmptyTitle,
              message: l10n.myRequestsEmptyBody,
            ),
          ),
          _Bottom(label: l10n.newRequestCta, onPressed: newRequest),
        ],
      );
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            children: <Widget>[
              InfoBanner(
                tone: InfoBannerTone.info,
                title: l10n.myRequestsIntroBanner,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final ServiceOrder order in orders) ...<Widget>[
                ServiceOrderCard(
                  order: order,
                  onTap: () => context.pushNamed(
                    AppRoutes.serviceOrderDetailName,
                    pathParameters: <String, String>{
                      'reservationId': reservationId,
                      'orderId': order.id,
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
        _Bottom(label: l10n.newRequestCta, onPressed: newRequest),
      ],
    );
  }
}

class _Bottom extends StatelessWidget {
  const _Bottom({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.xs,
        AppSpacing.pageGutter,
        AppSpacing.md,
      ),
      child: PrimaryButton(label: label, onPressed: onPressed),
    );
  }
}
