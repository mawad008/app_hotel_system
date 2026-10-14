import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/time/clock.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/bottom_action_bar.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../../core/widgets/pull_to_refresh.dart';
import '../../domain/entities/guest_notification.dart';
import '../state/notifications_providers.dart';
import '../../../../core/localization/numerals.dart';

/// `NOTIFICATIONS_List` (`12 · Notifications & profile`): the guest's in-app
/// feed from the backend, grouped today / yesterday / earlier, an info banner
/// with the unread count, and "تعليم الكل كمقروء". Each row opens its own
/// context (the Figma routing map) and is marked read on the server.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<NotificationFeed> feed = ref.watch(
      notificationFeedProvider,
    );

    return Scaffold(
      appBar: HotelAppBar(title: l10n.notificationsTitle),
      body: SafeArea(
        child: PullToRefresh(
          onRefresh: () => ref.refresh(notificationFeedProvider.future),
          child: feed.when(
            // A failed refresh keeps the last good data on screen.
            skipError: true,
            loading: () =>
                Center(child: LoadingView(label: l10n.stateLoadingTitle)),
            error: (Object e, StackTrace _) => MessageView(
              icon: AppIcons.notifications,
              title: l10n.stateErrorTitle,
              message: ErrorMapper.toFailure(e).localizedMessage(l10n),
              actionLabel: l10n.actionRetry,
              onAction: () => ref.invalidate(notificationFeedProvider),
            ),
            data: (NotificationFeed data) => data.items.isEmpty
                ? MessageView(
                    icon: AppIcons.notifications,
                    title: l10n.notificationsEmptyTitle,
                    message: l10n.notificationsEmptyBody,
                  )
                : _Feed(feed: data),
          ),
        ),
      ),
      bottomNavigationBar: switch (feed) {
        AsyncData<NotificationFeed>(:final NotificationFeed value)
            when value.items.isNotEmpty =>
          _MarkAllReadBar(enabled: value.unreadCount > 0),
        _ => null,
      },
    );
  }
}

class _Feed extends ConsumerWidget {
  const _Feed({required this.feed});

  final NotificationFeed feed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final DateTime now = ref.read(clockProvider)();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));

    final List<GuestNotification> todayItems = <GuestNotification>[];
    final List<GuestNotification> yesterdayItems = <GuestNotification>[];
    final List<GuestNotification> earlier = <GuestNotification>[];
    for (final GuestNotification n in feed.items) {
      final DateTime day = DateTime(
        n.createdAt.year,
        n.createdAt.month,
        n.createdAt.day,
      );
      if (!day.isBefore(today)) {
        todayItems.add(n);
      } else if (!day.isBefore(yesterday)) {
        yesterdayItems.add(n);
      } else {
        earlier.add(n);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        InfoBanner(
          tone: InfoBannerTone.info,
          title: feed.unreadCount > 0
              ? l10n.notificationsUnreadTitle(feed.unreadCount)
              : l10n.notificationsAllReadTitle,
          message: l10n.notificationsBannerBody,
        ),
        for (final List<GuestNotification> group in <List<GuestNotification>>[
          todayItems,
          yesterdayItems,
          earlier,
        ])
          if (group.isNotEmpty) ...<Widget>[
            const SizedBox(height: 18),
            SettingsCard(
              borderWidth: 1,
              children: <Widget>[
                for (final GuestNotification n in group)
                  _NotificationRow(
                    notification: n,
                    now: now,
                    yesterday: yesterday,
                  ),
              ],
            ),
          ],
      ],
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({
    required this.notification,
    required this.now,
    required this.yesterday,
  });

  final GuestNotification notification;
  final DateTime now;
  final DateTime yesterday;

  String _when(BuildContext context, AppLocalizations l10n) {
    final DateTime at = notification.createdAt;
    if (now.difference(at) < const Duration(minutes: 1))
      return l10n.notificationsNow;
    final DateTime day = DateTime(at.year, at.month, at.day);
    final MaterialLocalizations ml = MaterialLocalizations.of(context);
    if (day == DateTime(now.year, now.month, now.day)) {
      return context.localDigits(
        ml.formatTimeOfDay(TimeOfDay.fromDateTime(at)),
      );
    }
    if (day == yesterday) return l10n.notificationsYesterday;
    return ml.formatShortMonthDay(at);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    return Semantics(
      label: notification.isRead ? null : l10n.notificationsUnreadLabel,
      child: SettingsRow(
        icon: AppIcons.notifications,
        label: notification.subject,
        value: _when(context, l10n),
        onTap: () => _open(context, ref),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final String? reservationId = notification.reservationId;
    final GoRouter router = GoRouter.of(context);
    if (!notification.isRead) {
      try {
        await ref
            .read(notificationsRepositoryProvider)
            .markRead(notification.id);
      } on Failure {
        // The row simply stays unread — the feed below is re-read from the
        // server, which stays authoritative. Opening the context must not
        // depend on the read receipt.
      }
      ref.invalidate(notificationFeedProvider);
    }
    if (reservationId == null) return;
    final Map<String, String> params = <String, String>{
      'reservationId': reservationId,
    };
    switch (notification.type) {
      case GuestNotificationType.identityVerified:
        router.pushNamed(
          AppRoutes.identityVerificationResultName,
          pathParameters: params,
        );
      case GuestNotificationType.checkedIn:
        router.pushNamed(AppRoutes.digitalAccessName, pathParameters: params);
      case GuestNotificationType.invoiced:
        router.pushNamed(AppRoutes.invoiceName, pathParameters: params);
      case GuestNotificationType.depositHeld:
      case GuestNotificationType.cancelled:
      case GuestNotificationType.unknown:
        router.pushNamed(
          AppRoutes.reservationDetailName,
          pathParameters: params,
        );
    }
  }
}

class _MarkAllReadBar extends ConsumerStatefulWidget {
  const _MarkAllReadBar({required this.enabled});

  final bool enabled;

  @override
  ConsumerState<_MarkAllReadBar> createState() => _MarkAllReadBarState();
}

class _MarkAllReadBarState extends ConsumerState<_MarkAllReadBar> {
  bool _busy = false;

  Future<void> _markAll() async {
    final AppLocalizations l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
      ref.invalidate(notificationFeedProvider);
    } on Failure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(failure.localizedMessage(l10n))),
          );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomActionBar.actions(
      primary: PrimaryButton(
        label: context.l10n.notificationsMarkAllRead,
        isLoading: _busy,
        onPressed: widget.enabled && !_busy ? _markAll : null,
      ),
    );
  }
}
