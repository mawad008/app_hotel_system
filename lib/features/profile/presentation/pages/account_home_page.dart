import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/bottom_nav_navigation.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/numerals.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../bookings/domain/bookings_filter.dart';
import '../../../bookings/presentation/state/bookings_providers.dart';
import '../../../discovery/presentation/state/favorite_hotels_controller.dart';
import '../state/account_providers.dart';
import '../state/account_summary.dart';

/// `PROFILE_Home.png` — the "حسابي" bottom-nav root: the loyalty card,
/// trusted-guest status, and quick links, ending with sign-out (moved here
/// from `DiscoverPage`'s app bar per `docs/design-system.md`).
class AccountHomePage extends ConsumerWidget {
  const AccountHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<AccountSummary> async = ref.watch(accountSummaryProvider);

    return Scaffold(
      appBar: HotelAppBar(title: l10n.accountTitle, automaticallyImplyLeading: false),
      body: SafeArea(
        child: async.when(
          loading: () => Center(child: LoadingView(label: l10n.stateLoadingTitle)),
          error: (Object error, StackTrace _) {
            final failure = ErrorMapper.toFailure(error);
            return MessageView(
              icon: AppIcons.warning,
              title: l10n.stateErrorTitle,
              message: failure.localizedMessage(l10n),
              actionLabel: l10n.actionRetry,
              onAction: () {
                ref.invalidate(accountSummaryProvider);
                ref.invalidate(bookingsListProvider);
              },
            );
          },
          data: (AccountSummary summary) => _Body(summary: summary),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        current: AppNavTab.account,
        onSelected: (AppNavTab tab) => goToNavTab(context, tab),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.summary});

  final AccountSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final Locale locale = Localizations.localeOf(context);
    final AppColorTokens c = context.colors;
    final TextTheme text = Theme.of(context).textTheme;
    final String? loyaltyReservation = summary.loyaltyReservationId;
    final int favoriteCount = ref.watch(favoriteHotelsProvider).length;

    // `PROFILE_Home`: 24px page inset (12 top), sections 16px apart; every
    // row opens its own screen (Figma prototype routing map, "PROFILE").
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: <Widget>[
        InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          onTap: loyaltyReservation == null
              ? null
              : () => context.pushNamed(
                    AppRoutes.loyaltyName,
                    pathParameters: <String, String>{'reservationId': loyaltyReservation},
                  ),
          child: AppCard(
            style: AppCardStyle.inverse,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.accountLoyaltyProgramTitle,
                  style: text.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: c.textOnInverse.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.localDigits('${summary.loyalty.pointsBalance} ${l10n.accountLoyaltyPointsSuffix}'),
                  style: text.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.textOnInverse,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.accountLoyaltyDescription,
                  style: text.bodySmall?.copyWith(
                    fontSize: 13.5,
                    color: c.textOnInverse.withValues(alpha: 0.8),
                  ),
                ),
                if (summary.nightlyRate != null) ...<Widget>[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        l10n.accountLoyaltyPerNightLabel,
                        style: text.bodySmall?.copyWith(
                          fontSize: 12,
                          color: c.textOnInverse.withValues(alpha: 0.7),
                        ),
                      ),
                      MoneyText(summary.nightlyRate!.amount, currency: summary.nightlyRate!.currency, color: c.textOnInverse),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (summary.trustedGuest) ...<Widget>[
          const SizedBox(height: 16),
          _TrustedGuestCard(
            onTap: () => context.pushNamed(AppRoutes.profilePersonalInfoName),
          ),
        ],
        const SizedBox(height: 16),
        SettingsCard(
          children: <Widget>[
            if (!summary.trustedGuest)
              SettingsRow(
                icon: AppIcons.profileRow,
                label: l10n.profilePersonalInfoTitle,
                onTap: () => context.pushNamed(AppRoutes.profilePersonalInfoName),
              ),
            SettingsRow(
              icon: AppIcons.ticket,
              label: l10n.accountPreviousStaysLabel,
              value: context.localDigits('${summary.previousStaysCount}'),
              onTap: () {
                ref.read(bookingsFilterProvider.notifier).state = BookingsFilter.past;
                context.goNamed(AppRoutes.bookingsName);
              },
            ),
            SettingsRow(
              key: const ValueKey<String>('account-favorites'),
              icon: AppIcons.favorite,
              label: l10n.favoritesTitle,
              value: favoriteCount == 0 ? null : context.localDigits('$favoriteCount'),
              onTap: () => context.pushNamed(AppRoutes.favoriteHotelsName),
            ),
            SettingsRow(
              icon: AppIcons.settings,
              label: l10n.accountPreferencesLabel,
              value: summary.preferredRoomName?.resolve(locale),
              onTap: () => context.pushNamed(AppRoutes.profilePreferencesName),
            ),
            SettingsRow(
              icon: AppIcons.privacy,
              label: l10n.accountPrivacyLabel,
              onTap: () => context.pushNamed(AppRoutes.profilePrivacyName),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SettingsCard(
          children: <Widget>[
            SettingsRow(
              icon: AppIcons.help,
              label: l10n.accountHelpSupportLabel,
              onTap: () => context.pushNamed(AppRoutes.profileSupportName),
            ),
            SettingsRow(
              icon: AppIcons.logout,
              label: l10n.authSignOut,
              onTap: () => context.pushNamed(AppRoutes.logoutConfirmName),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InfoBanner(
          tone: InfoBannerTone.info,
          title: l10n.profilePrivacyBannerTitle,
          message: l10n.accountPrivacyNoteBody,
        ),
      ],
    );
  }
}

/// `PROFILE_Home` gold "نزيل موثوق" card (`#FAF7F0` fill, `#E2CB98` stroke,
/// radius 20, 16/18 padding) — opens "بياناتي".
class _TrustedGuestCard extends StatelessWidget {
  const _TrustedGuestCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppColorTokens c = context.colors;
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: c.accentWarmBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: c.accentWarmBorder),
      ),
      child: InkWell(
        customBorder: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: <Widget>[
              Icon(AppIcons.shieldTickOutline, size: 26, color: c.textPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.accountTrustedGuestTitle,
                      style: text.titleMedium?.copyWith(
                        fontSize: 18,
                        height: 28 / 18,
                        fontWeight: FontWeight.w700,
                        color: c.accentWarm,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.accountTrustedGuestBody,
                      style: text.bodySmall?.copyWith(
                        fontSize: 12,
                        height: 18 / 12,
                        color: c.accentWarm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
