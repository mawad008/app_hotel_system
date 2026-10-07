import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/bottom_action_bar.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/identity_document.dart';
import '../identity_verification_l10n.dart';

/// The guest's ID details, entered before the document photo: document type
/// (Egyptian National ID / Saudi National ID / Saudi Iqama / Passport), full
/// name, document number and — unless the number encodes it (Egypt) — date of
/// birth. The backend compares them with what its OCR reads off the document
/// (it never stores or returns them).
///
/// The chosen type explains which sides must be photographed (front only /
/// front + back / back optional) from the server's document-type catalog.
///
/// Not on the v2 Figma board — built from the design-system primitives
/// (HotelAppBar, AppTextField, BottomActionBar/PrimaryButton) in the same
/// layout language as the other identity screens.
class IdentityDetailsForm extends StatefulWidget {
  const IdentityDetailsForm({
    super.key,
    required this.options,
    required this.initialType,
    required this.onSubmit,
    required this.onBack,
    this.initialClaim,
    this.profileName,
    this.highlightedFields = const <String>[],
  });

  /// Selectable types, in display order.
  final List<IdentityDocumentOption> options;
  final IdentityDocumentType initialType;
  final IdentityDocumentClaim? initialClaim;

  /// The profile name, used to prefill the name field on first entry.
  final String? profileName;

  /// Backend field codes (`name` / `number` / `birth`) the document
  /// contradicted — shown with an error so the guest knows what to check.
  final List<String> highlightedFields;

  /// [claim] is null when the chosen type needs no typed details
  /// (document-only mode).
  final void Function(IdentityDocumentType type, IdentityDocumentClaim? claim) onSubmit;
  final VoidCallback onBack;

  @override
  State<IdentityDetailsForm> createState() => _IdentityDetailsFormState();
}

class _IdentityDetailsFormState extends State<IdentityDetailsForm> {
  late IdentityDocumentType _type = widget.options.any((o) => o.type == widget.initialType)
      ? widget.initialType
      : widget.options.first.type;
  late final TextEditingController _name = TextEditingController(
    text: widget.initialClaim?.fullName ?? widget.profileName ?? '',
  );
  late final TextEditingController _number = TextEditingController(
    text: widget.initialClaim?.documentNumber ?? '',
  );
  late DateTime? _dob = widget.initialClaim?.dateOfBirth;
  bool _showErrors = false;

  IdentityDocumentOption get _option =>
      widget.options.firstWhere((o) => o.type == _type, orElse: () => widget.options.first);

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  String? _nameError(AppLocalizations l10n) {
    if (_name.text.trim().length < 2) return _showErrors ? l10n.identityFieldRequired : null;
    return widget.highlightedFields.contains('name') ? l10n.identityMismatchTitle : null;
  }

  String? _numberError(AppLocalizations l10n) {
    final String v = _number.text.trim();
    if (v.isEmpty) return _showErrors ? l10n.identityFieldRequired : null;
    if (!_type.isPlausibleNumber(v)) return _showErrors ? l10n.identityDocumentNumberInvalidForType : null;
    return widget.highlightedFields.contains('number') ? l10n.identityMismatchTitle : null;
  }

  bool get _valid =>
      _name.text.trim().length >= 2 &&
      _type.isPlausibleNumber(_number.text.trim()) &&
      (_type.birthDateInNumber || _dob != null);

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day - 1),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _submit() {
    if (!_option.detailsRequired) {
      widget.onSubmit(_type, null);
      return;
    }
    if (!_valid) {
      setState(() => _showErrors = true);
      return;
    }
    widget.onSubmit(
      _type,
      IdentityDocumentClaim(
        fullName: _name.text.trim(),
        documentNumber: _number.text.trim(),
        dateOfBirth: _type.birthDateInNumber ? null : _dob,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final String tag = Localizations.localeOf(context).toLanguageTag();
    final bool dobError = (_showErrors && _dob == null) || widget.highlightedFields.contains('birth');

    return Scaffold(
      appBar: HotelAppBar(
        title: _option.detailsRequired ? l10n.identityDetailsTitle : l10n.identityDocumentTypeLabel,
        leading: IconButton(
          icon: Icon(AppIcons.backFor(Directionality.of(context))),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: widget.onBack,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            Text(
              _option.detailsRequired ? l10n.identityDetailsBody : l10n.identityDocumentOnlyBody,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.identityDocumentTypeLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                for (final IdentityDocumentOption o in widget.options)
                  ChoiceChip(
                    key: ValueKey<String>('idv-type-${o.type.wireValue}'),
                    label: Text(l10n.identityDocumentTypeLabelFor(o.type)),
                    selected: _type == o.type,
                    onSelected: (_) => setState(() => _type = o.type),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              key: const ValueKey<String>('idv-sides'),
              children: <Widget>[
                Icon(AppIcons.identity, size: 16, color: theme.hintColor),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    _option.automaticCheck
                        ? l10n.identityDocumentSidesLabel(_option.back)
                        : '${l10n.identityDocumentSidesLabel(_option.back)} · ${l10n.identityDocumentStaffCheck}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            if (_option.detailsRequired) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                key: const ValueKey<String>('idv-name'),
                label: l10n.identityFullNameLabel,
                hintText: _type.arabicDocument ? l10n.identityFullNameArabicHint : l10n.identityFullNameHint,
                controller: _name,
                errorText: _nameError(l10n),
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                key: const ValueKey<String>('idv-number'),
                label: l10n.identityDocumentNumberLabel,
                controller: _number,
                errorText: _numberError(l10n),
                keyboardType: _type == IdentityDocumentType.passport ? TextInputType.visiblePassword : TextInputType.number,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_type.birthDateInNumber)
                Text(
                  l10n.identityBirthDateFromNumber,
                  key: const ValueKey<String>('idv-dob-from-number'),
                  style: theme.textTheme.bodySmall,
                )
              else ...<Widget>[
                Text(l10n.identityDateOfBirthLabel, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  key: const ValueKey<String>('idv-dob'),
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      errorText: dobError
                          ? (_dob == null ? l10n.identityFieldRequired : l10n.identityMismatchTitle)
                          : null,
                    ),
                    child: Text(
                      _dob == null ? l10n.identityDateOfBirthHint : DateFormat.yMMMMd(tag).format(_dob!),
                      style: _dob == null
                          ? theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)
                          : theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        children: <Widget>[
          PrimaryButton(
            key: const ValueKey<String>('idv-details-continue'),
            label: l10n.identityReviewContinueCta,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
