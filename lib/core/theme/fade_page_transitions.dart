import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The app's default page transition: the incoming page fades in over the
/// current one (and fades out again on back), on every platform.
///
/// On iOS the edge swipe-back gesture is kept: Cupertino's gesture detector is
/// reused with its slide neutralised, so the drag fades the page out under
/// the finger instead of sliding it. Registered for all platforms through
/// [AppTheme]'s `pageTransitionsTheme`, so every route — `GoRoute` builders
/// included — uses it without per-route code.
class FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadePageTransitionsBuilder();

  static final Animatable<double> _fadeIn = CurveTween(curve: Curves.easeOut);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 260);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 220);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    Widget page = child;
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      // Constant animations: no slide, no parallax — only the back-swipe
      // detector, which drives this route's real animation (and so the fade).
      page = CupertinoRouteTransitionMixin.buildPageTransitions<T>(
        route,
        context,
        kAlwaysCompleteAnimation,
        kAlwaysDismissedAnimation,
        child,
      );
    }
    return FadeTransition(
      // Linear while a back swipe is in progress, so the fade tracks the
      // finger exactly.
      opacity: route.popGestureInProgress ? animation : animation.drive(_fadeIn),
      child: page,
    );
  }
}
