import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/localization/supported_locales.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../../core/widgets/pull_to_refresh.dart';
import '../../domain/entities/guest_preferences.dart';
import '../state/account_providers.dart';
import '../state/profile_providers.dart';
import '../widgets/profile_subpage.dart';

/// `PROFILE_Preferences` ("تفضيلاتي"): stay preferences every hotel of the
/// group reads (high floor, extra pillows — stored on the backend), the
/// email/SMS opt-out, and the app language. The room type is read-only — it
/// comes from the guest's booking history. Tapping a toggle row flips the
/// draft; "حفظ" writes it to the server.
class PreferencesPage extends ConsumerStatefulWidget {
  const PreferencesPage({super.key});

  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
  GuestPreferences? _draft;
  bool _saving = false;

  Future<void> _save() async {
    final AppLocalizations l10n = context.l10n;
    setState(() => _saving = true);
    try {
      await ref
          .read(guestAccountSettingsProvider.notifier)
          .savePreferences(_draft!);
      if (!mounted) return;
      setState(() => _draft = null);
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

  Future<void> _pickLanguage() async {
    final AppLocalizations l10n = context.l10n;
    final Locale current = Localizations.localeOf(context);
    final Locale? picked = await showModalBottomSheet<Locale>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: SettingsCard(
            borderWidth: 1,
            children: <Widget>[
              for (final (Locale locale, String label) in <(Locale, String)>[
                (SupportedLocales.arabic, l10n.languageArabic),
                (SupportedLocales.english, l10n.languageEnglish),
              ])
                SettingsRow(
                  icon: current.languageCode == locale.languageCode
                      ? AppIcons.success
                      : AppIcons.language,
                  label: label,
                  onTap: () => Navigator.of(ctx).pop(locale),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) ref.read(localeControllerProvider.notifier).set(picked);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<GuestAccountSettings> settings = ref.watch(
      guestAccountSettingsProvider,
    );
    final Locale locale = Localizations.localeOf(context);

    Future<void> refresh() {
      ref.invalidate(accountSummaryProvider);
      return ref.refresh(guestAccountSettingsProvider.future);
    }

    return settings.when(
      // A failed refresh keeps the last good data on screen.
      skipError: true,
      loading: () => Scaffold(
        appBar: HotelAppBar(title: l10n.profilePreferencesTitle),
        body: Center(child: LoadingView(label: l10n.stateLoadingTitle)),
      ),
      error: (Object e, StackTrace _) => Scaffold(
        appBar: HotelAppBar(title: l10n.profilePreferencesTitle),
        body: PullToRefresh(
          onRefresh: refresh,
          child: MessageView(
            icon: AppIcons.settings,
            title: l10n.stateErrorTitle,
            message: ErrorMapper.toFailure(e).localizedMessage(l10n),
            actionLabel: l10n.actionRetry,
            onAction: () => ref.invalidate(guestAccountSettingsProvider),
          ),
        ),
      ),
      data: (GuestAccountSettings saved) {
        final GuestPreferences prefs = _draft ?? saved.preferences;
        String onOff(bool on) => on ? l10n.profilePrefOn : l10n.profilePrefOff;
        void edit(GuestPreferences next) =>
            setState(() => _draft = next == saved.preferences ? null : next);
        final String? roomType = ref
            .watch(accountSummaryProvider)
            .valueOrNull
            ?.preferredRoomName
            ?.resolve(locale);

        return ProfileSubpage(
          onRefresh: refresh,
          title: l10n.profilePreferencesTitle,
          bannerTitle: l10n.profilePreferencesBannerTitle,
          bannerMessage: l10n.profilePreferencesBannerBody,
          cards: <Widget>[
            SettingsCard(
              borderWidth: 1,
              children: <Widget>[
                SettingsRow(
                  label: l10n.profilePrefRoomType,
                  value: roomType ?? l10n.accountPreferencesEmpty,
                ),
                SettingsRow(
                  label: l10n.profilePrefHighFloor,
                  value: onOff(prefs.highFloor),
                  onTap: () =>
                      edit(prefs.copyWith(highFloor: !prefs.highFloor)),
                ),
                SettingsRow(
                  label: l10n.profilePrefExtraPillows,
                  value: onOff(prefs.extraPillows),
                  onTap: () =>
                      edit(prefs.copyWith(extraPillows: !prefs.extraPillows)),
                ),
              ],
            ),
            SettingsCard(
              borderWidth: 1,
              children: <Widget>[
                SettingsRow(
                  label: l10n.profilePrefLanguage,
                  value: locale.languageCode == 'ar'
                      ? l10n.languageArabic
                      : l10n.languageEnglish,
                  onTap: _pickLanguage,
                ),
                SettingsRow(
                  label: l10n.profilePrefNotifications,
                  value: prefs.notificationsEnabled
                      ? l10n.profilePrefOnFeminine
                      : l10n.profilePrefOffFeminine,
                  onTap: () => edit(
                    prefs.copyWith(
                      notificationsEnabled: !prefs.notificationsEnabled,
                    ),
                  ),
                ),
              ],
            ),
          ],
          footer: PrimaryButton(
            label: l10n.profileSave,
            isLoading: _saving,
            onPressed: _draft != null && !_saving ? _save : null,
          ),
        );
      },
    );
  }
}
