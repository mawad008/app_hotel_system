import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/pull_to_refresh.dart';
import '../../domain/entities/problem_report.dart';
import '../../domain/entities/problem_report_status.dart';
import '../problem_reports_l10n.dart';
import '../state/problem_report_providers.dart';
import '../widgets/problem_report_status_pill.dart';

/// `13 · Report a problem` screen 4 — "تفاصيل البلاغ" ("track report"). Shows
/// the authoritative status the backend has resolved for this report; the
/// guest can reach reception directly from here.
class ProblemReportDetailPage extends ConsumerWidget {
  const ProblemReportDetailPage({
    super.key,
    required this.reservationId,
    required this.reportId,
  });

  final String reservationId;
  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ProblemReportKey key = (
      reservationId: reservationId,
      reportId: reportId,
    );
    final AsyncValue<ProblemReport> reportAsync = ref.watch(
      problemReportProvider(key),
    );

    return Scaffold(
      appBar: HotelAppBar(title: l10n.reportDetailTitle),
      body: SafeArea(
        child: PullToRefresh(
          onRefresh: () => ref.refresh(problemReportProvider(key).future),
          child: reportAsync.when(
            // A failed refresh keeps the last good data on screen.
            skipError: true,
            loading: () =>
                Center(child: LoadingView(label: l10n.stateLoadingTitle)),
            error: (Object e, StackTrace _) => MessageView(
              icon: AppIcons.report,
              title: l10n.reportNotFoundTitle,
              message: ErrorMapper.toFailure(e).localizedMessage(l10n),
              actionLabel: l10n.actionRetry,
              onAction: () => ref.invalidate(problemReportProvider(key)),
            ),
            data: (ProblemReport report) => _Body(report: report),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.report});

  final ProblemReport report;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final MaterialLocalizations ml = MaterialLocalizations.of(context);

    final InfoBannerTone tone = switch (report.status) {
      ProblemReportStatus.open => InfoBannerTone.warning,
      ProblemReportStatus.inProgress => InfoBannerTone.info,
      ProblemReportStatus.resolved => InfoBannerTone.success,
    };

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            children: <Widget>[
              InfoBanner(
                tone: tone,
                title: l10n.problemCategoryLabel(report.category),
                message: l10n.reportDetailBody,
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
                            l10n.problemCategoryLabel(report.category),
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        ProblemReportStatusPill(status: report.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.problemUrgencyLabel(report.urgency),
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (report.hasNotes) ...<Widget>[
                      const Divider(height: AppSpacing.lg),
                      Text(report.notes!, style: theme.textTheme.bodyMedium),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      ml.formatMediumDate(report.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
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
          child: SecondaryButton(
            label: l10n.reportContactReceptionCta,
            onPressed: () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l10n.navComingSoon))),
          ),
        ),
      ],
    );
  }
}
