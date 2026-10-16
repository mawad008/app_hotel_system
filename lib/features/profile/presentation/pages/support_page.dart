import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../app_content/domain/entities/app_content.dart';
import '../../../app_content/presentation/state/app_content_providers.dart';
import '../../../app_content/presentation/widgets/brand_link_actions.dart';
import '../../../bookings/presentation/state/bookings_providers.dart';
import '../state/account_providers.dart';
import '../state/account_summary.dart';
import '../widgets/profile_subpage.dart';

/// `PROFILE_Support` ("المساعدة"): FAQ (dashboard-managed), the cancellation
/// policy, report-a-problem, the hotel's support contacts (dashboard-managed:
/// call / WhatsApp / email / website — each hidden until set) and "تواصل مع
/// الاستقبال". Report-a-problem and reception need a stay — without one they
/// are shown disabled with the reason, never dead.
class SupportPage extends ConsumerWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AccountSummary? summary = ref
        .watch(accountSummaryProvider)
        .valueOrNull;
    final String? activeStay = summary?.activeStayReservationId;
    final String? contactStay = summary?.contactReservationId;
    final SupportContacts contacts = ref.watch(brandingProvider).support;

    return ProfileSubpage(
      onRefresh: () {
        // Derived from the bookings list: refetch that, not just the summary.
        ref.invalidate(bookingsListProvider);
        return ref.refresh(accountSummaryProvider.future);
      },
      title: l10n.profileSupportTitle,
      bannerTitle: l10n.profileSupportBannerTitle,
      bannerMessage: l10n.profileSupportBannerBody,
      cards: <Widget>[
        SettingsCard(
          borderWidth: 1,
          children: <Widget>[
            SettingsRow(
              icon: AppIcons.faq,
              label: l10n.profileFaq,
              onTap: () => context.pushNamed(AppRoutes.faqName),
            ),
            SettingsRow(
              icon: AppIcons.cancelPolicy,
              label: l10n.bookingCancellationPolicyHeading,
              onTap: () => context.pushNamed(AppRoutes.cancellationPolicyName),
            ),
            SettingsRow(
              icon: AppIcons.problem,
              label: l10n.stayHomeReportProblem,
              value: activeStay == null ? l10n.profileDuringStayOnly : null,
              onTap: activeStay == null
                  ? null
                  : () => context.pushNamed(
                      AppRoutes.reportProblemName,
                      pathParameters: <String, String>{
                        'reservationId': activeStay,
                      },
                    ),
            ),
          ],
        ),
        if (!contacts.isEmpty) SupportContactsCard(contacts: contacts),
      ],
      footer: PrimaryButton(
        label: contactStay == null
            ? l10n.profileContactReceptionNoStay
            : l10n.identityContactReceptionCta,
        onPressed: contactStay == null
            ? null
            : () => context.pushNamed(
                AppRoutes.contactReceptionName,
                pathParameters: <String, String>{'reservationId': contactStay},
              ),
      ),
    );
  }
}
