import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/pull_to_refresh.dart';
import '../../domain/entities/problem_report.dart';
import '../state/problem_report_providers.dart';
import '../widgets/problem_report_card.dart';

/// `13 · Report a problem` — the guest's full report history for a
/// reservation. No dedicated Figma screen supplied this list; it mirrors
/// `MyServiceRequestsPage` (`11 · Services & requests` screen 3), the closest
/// existing "my X" list in the app.
class MyProblemReportsPage extends ConsumerWidget {
  const MyProblemReportsPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<List<ProblemReport>> reportsAsync = ref.watch(
      problemReportsProvider(reservationId),
    );

    return Scaffold(
      appBar: HotelAppBar(title: l10n.myReportsTitle),
      body: SafeArea(
        child: PullToRefresh(
          onRefresh: () =>
              ref.refresh(problemReportsProvider(reservationId).future),
          child: reportsAsync.when(
            // A failed refresh keeps the last good data on screen.
            skipError: true,
            loading: () =>
                Center(child: LoadingView(label: l10n.stateLoadingTitle)),
            error: (Object e, StackTrace _) => MessageView(
              icon: AppIcons.report,
              title: l10n.reportUnavailableTitle,
              message: ErrorMapper.toFailure(e).localizedMessage(l10n),
              actionLabel: l10n.actionRetry,
              onAction: () =>
                  ref.invalidate(problemReportsProvider(reservationId)),
            ),
            data: (List<ProblemReport> reports) =>
                _Body(reservationId: reservationId, reports: reports),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.reservationId, required this.reports});

  final String reservationId;
  final List<ProblemReport> reports;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    void newReport() => context.pushReplacementNamed(
      AppRoutes.reportProblemName,
      pathParameters: <String, String>{'reservationId': reservationId},
    );

    if (reports.isEmpty) {
      return Column(
        children: <Widget>[
          Expanded(
            child: EmptyView(
              icon: AppIcons.report,
              title: l10n.myReportsEmptyTitle,
              message: l10n.myReportsEmptyBody,
            ),
          ),
          _Bottom(label: l10n.newReportCta, onPressed: newReport),
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
                title: l10n.myReportsIntroBanner,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final ProblemReport report in reports) ...<Widget>[
                ProblemReportCard(
                  report: report,
                  onTap: () => context.pushNamed(
                    AppRoutes.problemReportDetailName,
                    pathParameters: <String, String>{
                      'reservationId': reservationId,
                      'reportId': report.id,
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
        _Bottom(label: l10n.newReportCta, onPressed: newReport),
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
