import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../discovery/presentation/widgets/guest_stepper.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/state/reservation_detail_provider.dart';
import '../../domain/entities/hotel_service.dart';
import '../../domain/entities/service_order.dart';
import '../state/service_request_controller.dart';
import '../state/stay_services_providers.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/pull_to_refresh.dart';

/// `11 · Services & requests` — one service, with quantity + notes and the
/// "request" action. The estimated total shown here is a client-side
/// **estimate** for the guest's benefit; the backend records the authoritative
/// `total_amount` and the folio.
class ServiceDetailPage extends ConsumerStatefulWidget {
  const ServiceDetailPage({
    super.key,
    required this.reservationId,
    required this.serviceId,
  });

  final String reservationId;
  final String serviceId;

  @override
  ConsumerState<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends ConsumerState<ServiceDetailPage> {
  final TextEditingController _notes = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Locale locale = Localizations.localeOf(context);
    final AsyncValue<Reservation> reservationAsync = ref.watch(
      reservationDetailProvider(widget.reservationId),
    );

    return Scaffold(
      appBar: HotelAppBar(title: l10n.serviceDetailTitle),
      body: SafeArea(
        child: PullToRefresh(
          onRefresh: () {
            ref.invalidate(serviceCatalogueProvider);
            return ref.refresh(
              reservationDetailProvider(widget.reservationId).future,
            );
          },
          child: reservationAsync.when(
            // A failed refresh keeps the last good data on screen.
            skipError: true,
            loading: () =>
                Center(child: LoadingView(label: l10n.stateLoadingTitle)),
            error: (_, _) => _missing(context),
            data: (Reservation reservation) {
              final AsyncValue<ServiceCatalogue> cat = ref.watch(
                serviceCatalogueProvider(reservation.hotelId),
              );
              return cat.when(
                skipError: true,
                loading: () =>
                    Center(child: LoadingView(label: l10n.stateLoadingTitle)),
                error: (_, _) => _missing(context),
                data: (ServiceCatalogue catalogue) {
                  final HotelService? service = catalogue.serviceById(
                    widget.serviceId,
                  );
                  if (service == null || !service.isOrderable) {
                    return _missing(context);
                  }
                  return _content(context, reservation, service, locale);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _missing(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return MessageView(
      icon: AppIcons.help,
      title: l10n.servicesEmptyTitle,
      message: l10n.servicesEmptyBody,
      actionLabel: l10n.commonBack,
      onAction: () => context.pop(),
    );
  }

  Widget _content(
    BuildContext context,
    Reservation reservation,
    HotelService service,
    Locale locale,
  ) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final CreateServiceRequest request = CreateServiceRequest.forReservation(
      reservation,
      serviceId: service.id,
      serviceName: service.name,
      quantity: _quantity,
      notes: _notes.text,
    );
    final ServiceRequestState action = ref.watch(
      serviceRequestControllerProvider,
    );
    final bool submitting =
        action is ServiceRequestSubmitting && action.request == request;
    final bool paid = service.price.amount > 0;
    final num estimate = service.price.amount * _quantity;

    ref.listen<ServiceRequestState>(serviceRequestControllerProvider, (
      _,
      next,
    ) {
      if (next is ServiceRequestDone &&
          next.request.reservationId == reservation.id &&
          next.request.serviceId == service.id) {
        context.pushReplacementNamed(
          AppRoutes.serviceOrderDetailName,
          pathParameters: <String, String>{
            'reservationId': reservation.id,
            'orderId': next.order.id,
          },
        );
      }
    });

    final Failure? failure =
        action is ServiceRequestFailed &&
            action.request.reservationId == reservation.id &&
            action.request.serviceId == service.id
        ? action.failure
        : null;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            children: <Widget>[
              Text(
                service.name.resolve(locale),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                service.description.resolve(locale),
                style: theme.textTheme.bodyMedium,
              ),
              if (service.estimatedMinutes != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.serviceEstimatedMinutes(service.estimatedMinutes!),
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: GuestStepper(
                  label: l10n.serviceQuantityLabel,
                  value: _quantity,
                  min: 1,
                  max: 10,
                  onChanged: submitting
                      ? (_) {}
                      : (int v) => setState(() => _quantity = v),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.serviceNotesLabel,
                hintText: l10n.serviceNotesHint,
                controller: _notes,
                enabled: !submitting,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.md),
              if (paid)
                AppCard(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          l10n.serviceEstimatedTotalLabel,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Text(
                        l10n.moneyAmount(
                          service.price.currency,
                          MoneyText.digits(context, estimate),
                        ),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color:
                              theme.extension<AppSemanticColors>()?.accent ??
                              AppColors.bronze500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.serviceChargeNote, style: theme.textTheme.bodySmall),
              if (failure != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                InfoBanner(
                  tone: InfoBannerTone.error,
                  title: l10n.serviceRequestFailedTitle,
                  message: failure.localizedMessage(l10n),
                ),
              ],
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
          child: PrimaryButton(
            label: submitting
                ? l10n.serviceRequestingCta
                : l10n.serviceRequestCta,
            isLoading: submitting,
            onPressed: submitting
                ? null
                : () => ref
                      .read(serviceRequestControllerProvider.notifier)
                      .submit(request),
          ),
        ),
      ],
    );
  }
}
