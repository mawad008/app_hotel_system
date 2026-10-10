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
import '../../domain/entities/loyalty_account.dart';
import '../../domain/entities/loyalty_operations.dart';
import '../../domain/entities/loyalty_transaction.dart';
import '../state/loyalty_providers.dart';
import '../widgets/loyalty_balance_card.dart';
import '../widgets/loyalty_transaction_tile.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/pull_to_refresh.dart';

/// `14 · Entry, loyalty & completion` — the guest's loyalty screen for a
/// reservation: balance, contextual earn / redeem, and the points history.
///
/// The backend stays authoritative for eligibility, the balance and the ledger.
/// The app never computes a new balance — after an earn it re-reads the account
/// and transactions. No tiers, no rewards catalogue, no conversion rate (none
/// exist in the MVP).
class LoyaltyPage extends ConsumerWidget {
  const LoyaltyPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<LoyaltyContext> ctxAsync = ref.watch(
      loyaltyContextProvider(reservationId),
    );
    final AsyncValue<LoyaltyAccount> accountAsync = ref.watch(
      loyaltyAccountProvider(reservationId),
    );
    final AsyncValue<List<LoyaltyTransaction>> txAsync = ref.watch(
      loyaltyTransactionsProvider(reservationId),
    );

    return Scaffold(
      appBar: HotelAppBar(title: l10n.loyaltyTitle),
      body: SafeArea(
        child: PullToRefresh(
          onRefresh: () => refreshAll(<Future<Object?>>[
            ref.refresh(loyaltyContextProvider(reservationId).future),
            ref.refresh(loyaltyAccountProvider(reservationId).future),
            ref.refresh(loyaltyTransactionsProvider(reservationId).future),
          ]),
          child: _merge(
            ctxAsync,
            accountAsync,
            loading: () =>
                Center(child: LoadingView(label: l10n.stateLoadingTitle)),
            error: (Object e) => MessageView(
              icon: AppIcons.loyalty,
              title: l10n.loyaltyUnavailableTitle,
              message: ErrorMapper.toFailure(e).localizedMessage(l10n),
              actionLabel: l10n.actionRetry,
              onAction: () {
                ref.invalidate(loyaltyContextProvider(reservationId));
                ref.invalidate(loyaltyAccountProvider(reservationId));
                ref.invalidate(loyaltyTransactionsProvider(reservationId));
              },
            ),
            data: (LoyaltyContext ctx, LoyaltyAccount account) => _Body(
              reservationId: reservationId,
              context: ctx,
              account: account,
              transactions: txAsync,
            ),
          ),
        ),
      ),
    );
  }

  static Widget _merge(
    AsyncValue<LoyaltyContext> a,
    AsyncValue<LoyaltyAccount> b, {
    required Widget Function() loading,
    required Widget Function(Object) error,
    required Widget Function(LoyaltyContext, LoyaltyAccount) data,
  }) {
    // A failed refresh keeps the last good data on screen.
    if (a.hasValue && b.hasValue) return data(a.requireValue, b.requireValue);
    if (a.hasError) return error(a.error!);
    if (b.hasError) return error(b.error!);
    return loading();
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.reservationId,
    required this.context,
    required this.account,
    required this.transactions,
  });

  final String reservationId;
  final LoyaltyContext context;
  final LoyaltyAccount account;
  final AsyncValue<List<LoyaltyTransaction>> transactions;

  @override
  Widget build(BuildContext buildContext, WidgetRef ref) {
    final AppLocalizations l10n = buildContext.l10n;
    // Points accrue automatically when the stay completes (backend lifecycle
    // listener) — the ledger shows whether this stay has been credited.
    final bool alreadyEarned = transactions.maybeWhen(
      data: (List<LoyaltyTransaction> txs) => txs.any(
        (LoyaltyTransaction t) =>
            t.type.isCredit && t.isForReservation(reservationId),
      ),
      orElse: () => false,
    );

    final bool canRedeem =
        account.isActive && account.hasPoints && context.isRedeemableBooking;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageGutter),
      children: <Widget>[
        if (!account.isActive) ...<Widget>[
          InfoBanner(
            tone: InfoBannerTone.warning,
            title: l10n.loyaltyProgramOffTitle,
            message: l10n.loyaltyProgramOffBody,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        LoyaltyBalanceCard(account: account),
        const SizedBox(height: AppSpacing.md),

        // ── Earn ──
        if (account.isActive && context.isCompletedStay) ...<Widget>[
          if (alreadyEarned)
            InfoBanner(
              tone: InfoBannerTone.success,
              title: l10n.loyaltyAlreadyEarnedTitle,
              message: l10n.loyaltyAlreadyEarnedBody,
            )
          else
            InfoBanner(
              tone: InfoBannerTone.info,
              title: l10n.loyaltyAutoEarnTitle,
              message: l10n.loyaltyAutoEarnBody,
            ),
          const SizedBox(height: AppSpacing.xs),
        ],

        // ── Redeem ──
        if (canRedeem) ...<Widget>[
          SecondaryButton(
            label: l10n.loyaltyRedeemCta,
            icon: AppIcons.loyalty,
            onPressed: () => buildContext.pushNamed(
              AppRoutes.loyaltyRedeemName,
              pathParameters: <String, String>{'reservationId': reservationId},
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],

        const SizedBox(height: AppSpacing.md),

        // ── History ──
        Text(
          l10n.loyaltyHistoryTitle,
          style: Theme.of(buildContext).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        InfoBanner(tone: InfoBannerTone.info, title: l10n.loyaltyHistoryNote),
        const SizedBox(height: AppSpacing.md),
        transactions.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (Object e, StackTrace _) => InfoBanner(
            tone: InfoBannerTone.error,
            title: l10n.loyaltyUnavailableTitle,
            message: ErrorMapper.toFailure(e).localizedMessage(l10n),
          ),
          data: (List<LoyaltyTransaction> txs) {
            if (txs.isEmpty) {
              return _HistoryEmpty();
            }
            return AppCard(
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < txs.length; i++) ...<Widget>[
                    if (i > 0) const Divider(height: 1),
                    LoyaltyTransactionTile(
                      transaction: txs[i],
                      highlightReservationId: reservationId,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    return AppCard(
      child: Column(
        children: <Widget>[
          Icon(AppIcons.time, size: 32, color: theme.colorScheme.outline),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.loyaltyHistoryEmptyTitle,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.loyaltyHistoryEmptyBody,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
