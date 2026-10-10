import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../errors/error_mapper.dart';
import '../errors/failure_l10n.dart';
import '../localization/l10n.dart';
import '../theme/app_colors.dart';

/// Pull-down-to-refresh for a screen's server data.
///
/// Wrap a screen body; pulling down from the top runs [onRefresh], which
/// should invalidate the screen's providers and await their refetch (Riverpod
/// keeps the previous value on screen meanwhile, so nothing flashes). A failed
/// refresh shows the localized failure in a snackbar; the screen keeps
/// whatever its provider renders (screens use `skipError: true` so the last
/// good data stays).
///
/// Every vertical scrollable below is made always-scrollable, so the pull also
/// works on short lists and on the centred loading / empty / error views
/// (`MessageView`) — wrap them in [PullToRefreshFill] when they are not
/// scrollable at all. On web / desktop a mouse drag pulls too.
class PullToRefresh extends StatelessWidget {
  const PullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  Future<void> _run(BuildContext context) async {
    try {
      await onRefresh();
    } on Object catch (error) {
      if (!context.mounted) return;
      final String message = ErrorMapper.toFailure(error)
          .localizedMessage(context.l10n);
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ScrollBehavior inherited = ScrollConfiguration.of(context);
    return RefreshIndicator(
      color: context.colors.bgPrimary,
      backgroundColor: context.colors.bgSurface,
      onRefresh: () => _run(context),
      child: ScrollConfiguration(
        behavior: inherited.copyWith(
          physics: AlwaysScrollableScrollPhysics(
            parent: inherited.getScrollPhysics(context),
          ),
          dragDevices: <PointerDeviceKind>{
            ...inherited.dragDevices,
            if (kIsWeb) PointerDeviceKind.mouse,
          },
        ),
        child: child,
      ),
    );
  }
}

/// Makes a non-scrolling child (a centred loading / empty / error view)
/// fill the viewport inside a scrollable, so [PullToRefresh] can be pulled
/// from anywhere on it.
class PullToRefreshFill extends StatelessWidget {
  const PullToRefreshFill({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) =>
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: child,
            ),
          ),
    );
  }
}

/// Awaits several provider refetches together (e.g.
/// `refreshAll([ref.refresh(a.future), ref.refresh(b.future)])`), completing
/// once every one has settled; fails with the first error, if any.
Future<void> refreshAll(Iterable<Future<Object?>> refetches) =>
    Future.wait(refetches);
