import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/di/core_providers.dart';
import '../features/authentication/presentation/state/auth_controller.dart';
import '../core/health/domain/backend_health.dart';
import '../core/health/presentation/backend_health_controller.dart';
import '../core/localization/l10n.dart';
import '../core/localization/locale_controller.dart';
import '../core/localization/supported_locales.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_icon_button.dart';
import '../core/widgets/app_list_row.dart';
import '../core/widgets/app_text_field.dart';
import '../core/widgets/hotel_app_bar.dart';
import '../core/widgets/primary_button.dart';
import '../core/widgets/secondary_button.dart';
import '../core/widgets/section_header.dart';
import '../core/widgets/status_pill.dart';
import '../core/widgets/ui_state_view.dart';
import '../core/widgets/app_icons.dart';

/// Phase 0 placeholder screen.
///
/// It is intentionally NOT a product feature — it exists to exercise and
/// document the foundation: design tokens, localization + RTL, theme switching,
/// and one full UI → state → repository → data-source slice (backend health).
/// Feature screens arrive in later mobile phases.
class FoundationHomePage extends ConsumerWidget {
  const FoundationHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppConfig config = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: HotelAppBar(
        title: l10n.foundationScreenTitle,
        actions: <Widget>[
          IconButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
            tooltip: l10n.authSignOut,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pageGutter),
          children: <Widget>[
            Text(
              l10n.appTagline,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.foundationScreenSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            _EnvironmentCard(config: config),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: l10n.sectionLanguage,
              child: const _LanguageSelector(),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: l10n.sectionBackendStatus,
              child: const _BackendStatusView(),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionCard(
              title: l10n.sectionComponents,
              child: _ComponentGallery(l10n: l10n),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _EnvironmentCard extends StatelessWidget {
  const _EnvironmentCard({required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.environmentLabel(config.environment.name),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.apiBaseUrlLabel(config.apiRoot),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final Locale current = Localizations.localeOf(context);
    return SegmentedButton<String>(
      segments: <ButtonSegment<String>>[
        ButtonSegment<String>(value: 'en', label: Text(l10n.languageEnglish)),
        ButtonSegment<String>(value: 'ar', label: Text(l10n.languageArabic)),
      ],
      selected: <String>{current.languageCode},
      onSelectionChanged: (Set<String> selection) {
        ref
            .read(localeControllerProvider.notifier)
            .set(
              selection.first == 'ar'
                  ? SupportedLocales.arabic
                  : SupportedLocales.english,
            );
      },
    );
  }
}

class _BackendStatusView extends ConsumerWidget {
  const _BackendStatusView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final state = backendHealthUiState(
      ref.watch(backendHealthControllerProvider),
    );

    return UiStateView<BackendHealth>(
      state: state,
      onRetry: () =>
          ref.read(backendHealthControllerProvider.notifier).refresh(),
      onSuccess: (BackendHealth health) {
        final AppColorTokens c = context.colors;
        final (String label, Color fg, Color bg) = switch (health.status) {
          HealthStatus.ok => (l10n.backendStatusOk, c.successFg, c.successBg),
          HealthStatus.degraded => (
            l10n.backendStatusDegraded,
            c.warningFg,
            c.warningBg,
          ),
          HealthStatus.down => (l10n.backendStatusDown, c.errorFg, c.errorBg),
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            StatusPill(
              label: label,
              foreground: fg,
              background: bg,
              icon: Icons.circle,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.backendStatusCheckedAt(
                TimeOfDay.fromDateTime(health.checkedAt).format(context),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: l10n.actionCheckAgain,
              icon: AppIcons.refresh,
              onPressed: () =>
                  ref.read(backendHealthControllerProvider.notifier).refresh(),
            ),
          ],
        );
      },
    );
  }
}

class _ComponentGallery extends StatelessWidget {
  const _ComponentGallery({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PrimaryButton(label: l10n.actionPrimaryExample, onPressed: () {}),
        const SizedBox(height: AppSpacing.xs),
        SecondaryButton(label: l10n.actionSecondaryExample, onPressed: () {}),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: l10n.textFieldExampleLabel,
          hintText: l10n.textFieldExampleHint,
        ),
        const SizedBox(height: AppSpacing.sm),
        SectionHeader(
          title: l10n.sectionComponents,
          action: l10n.commonSeeAll,
          onAction: () {},
        ),
        Row(
          children: <Widget>[
            AppIconButton(icon: AppIcons.search, onPressed: () {}),
            const SizedBox(width: AppSpacing.xs),
            AppIconButton(
              icon: AppIcons.rating,
              onPressed: () {},
              selected: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          style: AppCardStyle.subtle,
          child: Column(
            children: <Widget>[
              AppListRow(
                label: l10n.reservationStatusConfirmed,
                value: Text(l10n.commonSeeAll),
              ),
              AppListRow(
                label: l10n.reservationStatusConfirmed,
                value: Text(l10n.commonSeeAll),
                style: AppListRowStyle.total,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
