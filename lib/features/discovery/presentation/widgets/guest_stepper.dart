import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_icons.dart';

/// A labelled −/+ stepper row (booking summary + the "عدد الضيوف" sheet).
///
/// The v2 `Stepper` component: a 148×48 capsule (0.5px `border/default`,
/// 6px inset) holding two 36px round `bg/subtle` buttons around the value
/// (16 Medium). The capsule keeps − on the left and + on the right in both
/// directions, as the Figma Arabic frames do. Buttons disable at [min] /
/// [max]; when [onLimitReached] is given, + stays tappable (dimmed) at [max]
/// and reports the ceiling instead of silently doing nothing.
class GuestStepper extends StatelessWidget {
  const GuestStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onLimitReached,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final VoidCallback? onLimitReached;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;
    final AppColorTokens c = context.colors;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: c.textPrimary,
            ),
          ),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            width: 148,
            height: 48,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: c.bgSurface,
              borderRadius: const BorderRadius.all(Radius.circular(999)),
              border: Border.all(color: c.borderDefault, width: 0.5),
            ),
            child: Row(
              children: <Widget>[
                _RoundButton(
                  icon: AppIcons.remove,
                  tooltip: '${l10n.stepperDecrease} — $label',
                  onPressed: value > min ? () => onChanged(value - 1) : null,
                ),
                Expanded(
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                _RoundButton(
                  icon: AppIcons.add,
                  tooltip: '${l10n.stepperIncrease} — $label',
                  onPressed: value < max
                      ? () => onChanged(value + 1)
                      : onLimitReached,
                  dimmed: value >= max,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.dimmed = false,
  });

  final IconData icon;
  final bool dimmed;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 18),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        fixedSize: const Size(36, 36),
        minimumSize: const Size(36, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: c.bgSubtle,
        disabledBackgroundColor: c.bgSubtle,
        foregroundColor:
            dimmed ? c.textPrimary.withValues(alpha: 0.3) : c.textPrimary,
        disabledForegroundColor: c.textPrimary.withValues(alpha: 0.3),
        shape: const CircleBorder(),
      ),
    );
  }
}
