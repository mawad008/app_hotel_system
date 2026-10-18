import 'package:flutter/material.dart';

import '../widgets/entry_splash_backdrop.dart';

/// Shown while [AuthState.unknown] — the stored session is being restored. The
/// router replaces it with the entry flow or the home screen as soon as restore
/// resolves.
///
/// The brand navy field with the STDY HOTELS lock-up (app icon over the
/// wordmark), centred — matching the native launch screen. No tagline, no
/// spinner.
class AuthSplashPage extends StatelessWidget {
  const AuthSplashPage({super.key});

  @override
  Widget build(BuildContext context) => const EntrySplashBackdrop();
}
