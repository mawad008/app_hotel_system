import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/pull_to_refresh.dart';
import '../../../app_content/domain/entities/app_content.dart';
import '../../../app_content/presentation/state/app_content_providers.dart';

/// "الأسئلة الشائعة" — the dashboard-managed FAQ (Guest app page), shown in
/// the current language with the other one as fallback.
class FaqPage extends ConsumerWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final Locale locale = Localizations.localeOf(context);
    final AsyncValue<List<FaqEntry>> faq = ref.watch(faqProvider);
    String text(ManagedText t) => t.resolve(locale) ?? t.ar ?? t.en ?? '';

    return Scaffold(
      appBar: HotelAppBar(title: l10n.profileFaq),
      body: SafeArea(
        child: PullToRefresh(
          onRefresh: () => ref.refresh(faqProvider.future),
          child: faq.when(
            // A failed refresh keeps the last good data on screen.
            skipError: true,
            loading: () =>
                Center(child: LoadingView(label: l10n.stateLoadingTitle)),
            error: (Object e, StackTrace _) => MessageView(
              icon: AppIcons.faq,
              title: l10n.stateErrorTitle,
              message: ErrorMapper.toFailure(e).localizedMessage(l10n),
              actionLabel: l10n.actionRetry,
              onAction: () => ref.invalidate(faqProvider),
            ),
            data: (List<FaqEntry> items) => items.isEmpty
                ? MessageView(
                    icon: AppIcons.faq,
                    title: l10n.profileFaqEmptyTitle,
                    message: l10n.profileFaqEmptyBody,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int i) => _FaqTile(
                      question: text(items[i].question),
                      answer: text(items[i].answer),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    final TextTheme text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: c.borderDefault, width: 0.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: c.textPrimary,
          collapsedIconColor: c.textSecondary,
          title: Text(
            question,
            style: text.bodyLarge?.copyWith(
              fontSize: 15,
              height: 26 / 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          children: <Widget>[
            Text(
              answer,
              style: text.bodyMedium?.copyWith(
                fontSize: 14,
                height: 24 / 14,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
