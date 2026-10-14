import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/platform/external_launcher.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../domain/entities/app_content.dart';

/// Runs a dashboard-managed contact / link action and tells the guest when
/// the device could not open it (no dialer, no mail app, no WhatsApp…).
Future<void> openBrandLink(
  BuildContext context,
  WidgetRef ref,
  Future<bool> Function(ExternalLauncher launcher) action,
) async {
  final String failed = context.l10n.linkOpenFailed;
  final bool opened = await action(ref.read(externalLauncherProvider));
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(failed)));
  }
}

/// `PROFILE_Support` "تواصل معنا": one row per contact the hotel set on the
/// dashboard (Guest app → Support contacts). Renders nothing when none is set.
class SupportContactsCard extends ConsumerWidget {
  const SupportContactsCard({super.key, required this.contacts});

  final SupportContacts contacts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (contacts.isEmpty) return const SizedBox.shrink();
    final AppLocalizations l10n = context.l10n;

    return SettingsCard(
      borderWidth: 1,
      children: <Widget>[
        if (contacts.phone case final String phone)
          SettingsRow(
            icon: AppIcons.phone,
            label: l10n.supportCall,
            value: phone,
            onTap: () => openBrandLink(context, ref, (l) => l.dial(phone)),
          ),
        if (contacts.whatsapp case final String number)
          SettingsRow(
            icon: AppIcons.whatsapp,
            label: l10n.supportWhatsapp,
            value: number,
            onTap: () => openBrandLink(context, ref, (l) => l.whatsapp(number)),
          ),
        if (contacts.email case final String email)
          SettingsRow(
            icon: AppIcons.email,
            label: l10n.supportEmail,
            value: email,
            onTap: () => openBrandLink(context, ref, (l) => l.email(email)),
          ),
        if (contacts.website case final String website)
          SettingsRow(
            icon: AppIcons.website,
            label: l10n.supportWebsite,
            onTap: () => openBrandLink(context, ref, (l) => l.openUrl(website)),
          ),
      ],
    );
  }
}

/// The hotel's terms / privacy links (dashboard → Guest app → Legal links) as
/// compact text buttons, for the sign-in screen's "by continuing you agree…".
/// Renders nothing when neither is set.
class LegalLinksRow extends ConsumerWidget {
  const LegalLinksRow({super.key, required this.content});

  final AppContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final String? terms = content.termsUrl;
    final String? privacy = content.privacyUrl;
    if (terms == null && privacy == null) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.center,
      children: <Widget>[
        if (terms != null)
          TextButton(
            onPressed: () => openBrandLink(context, ref, (l) => l.openUrl(terms)),
            child: Text(l10n.legalTerms),
          ),
        if (privacy != null)
          TextButton(
            onPressed: () => openBrandLink(context, ref, (l) => l.openUrl(privacy)),
            child: Text(l10n.legalPrivacy),
          ),
      ],
    );
  }
}
