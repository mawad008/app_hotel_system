import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../domain/entities/guest_phone.dart';

/// Mobile-number input from `09 · Authentication`: a fixed `+966` dialling-code
/// box next to the national-number field. The number itself is always entered
/// left-to-right, even in an RTL layout.
class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.errorText,
    this.enabled = true,
    this.onSubmitted,
    this.dialCode = GuestPhone.defaultDialCode,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final String? errorText;
  final bool enabled;
  final VoidCallback? onSubmitted;
  final String dialCode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Directionality(
          textDirection: TextDirection.ltr,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: AppRadius.allMd,
                    border: Border.all(
                      color: hasError
                          ? theme.colorScheme.error
                          : theme.colorScheme.outline,
                    ),
                  ),
                  child: Text(
                    '🇸🇦  $dialCode',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onSubmitted?.call(),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    // The message is rendered below the whole row (in the
                    // reading direction, wrapping freely); the field only
                    // takes the error border.
                    decoration: InputDecoration(
                      hintText: hintText,
                      error: hasError ? const SizedBox.shrink() : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  AppIcons.errorOutline,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
