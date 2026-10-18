import 'package:flutter/material.dart';

import '../widgets/entry_splash_backdrop.dart';

/// Shown while [AuthState.unknown] — the stored session is being restored. The
/// router replaces it with the entry flow or the home screen as soon as restore
/// resolves.
///
/// v2 Figma `ENTRY_Splash` (`14 · Entry, loyalty & completion`): a white field
/// with the two-tone brand mark and the "Hotel System" wordmark, centred. No
/// tagline, no spinner. The lock-up plays a short entrance on top of that
/// (mark breath, gold ripples, sheen, wordmark rising in).
class AuthSplashPage extends StatelessWidget {
  const AuthSplashPage({super.key});

  @override
  Widget build(BuildContext context) => const EntrySplashBackdrop(animateEntrance: true);
}
