import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/presentation/latin_digits_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';

/// The one-time-code input from `09 · Authentication`.
///
/// One real [TextField] captures the digits (so paste and OS SMS autofill keep
/// working); the boxes above are a presentation of its value. Always laid out
/// left-to-right. Figma boxes are ~48×56 with a fixed gap and a light-red
/// **filled** error state.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.length,
    required this.controller,
    this.enabled = true,
    this.hasError = false,
    this.autofocus = true,
    this.onCompleted,
  });

  final int length;
  final TextEditingController controller;
  final bool enabled;
  final bool hasError;
  final bool autofocus;
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChange() {
    setState(() {});
    if (widget.controller.text.length == widget.length) {
      widget.onCompleted?.call(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String value = widget.controller.text;

    final Color borderColor = widget.hasError
        ? theme.colorScheme.error
        : theme.colorScheme.outline;
    final Color fill = widget.hasError
        ? AppColors.errorContainer
        : theme.colorScheme.surface;
    final Color textColor = widget.hasError
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 56,
          child: Stack(
            children: <Widget>[
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (int i = 0; i < widget.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(width: 8),
                        Container(
                          width: 48,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: fill,
                            borderRadius: AppRadius.allInput,
                            border: Border.all(
                              color: borderColor,
                              width: i < value.length ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            i < value.length ? value[i] : '',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: textColor,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    autofocus: widget.autofocus,
                    keyboardType: TextInputType.number,
                    showCursor: false,
                    enableInteractiveSelection: false,
                    inputFormatters: <TextInputFormatter>[
                      // Arabic keyboards type ٠–٩; keep them as 0–9.
                      const LatinDigitsFormatter(),
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(widget.length),
                    ],
                    decoration: const InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
