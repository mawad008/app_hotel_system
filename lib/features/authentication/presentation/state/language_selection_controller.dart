import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_preferences.dart';

/// Whether the guest has confirmed an app language on the first-run
/// `01 · Entry` language screen.
///
/// `false` on a first launch routes the guest to `AppRoutes.language` before
/// the entry screen; [markSelected] flips it once they tap "متابعة" so the
/// screen is not shown again for the rest of the session. A guest who already
/// finished onboarding on an earlier launch ([onboardingCompletedProvider])
/// chose their language then, so it starts `true`.
class LanguageSelectionController extends Notifier<bool> {
  @override
  bool build() => ref.read(appPreferencesProvider).onboardingCompleted;

  void markSelected() => state = true;
}

final languageSelectedProvider =
    NotifierProvider<LanguageSelectionController, bool>(
      LanguageSelectionController.new,
    );

/// Whether the guest has finished (or moved past) the first-run onboarding
/// screen. Persisted through [AppPreferences], so once `true` a cold start goes
/// straight to the app instead of language → onboarding again.
class OnboardingController extends Notifier<bool> {
  @override
  bool build() => ref.read(appPreferencesProvider).onboardingCompleted;

  void complete() {
    if (state) return;
    state = true;
    unawaited(ref.read(appPreferencesProvider).setOnboardingCompleted());
  }
}

final onboardingCompletedProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);
