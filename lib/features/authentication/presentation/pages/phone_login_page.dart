import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/datasources/auth_demo_config.dart';
import '../../domain/entities/guest_phone.dart';
import '../../domain/validators/auth_validators.dart';
import '../state/login_flow_controller.dart';
import '../state/post_auth_redirect_controller.dart';
import '../widgets/phone_number_field.dart';

/// `09 · Authentication` — "Enter your mobile number". Collects the phone,
/// validates its shape locally, and asks the backend to send a code.
class PhoneLoginPage extends ConsumerStatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  ConsumerState<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends ConsumerState<PhoneLoginPage> {
  final TextEditingController _controller = TextEditingController();
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  GuestPhone get _phone =>
      GuestPhone.fromInput(rawNationalNumber: _controller.text);

  void _submit() {
    setState(() => _showValidation = true);
    if (AuthValidators.saudiPhone(_controller.text) != null) return;
    FocusScope.of(context).unfocus();
    ref.read(loginFlowControllerProvider.notifier).submitPhone(_phone);
  }

  /// Every entry point reaches sign-in with `context.go`, so there is nothing
  /// to pop. Return to the screen that asked for sign-in (e.g. the booking
  /// review) when one was remembered, otherwise to discovery — and drop the
  /// remembered target so a later, unrelated sign-in does not jump there.
  void _leave() {
    final String target =
        ref.read(postAuthRedirectProvider.notifier).consume() ??
        AppRoutes.discover;
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final AppConfig config = ref.watch(appConfigProvider);

    final LoginFlowState flow = ref.watch(loginFlowControllerProvider);
    ref.listen<LoginFlowState>(loginFlowControllerProvider, (
      _,
      LoginFlowState next,
    ) {
      if (next is LoginOtpStep) context.goNamed(AppRoutes.otpName);
    });

    final FormSubmissionView submission = _viewOf(flow);
    final PhoneInputError? error = _showValidation
        ? AuthValidators.saudiPhone(_controller.text)
        : null;

    // Android's system back would otherwise close the app here.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: HotelAppBar(title: l10n.authPhoneTitle, onBack: _leave),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            children: <Widget>[
              Text(l10n.authPhoneHeading, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.authPhoneBody, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xl),
              PhoneNumberField(
                label: l10n.authPhoneFieldLabel,
                hintText: l10n.authPhoneFieldHint,
                controller: _controller,
                enabled: !submission.inProgress,
                onSubmitted: _submit,
                errorText: switch (error) {
                  PhoneInputError.empty => l10n.authPhoneInvalid,
                  PhoneInputError.invalid => l10n.authPhoneInvalid,
                  null => null,
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.authPhoneHelper, style: theme.textTheme.bodySmall),
              if (config.useDummyData) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.authDemoHint(AuthDemoConfig.acceptedCode),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              if (submission.failure != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  submission.failure!.localizedMessage(l10n),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: l10n.authPhoneSubmit,
                isLoading: submission.inProgress,
                onPressed: submission.inProgress ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.authPhoneTerms,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  FormSubmissionView _viewOf(LoginFlowState flow) {
    if (flow is LoginPhoneStep) {
      return FormSubmissionView(
        inProgress: flow.submission.isInProgress,
        failure: flow.submission.failureOrNull,
      );
    }
    return const FormSubmissionView(inProgress: false, failure: null);
  }
}

/// Small view-model so the widget does not re-derive submission flags inline.
class FormSubmissionView {
  const FormSubmissionView({required this.inProgress, required this.failure});
  final bool inProgress;
  final Failure? failure;
}
