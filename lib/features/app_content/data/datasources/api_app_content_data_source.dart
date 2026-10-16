import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show debugPrint;

import '../../../../core/data/data_source.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../domain/entities/app_content.dart';
import 'app_content_data_source.dart';

typedef Json = Map<String, Object?>;

/// API-backed source: `GET /guest/app-content` (anonymous — shown before any
/// sign-in). Text arrives as full `{"en","ar"}` maps so the entry screens can
/// switch language client-side; image URLs are re-hosted for the emulator via
/// [ApiClient.resolveMediaUrl], never fabricated.
///
/// Every successful response is kept in [AppPreferences.appContentCache] so
/// the next launch (or an offline one) shows the hotel's branding at once —
/// see [cachedContent].
class ApiAppContentDataSource
    implements AppContentDataSource, RemoteDataSource {
  ApiAppContentDataSource(this._client, [this._preferences]);

  final ApiClient _client;
  final AppPreferences? _preferences;

  @override
  Future<AppContent> fetchContent() async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/app-content',
    );
    // Parsed before caching, so a response this version cannot read is never
    // stored and replayed on every later launch.
    final AppContent content = _parse(json);
    if (json['data'] is Json) {
      // Best effort: a failed write only costs the next launch's head start.
      _preferences?.setAppContentCache(jsonEncode(json)).ignore();
    }
    return content;
  }

  /// The last response this device received, or null when there is none (or
  /// it can no longer be read).
  AppContent? cachedContent() {
    final String? raw = _preferences?.appContentCache;
    if (raw == null || raw.isEmpty) return null;
    try {
      final Object? json = jsonDecode(raw);
      return json is Json ? _parse(json) : null;
    } catch (e) {
      // Any unreadable cache (bad JSON, or a shape an older build stored)
      // must fall back to the bundled defaults, never break app start-up.
      debugPrint('appContent: unreadable cache — $e');
      return null;
    }
  }

  AppContent _parse(Json json) {
    final Object? data = json['data'];
    if (data is! Json) return AppContent.empty;
    // Laravel sends an empty object as `[]`, so every nested object and
    // number is read leniently: a missing or oddly typed field falls back to
    // the bundled default instead of throwing.
    final Json policy = _map(_map(json['meta'])['booking_policy']);
    final Json support = _map(data['support']);
    final Json legal = _map(data['legal']);

    return AppContent(
      appName: _text(data['app_name_i18n']),
      logoUrl: _url(data['logo_url']),
      onboardingImageUrl: _url(data['onboarding_image_url']),
      appIconUrl: _url(data['app_icon_url']),
      primaryColor: _color(data['primary_color']),
      support: SupportContacts(
        phone: _string(support['phone']),
        whatsapp: _string(support['whatsapp']),
        email: _string(support['email']),
        website: _string(support['website']),
      ),
      termsUrl: _string(legal['terms_url']),
      privacyUrl: _string(legal['privacy_url']),
      onboardingTitle: _text(data['onboarding_title_i18n']),
      onboardingBody: _text(data['onboarding_body_i18n']),
      onboardingCta: _text(data['onboarding_cta_i18n']),
      freeCancellationHours: _int(policy['free_cancellation_hours']),
      identityRetentionDays: _int(policy['identity_retention_days']),
      faq: <FaqEntry>[
        for (final Object? item in data['faq'] is List ? data['faq']! as List<Object?> : const <Object?>[])
          if (item is Json)
            FaqEntry(
              question: _text(item['question_i18n']),
              answer: _text(item['answer_i18n']),
            ),
      ],
    );
  }

  String? _url(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return _client.resolveMediaUrl(raw);
  }

  static Json _map(Object? raw) =>
      raw is Map ? raw.cast<String, Object?>() : const <String, Object?>{};

  static int? _int(Object? raw) => switch (raw) {
    final num n => n.toInt(),
    final String s => int.tryParse(s.trim()),
    _ => null,
  };

  static String? _string(Object? raw) =>
      raw is String && raw.trim().isNotEmpty ? raw.trim() : null;

  /// `#RRGGBB` → an opaque [Color]; anything else → null (built-in palette).
  static Color? _color(Object? raw) {
    if (raw is! String) return null;
    final RegExpMatch? m = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(raw.trim());
    if (m == null) return null;
    return Color(0xFF000000 | int.parse(m.group(1)!, radix: 16));
  }

  static ManagedText _text(Object? raw) {
    if (raw is! Map) return const ManagedText();
    String? pick(String locale) {
      final Object? v = raw[locale];
      return v is String && v.trim().isNotEmpty ? v : null;
    }

    return ManagedText(ar: pick('ar'), en: pick('en'));
  }
}
