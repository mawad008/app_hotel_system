import 'package:flutter/widgets.dart';

/// A dashboard-managed string that may exist in either, both or neither of
/// the supported locales.
///
/// Unlike discovery's `LocalizedText`, a locale may be missing: [resolve]
/// returns `null` for it so the caller falls back to the app's bundled copy
/// in the *same* language — it never shows the other language instead.
@immutable
class ManagedText {
  const ManagedText({this.ar, this.en});

  final String? ar;
  final String? en;

  String? resolve(Locale locale) => locale.languageCode == 'ar' ? ar : en;

  @override
  bool operator ==(Object other) =>
      other is ManagedText && other.ar == ar && other.en == en;

  @override
  int get hashCode => Object.hash(ar, en);
}

/// The Guest App's branding + entry content, edited from the dashboard
/// (`GET /guest/app-content`): the app name (app title + splash wordmark),
/// the logo (splash + onboarding avatar), the app icon (web favicon /
/// home-screen icon), the brand colour, the onboarding photo and copy, the
/// support contacts and the legal links.
///
/// Every field is optional — `null` means "not configured", and the screen
/// uses its bundled Figma default (asset / vector mark / ARB string).
@immutable
class AppContent {
  const AppContent({
    this.appName = const ManagedText(),
    this.logoUrl,
    this.onboardingImageUrl,
    this.appIconUrl,
    this.primaryColor,
    this.support = SupportContacts.none,
    this.termsUrl,
    this.privacyUrl,
    this.onboardingTitle = const ManagedText(),
    this.onboardingBody = const ManagedText(),
    this.onboardingCta = const ManagedText(),
    this.faq = const <FaqEntry>[],
    this.freeCancellationHours,
    this.identityRetentionDays,
  });

  /// Nothing configured — every screen shows its bundled defaults.
  static const AppContent empty = AppContent();

  final ManagedText appName;
  final String? logoUrl;
  final String? onboardingImageUrl;

  /// Square app icon — applied as the web favicon / home-screen icon. Native
  /// launcher icons are build-time assets and cannot follow it.
  final String? appIconUrl;

  /// The brand colour (buttons, accents). Null = the built-in palette.
  final Color? primaryColor;

  /// `PROFILE_Support` contact actions; an unset one is hidden.
  final SupportContacts support;

  /// Linked from sign-in ("by continuing you agree…") and Account → Privacy.
  final String? termsUrl;
  final String? privacyUrl;
  final ManagedText onboardingTitle;
  final ManagedText onboardingBody;
  final ManagedText onboardingCta;

  /// `PROFILE_Support` "الأسئلة الشائعة", in the dashboard's order.
  final List<FaqEntry> faq;

  /// Platform booking rule from the server (`meta.booking_policy`) — the
  /// free-cancellation window the app explains. Null until loaded.
  final int? freeCancellationHours;

  /// Days the hotel keeps a stay's ID images after it ends (server config).
  final int? identityRetentionDays;
}

/// The dashboard-managed support contacts. Each is null when not configured.
@immutable
class SupportContacts {
  const SupportContacts({this.phone, this.whatsapp, this.email, this.website});

  static const SupportContacts none = SupportContacts();

  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? website;

  bool get isEmpty =>
      phone == null && whatsapp == null && email == null && website == null;
}

/// One dashboard-managed FAQ entry (question + answer, both locales).
@immutable
class FaqEntry {
  const FaqEntry({required this.question, required this.answer});

  final ManagedText question;
  final ManagedText answer;

  @override
  bool operator ==(Object other) =>
      other is FaqEntry && other.question == question && other.answer == answer;

  @override
  int get hashCode => Object.hash(question, answer);
}
