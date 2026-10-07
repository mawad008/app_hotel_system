import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// One row of the v2 list cards (`PROFILE_*`, `NOTIFICATIONS_List`,
/// `STAY_Requests_List`, …), laid out to the Figma frames: a 60px row — a
/// 36×36 `bg/subtle` icon tile (radius 12, 18px glyph), 12px gap, the label
/// (15/26, text primary) and an optional trailing value (14/24, text
/// secondary). Rows sit in a [SettingsCard], spaced 10px apart, no dividers.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.emphasized = false,
    this.trailing,
  });

  /// The 36px tile glyph. Null = a text-only row (the `PROFILE_*`
  /// sub-screens), 50px tall.
  final IconData? icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  /// Unread notifications / items needing attention: medium-weight label.
  final bool emphasized;

  /// Optional end-side widget after [value] (e.g. a selection mark).
  final Widget? trailing;

  static const double _tile = 36;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorTokens c = context.colors;
    final Widget labelText = Text(
      label,
      maxLines: 1,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontSize: 15,
        height: 26 / 15,
        color: c.textPrimary,
        fontWeight: emphasized ? FontWeight.w500 : FontWeight.w400,
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.allSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Container(
                width: _tile,
                height: _tile,
                decoration: BoxDecoration(
                  color: c.bgSubtle,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: Icon(icon, size: 18, color: c.textPrimary),
              ),
              const SizedBox(width: 12),
            ],
            // The label is never squeezed: a long value (an e-mail address)
            // takes the remaining width and ellipsizes instead of pushing the
            // label into a narrow column that wraps letter by letter.
            if (value == null)
              Expanded(child: labelText)
            else ...<Widget>[
              labelText,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 24 / 14,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// The white v2 list card that holds [SettingsRow]s: 0.5px `border/default`
/// stroke, radius 20, 18px padding, rows 10px apart.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children, this.borderWidth = 0.5});

  final List<Widget> children;

  /// 0.5 on `PROFILE_Home`; the sub-screens and feeds use 1.
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: c.borderDefault, width: borderWidth),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int i = 0; i < children.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 10),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
