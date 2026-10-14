import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/state/reservation_detail_provider.dart';
import '../../domain/entities/hotel_service.dart';
import '../state/stay_services_providers.dart';
import '../widgets/service_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/pull_to_refresh.dart';

/// `11 · Services & requests` — the hotel service catalogue, grouped by
/// category. Read-only: ordering happens on the service detail screen.
class StayServicesPage extends ConsumerWidget {
  const StayServicesPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<Reservation> reservationAsync = ref.watch(
      reservationDetailProvider(reservationId),
    );

    return Scaffold(
      appBar: HotelAppBar(title: l10n.servicesTitle),
      body: SafeArea(
        child: PullToRefresh(
          onRefresh: () {
            ref.invalidate(serviceCatalogueProvider);
            return ref.refresh(reservationDetailProvider(reservationId).future);
          },
          child: reservationAsync.when(
            // A failed refresh keeps the last good data on screen.
            skipError: true,
            loading: () =>
                Center(child: LoadingView(label: l10n.stateLoadingTitle)),
            error: (Object e, StackTrace _) => _error(context, ref, e),
            data: (Reservation reservation) {
              final AsyncValue<ServiceCatalogue> cat = ref.watch(
                serviceCatalogueProvider(reservation.hotelId),
              );
              return cat.when(
                skipError: true,
                loading: () =>
                    Center(child: LoadingView(label: l10n.stateLoadingTitle)),
                error: (Object e, StackTrace _) => _error(context, ref, e),
                data: (ServiceCatalogue catalogue) =>
                    _Body(reservationId: reservationId, catalogue: catalogue),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _error(BuildContext context, WidgetRef ref, Object error) {
    final AppLocalizations l10n = context.l10n;
    return MessageView(
      icon: AppIcons.roomService,
      title: l10n.servicesUnavailableTitle,
      message: ErrorMapper.toFailure(error).localizedMessage(l10n),
      actionLabel: l10n.actionRetry,
      onAction: () {
        ref.invalidate(reservationDetailProvider(reservationId));
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.reservationId, required this.catalogue});

  final String reservationId;
  final ServiceCatalogue catalogue;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final Locale locale = Localizations.localeOf(context);
    final List<(ServiceCategory?, List<HotelService>)> groups = catalogue
        .grouped();

    if (groups.isEmpty) {
      return Column(
        children: <Widget>[
          Expanded(
            child: EmptyView(
              title: l10n.servicesEmptyTitle,
              message: l10n.servicesEmptyBody,
            ),
          ),
          _MyRequestsButton(reservationId: reservationId),
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
                title: l10n.servicesIntroBanner,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final (ServiceCategory?, List<HotelService>) group
                  in groups) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.xs,
                    top: AppSpacing.xs,
                  ),
                  child: Text(
                    group.$1?.name.resolve(locale) ?? l10n.serviceUncategorised,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                AppCard(
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < group.$2.length; i++) ...<Widget>[
                        if (i > 0) const Divider(height: 1),
                        ServiceCard(
                          service: group.$2[i],
                          onTap: () => context.pushNamed(
                            AppRoutes.serviceDetailName,
                            pathParameters: <String, String>{
                              'reservationId': reservationId,
                              'serviceId': group.$2[i].id,
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
        _MyRequestsButton(reservationId: reservationId),
      ],
    );
  }
}

class _MyRequestsButton extends StatelessWidget {
  const _MyRequestsButton({required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.xs,
        AppSpacing.pageGutter,
        AppSpacing.md,
      ),
      child: SecondaryButton(
        label: context.l10n.myRequestsTitle,
        icon: AppIcons.invoice,
        onPressed: () => context.pushNamed(
          AppRoutes.serviceOrdersName,
          pathParameters: <String, String>{'reservationId': reservationId},
        ),
      ),
    );
  }
}
