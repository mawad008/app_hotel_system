import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pops when there is a page underneath, otherwise goes to [fallback].
///
/// A screen reached with `context.go` (e.g. the booking summary the guest is
/// returned to after signing in) is the only page on the stack, so a plain
/// `pop` has nowhere to go.
void popOr(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

/// Routes the system / browser back gesture to [fallback] when the screen is
/// the only page on the stack, instead of leaving the app. Pair it with
/// `HotelAppBar(fallbackLocation: …)` for the on-screen back button.
class BackFallbackScope extends StatelessWidget {
  const BackFallbackScope({
    super.key,
    required this.fallback,
    required this.child,
  });

  final String fallback;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) context.go(fallback);
      },
      child: child,
    );
  }
}
