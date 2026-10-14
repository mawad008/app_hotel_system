import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icons.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// Shared layout for full-section empty / error / message states: an icon in a
/// soft circular badge, a title, an optional body, and up to two stacked
/// actions (primary + secondary) — matching the Figma empty states
/// (`لا توجد غرف متاحة …` with `تغيير التاريخ` + `تعديل عدد الضيوف`).
///
/// [EmptyView] and [ErrorView] are thin presets so call sites read clearly.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color tint = iconColor ?? theme.colorScheme.onSurfaceVariant;

    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Figma: the icon "sits in a soft tile so the block has weight
        // rather than floating" — a rounded square, not a circle. v2: a
        // white tile lifted by a soft shadow (was a stone/100 fill).
        Container(
          width: AppSizes.emptyStateTile,
          height: AppSizes.emptyStateTile,
          decoration: BoxDecoration(
            color: context.colors.bgSurface,
            borderRadius: AppRadius.allXl,
            boxShadow: theme.brightness == Brightness.light
                ? AppShadows.tile
                : AppShadows.none,
          ),
          child: Icon(icon, size: 32, color: tint),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          title,
          // v2 `Empty State` title: 18 Medium.
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: AppTypography.medium,
          ),
          textAlign: TextAlign.center,
        ),
        if (message != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            message!,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
        if (actionLabel != null && onAction != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: actionLabel!, onPressed: onAction),
        ],
        if (secondaryActionLabel != null &&
            onSecondaryAction != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          SecondaryButton(
            label: secondaryActionLabel!,
            onPressed: onSecondaryAction,
          ),
        ],
      ],
    );

    // With a bounded height the scroll view fills it (content centred), so a
    // surrounding `PullToRefresh` can be pulled from anywhere on the state,
    // not just from the small centred block.
    const double padding = AppSpacing.space6;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!constraints.hasBoundedHeight) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(padding),
              child: content,
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(padding),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - padding * 2).clamp(
                0,
                double.infinity,
              ),
            ),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}

/// Empty-state preset.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.message,
    this.icon = AppIcons.search,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return MessageView(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      secondaryActionLabel: secondaryActionLabel,
      onSecondaryAction: onSecondaryAction,
    );
  }
}

/// Error-state preset.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return MessageView(
      icon: AppIcons.warning,
      iconColor: Theme.of(context).colorScheme.error,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      secondaryActionLabel: secondaryActionLabel,
      onSecondaryAction: onSecondaryAction,
    );
  }
}
