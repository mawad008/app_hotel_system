import 'dart:async';

import 'package:flutter/widgets.dart';

/// Keeps a screen's server data current while the guest is looking at it.
///
/// Staff act on a booking from the dashboard (assign a room, check the guest
/// in, confirm a payment, approve an ID) and the app has no push channel, so a
/// screen fetched once would otherwise show the old state — and keep a CTA
/// disabled — until the app is restarted. [onRefresh] is called:
///
/// * when the app returns to the foreground, and
/// * every [interval] while this screen is the visible one — the top route,
///   in the active tab (hidden tabs and covered routes don't poll).
///
/// [onRefresh] should invalidate the screen's providers; Riverpod keeps the
/// previous value on screen while the refetch runs, so nothing flashes.
class LiveRefresh extends StatefulWidget {
  const LiveRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.interval = defaultInterval,
  });

  static const Duration defaultInterval = Duration(seconds: 15);

  final VoidCallback onRefresh;

  /// `null` refreshes on app resume only.
  final Duration? interval;
  final Widget child;

  @override
  State<LiveRefresh> createState() => _LiveRefreshState();
}

class _LiveRefreshState extends State<LiveRefresh> {
  late final AppLifecycleListener _lifecycle;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refreshIfVisible);
    _restartTimer();
  }

  @override
  void didUpdateWidget(LiveRefresh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interval != widget.interval) _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    final Duration? interval = widget.interval;
    _timer = interval == null
        ? null
        : Timer.periodic(interval, (_) => _refreshIfVisible());
  }

  void _refreshIfVisible() {
    if (!mounted) return;
    // Inactive shell tabs run with tickers disabled; covered routes aren't
    // current. Neither is on screen, so neither needs fresh data yet.
    if (!TickerMode.valuesOf(context).enabled) return;
    if (ModalRoute.of(context)?.isCurrent == false) return;
    widget.onRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
