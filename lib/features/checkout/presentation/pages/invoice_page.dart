import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/state/reservation_detail_provider.dart';
import '../../domain/entities/invoice.dart';
import '../state/checkout_providers.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/pull_to_refresh.dart';

/// `05 · Depart & Invoice` screen 2 — the issued e-invoice with full line
/// items. Every figure is backend-supplied; the app renders it and never
/// recomputes a subtotal or an outstanding amount.
class InvoicePage extends ConsumerWidget {
  const InvoicePage({super.key, required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<Invoice> invoiceAsync = ref.watch(
      invoiceProvider(reservationId),
    );

    return Scaffold(
      appBar: HotelAppBar(title: l10n.invoiceTitle),
      body: SafeArea(
        child: PullToRefresh(
          onRefresh: () => ref.refresh(invoiceProvider(reservationId).future),
          child: invoiceAsync.when(
            // A failed refresh keeps the last invoice on screen.
            skipError: true,
            loading: () =>
                Center(child: LoadingView(label: l10n.stateLoadingTitle)),
            error: (Object e, StackTrace _) {
              final Failure failure = ErrorMapper.toFailure(e);
              if (failure.kind == FailureKind.notFound) {
                return MessageView(
                  icon: AppIcons.invoice,
                  title: l10n.invoiceNotReadyTitle,
                  message: l10n.invoiceNotReadyBody,
                  actionLabel: l10n.commonBack,
                  onAction: () => context.pop(),
                );
              }
              return MessageView(
                icon: AppIcons.invoice,
                title: l10n.invoiceUnavailableTitle,
                message: failure.localizedMessage(l10n),
                actionLabel: l10n.actionRetry,
                onAction: () => ref.invalidate(invoiceProvider(reservationId)),
              );
            },
            data: (Invoice invoice) =>
                _Body(reservationId: reservationId, invoice: invoice),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.reservationId, required this.invoice});

  final String reservationId;
  final Invoice invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final MaterialLocalizations ml = MaterialLocalizations.of(context);
    final Locale locale = Localizations.localeOf(context);
    final AppSemanticColors semantic =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final AsyncValue<Reservation> reservationAsync = ref.watch(
      reservationDetailProvider(reservationId),
    );

    String money(num amount) =>
        l10n.moneyAmount(invoice.currency, MoneyText.digits(context, amount));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageGutter),
      children: <Widget>[
        InfoBanner(
          tone: InfoBannerTone.info,
          title: l10n.invoiceIssuedBannerTitle,
          message: l10n.invoiceIssuedBannerBody,
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
                      l10n.invoiceNumberLabel,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    invoice.invoiceNumber,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
              if (invoice.issuedAt != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.invoiceIssuedLabel,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      ml.formatMediumDate(invoice.issuedAt!),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
              reservationAsync.maybeWhen(
                data: (Reservation r) => Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          l10n.reviewHotelLabel,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          r.hotelName.resolve(locale),
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l10n.invoiceItemsTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (final InvoiceItem item in invoice.items) ...<Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.quantity > 1
                            ? '${_itemLabel(l10n, item)} ×${item.quantity}'
                            : _itemLabel(l10n, item),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      money(item.totalAmount.amount),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              const Divider(height: AppSpacing.lg),
              _totalRow(
                theme,
                l10n.invoiceSubtotalLabel,
                money(invoice.subtotal.amount),
              ),
              if (invoice.paymentsTotal.amount > 0) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                _totalRow(
                  theme,
                  l10n.invoicePaymentsLabel,
                  '−${money(invoice.paymentsTotal.amount)}',
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n.invoiceOutstandingLabel,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    money(invoice.outstandingTotal.amount),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: invoice.isSettled
                          ? semantic.success
                          : semantic.accent,
                    ),
                  ),
                ],
              ),
              if (invoice.isSettled) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.invoiceSettledTag,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: semantic.success,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  String _itemLabel(AppLocalizations l10n, InvoiceItem item) {
    if (item.sourceType == 'accommodation') return l10n.folioAccommodationLine;
    return item.description.isEmpty ? l10n.folioServiceLine : item.description;
  }

  Widget _totalRow(ThemeData theme, String label, String value) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.ink900),
        ),
      ],
    );
  }
}
