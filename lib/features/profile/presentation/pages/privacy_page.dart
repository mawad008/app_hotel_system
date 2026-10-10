import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/banner_screen.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../../core/widgets/pull_to_refresh.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../app_content/presentation/state/app_content_providers.dart';
import '../../../bookings/domain/bookings_filter.dart';
import '../../../bookings/presentation/state/bookings_providers.dart';
import '../../domain/entities/guest_preferences.dart';
import '../state/profile_providers.dart';
import '../widgets/profile_subpage.dart';

/// `PROFILE_Privacy` ("الخصوصية وبياناتي"): how the guest's data is handled,
/// a link to their stay history, and "طلب حذف بياناتي" — recorded on the
/// backend (`POST /guest/privacy/deletion-request`) for the hotel team, who
/// see it on the guest's dashboard profile.
class PrivacyPage extends ConsumerWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<GuestAccountSettings> settings = ref.watch(
      guestAccountSettingsProvider,
    );

    Future<void> refresh() {
      ref.invalidate(appContentProvider);
      return ref.refresh(guestAccountSettingsProvider.future);
    }

    return settings.when(
      // A failed refresh keeps the last good data on screen.
      skipError: true,
      loading: () => Scaffold(
        appBar: HotelAppBar(title: l10n.accountPrivacyLabel),
        body: Center(child: LoadingView(label: l10n.stateLoadingTitle)),
      ),
      error: (Object e, StackTrace _) => Scaffold(
        appBar: HotelAppBar(title: l10n.accountPrivacyLabel),
        body: PullToRefresh(
          onRefresh: refresh,
          child: MessageView(
            icon: AppIcons.privacy,
            title: l10n.stateErrorTitle,
            message: ErrorMapper.toFailure(e).localizedMessage(l10n),
            actionLabel: l10n.actionRetry,
            onAction: () => ref.invalidate(guestAccountSettingsProvider),
          ),
        ),
      ),
      data: (GuestAccountSettings s) {
        final DateTime? requestedAt = s.dataDeletionRequestedAt;
        return ProfileSubpage(
          onRefresh: refresh,
          title: l10n.accountPrivacyLabel,
          bannerTone: requestedAt == null
              ? InfoBannerTone.info
              : InfoBannerTone.success,
          bannerTitle: requestedAt == null
              ? l10n.profilePrivacyBannerTitle
              : l10n.profileDeletionRequestedTitle,
          bannerMessage: requestedAt == null
              ? l10n.profilePrivacyBannerBody
              : l10n.profileDeletionRequestedBody(
                  MaterialLocalizations.of(context)
                      .formatMediumDate(requestedAt),
                ),
          cards: <Widget>[
            SettingsCard(
              borderWidth: 1,
              children: <Widget>[
                SettingsRow(
                  label: l10n.profilePrivacyIdPhotos,
                  value: s.keepIdentityForFuture
                      ? l10n.profileIdentityKeptValue
                      : l10n.profilePrivacyIdPhotosValue,
                ),
                SettingsRow(
                  label: l10n.profilePrivacyPaymentData,
                  value: l10n.profilePrivacyPaymentDataValue,
                ),
                SettingsRow(
                  label: l10n.profilePrivacyStayHistory,
                  onTap: () {
                    ref.read(bookingsFilterProvider.notifier).state =
                        BookingsFilter.past;
                    context.goNamed(AppRoutes.bookingsName);
                  },
                ),
              ],
            ),
            // The guest's identity-image choice (stored on the backend).
            SettingsCard(
              borderWidth: 1,
              children: <Widget>[
                _RetentionOption(
                  label: l10n.profileIdentityDeleteAfterCheckout,
                  selected: !s.keepIdentityForFuture,
                  onTap: () => _setRetention(context, ref, keep: false),
                ),
                _RetentionOption(
                  label: l10n.profileIdentityKeepForFuture,
                  selected: s.keepIdentityForFuture,
                  onTap: () => _setRetention(context, ref, keep: true),
                ),
                if (ref
                        .watch(appContentProvider)
                        .valueOrNull
                        ?.identityRetentionDays
                    case final int days)
                  Text(
                    l10n.profileIdentityHotelCopyNote(days),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: context.colors.textSecondary),
                  ),
              ],
            ),
          ],
          footer: PrimaryButton(
            label: requestedAt == null
                ? l10n.profileRequestDeletion
                : l10n.profileDeletionRequestedCta,
            onPressed: requestedAt == null
                ? () => _confirm(context, ref)
                : null,
          ),
        );
      },
    );
  }

  Future<void> _setRetention(
    BuildContext context,
    WidgetRef ref, {
    required bool keep,
  }) async {
    final AppLocalizations l10n = context.l10n;
    try {
      await ref
          .read(guestAccountSettingsProvider.notifier)
          .setIdentityRetention(keepForFuture: keep);
    } on Failure catch (failure) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(failure.localizedMessage(l10n))),
          );
      }
    }
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = context.l10n;
    final bool? confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (BuildContext ctx) => BannerScreen(
          title: l10n.profileRequestDeletion,
          tone: InfoBannerTone.warning,
          bannerTitle: l10n.profileDeletionConfirmTitle,
          bannerMessage: l10n.profileDeletionConfirmBody,
          primaryLabel: l10n.profileDeletionConfirmCta,
          onPrimary: () => Navigator.of(ctx).pop(true),
          secondaryLabel: l10n.commonBack,
          onSecondary: () => Navigator.of(ctx).pop(false),
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(guestAccountSettingsProvider.notifier)
          .requestDataDeletion();
    } on Failure catch (failure) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(failure.localizedMessage(l10n))),
          );
      }
    }
  }
}

class _RetentionOption extends StatelessWidget {
  const _RetentionOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: <Widget>[
              Icon(
                selected ? AppIcons.success : AppIcons.radioOff,
                size: 20,
                color: selected ? c.textPrimary : c.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(fontSize: 15, height: 26 / 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
