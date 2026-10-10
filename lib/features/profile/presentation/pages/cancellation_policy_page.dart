import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/pull_to_refresh.dart';
import '../../../app_content/presentation/state/app_content_providers.dart';
import '../../../bookings/presentation/widgets/cancellation_policy_card.dart';

/// "سياسة الإلغاء" from Support — the same policy card every booking detail
/// shows.
class CancellationPolicyPage extends ConsumerWidget {
  const CancellationPolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int? hours = ref
        .watch(appContentProvider)
        .valueOrNull
        ?.freeCancellationHours;
    return Scaffold(
      appBar: HotelAppBar(title: context.l10n.bookingCancellationPolicyHeading),
      body: SafeArea(
        child: PullToRefresh(
          onRefresh: () => ref.refresh(appContentProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              // The platform rule, with the window the server configures.
              if (hours == null)
                const LoadingView()
              else
                CancellationPolicyCard(freeCancellationHours: hours),
            ],
          ),
        ),
      ),
    );
  }
}
