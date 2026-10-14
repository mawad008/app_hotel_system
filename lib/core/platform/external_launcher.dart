import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hands a phone number, WhatsApp chat, email address, web link or map
/// location to the device (dialer / WhatsApp / mail app / browser / maps).
/// Behind a provider so widget tests can assert the call without a platform.
abstract interface class ExternalLauncher {
  /// Opens the dialer for [phone]. Returns false when the device can't
  /// place calls (e.g. a tablet / simulator) so the UI can say so.
  Future<bool> dial(String phone);

  /// Opens the device maps app on the coordinate.
  Future<bool> openMap({required double latitude, required double longitude});

  /// Opens a WhatsApp chat with [phone] (international format).
  Future<bool> whatsapp(String phone);

  /// Opens the mail app addressed to [email].
  Future<bool> email(String email);

  /// Opens an `http(s)` [url] in the browser; anything else is refused.
  Future<bool> openUrl(String url);
}

class UrlExternalLauncher implements ExternalLauncher {
  const UrlExternalLauncher();

  @override
  Future<bool> dial(String phone) async {
    // Keep only what a `tel:` URI allows (digits and a leading +).
    final String digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return false;
    return _launch(Uri(scheme: 'tel', path: digits));
  }

  @override
  Future<bool> openMap({required double latitude, required double longitude}) {
    // The universal `geo:` / Apple Maps forms differ per platform; the
    // Google Maps search URL opens the native maps app on both, or the
    // browser as a fallback.
    return _launch(
      Uri.https('www.google.com', '/maps/search/', <String, String>{
        'api': '1',
        'query': '$latitude,$longitude',
      }),
    );
  }

  @override
  Future<bool> whatsapp(String phone) async {
    // wa.me takes the international number as bare digits.
    final String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return false;
    return _launch(Uri.https('wa.me', '/$digits'));
  }

  @override
  Future<bool> email(String email) async {
    if (!email.contains('@')) return false;
    return _launch(Uri(scheme: 'mailto', path: email.trim()));
  }

  @override
  Future<bool> openUrl(String url) async {
    final Uri? uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return false;
    }
    return _launch(uri);
  }

  Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception catch (e) {
      debugPrint('External launch failed for ${uri.scheme}: $e');
      return false;
    }
  }
}

final externalLauncherProvider = Provider<ExternalLauncher>(
  (Ref ref) => const UrlExternalLauncher(),
);
