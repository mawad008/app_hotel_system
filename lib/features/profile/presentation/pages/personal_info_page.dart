import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../authentication/domain/entities/guest_profile.dart';
import '../../../authentication/domain/validators/auth_validators.dart';
import '../../../authentication/presentation/state/auth_controller.dart';
import '../../../authentication/presentation/state/auth_state.dart';
import '../state/account_providers.dart';
import '../widgets/profile_subpage.dart';

/// `PROFILE_PersonalInfo` ("بياناتي"). Name and phone are read-only — the
/// banner sends name / ID corrections to reception (they must match the
/// verified ID); the guest can change their email, saved with
/// `PATCH /guest/profile` on "حفظ التعديلات".
class PersonalInfoPage extends ConsumerStatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  ConsumerState<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends ConsumerState<PersonalInfoPage> {
  String? _draftEmail;
  bool _saving = false;

  Future<void> _editEmail(String current) async {
    final String? next = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext ctx) => _EmailSheet(initial: current),
    );
    if (next != null && mounted) setState(() => _draftEmail = next);
  }

  Future<void> _save(GuestProfile profile) async {
    final AppLocalizations l10n = context.l10n;
    setState(() => _saving = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateContactDetails(
            fullName: profile.fullName ?? '',
            email: _draftEmail!,
          );
      if (!mounted) return;
      setState(() => _draftEmail = null);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
    } on Failure catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(failure.localizedMessage(l10n))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AuthState auth = ref.watch(authControllerProvider);
    final GuestProfile? profile = auth is Authenticated
        ? auth.session.profile
        : null;
    final bool trusted =
        ref.watch(accountSummaryProvider).valueOrNull?.trustedGuest ?? false;
    final String email = _draftEmail ?? profile?.email ?? '';
    final bool dirty = _draftEmail != null && _draftEmail != profile?.email;

    return ProfileSubpage(
      onRefresh: () => ref.refresh(accountSummaryProvider.future),
      title: l10n.profilePersonalInfoTitle,
      bannerTitle: l10n.profilePersonalInfoBannerTitle,
      bannerMessage: l10n.profilePersonalInfoBannerBody,
      cards: <Widget>[
        SettingsCard(
          borderWidth: 1,
          children: <Widget>[
            SettingsRow(
              label: l10n.profileNameLabel,
              value: profile?.fullName ?? '—',
            ),
            SettingsRow(
              label: l10n.profilePhoneLabel,
              // Bidi-isolated so "+966 …" keeps its order in RTL.
              value: profile == null
                  ? '—'
                  : '\u2066${profile.phone.display}\u2069',
            ),
            SettingsRow(
              label: l10n.profileEmailLabel,
              value: email.isEmpty ? l10n.profileEmailAdd : email,
              onTap: profile == null ? null : () => _editEmail(email),
            ),
          ],
        ),
        SettingsCard(
          borderWidth: 1,
          children: <Widget>[
            SettingsRow(
              label: l10n.profileVerifiedIdentityLabel,
              value: trusted ? l10n.profileVerified : l10n.profileNotVerified,
            ),
          ],
        ),
      ],
      footer: PrimaryButton(
        label: l10n.profileSaveChanges,
        isLoading: _saving,
        onPressed: dirty && !_saving && profile != null
            ? () => _save(profile)
            : null,
      ),
    );
  }
}

class _EmailSheet extends StatefulWidget {
  const _EmailSheet({required this.initial});

  final String initial;

  @override
  State<_EmailSheet> createState() => _EmailSheetState();
}

class _EmailSheetState extends State<_EmailSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String value = _controller.text.trim();
    if (AuthValidators.email(value) != null) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            label: l10n.authProfileEmailLabel,
            hintText: l10n.authProfileEmailHint,
            controller: _controller,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            errorText: _showError ? l10n.authProfileEmailInvalid : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: l10n.profileDone, onPressed: _submit),
        ],
      ),
    );
  }
}
