import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/localization/content_language_provider.dart';
import '../../../../core/time/clock.dart';
import '../../../authentication/presentation/state/auth_controller.dart';
import '../../../authentication/presentation/state/auth_state.dart';
import '../../data/datasources/api_notifications_data_source.dart';
import '../../data/datasources/dummy_notifications_data_source.dart';
import '../../data/datasources/notifications_data_source.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/guest_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

/// One dummy instance keeps read state for the session.
final _dummyNotificationsProvider = Provider<DummyNotificationsDataSource>(
  (Ref ref) => DummyNotificationsDataSource(clock: ref.watch(clockProvider)),
);

final notificationsDataSourceProvider = Provider<NotificationsDataSource>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? ref.watch(_dummyNotificationsProvider)
      : ApiNotificationsDataSource(ref.watch(apiClientProvider));
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (Ref ref) => NotificationsRepositoryImpl(ref.watch(notificationsDataSourceProvider)),
);

/// The signed-in guest's feed. A signed-out guest has no feed (empty, no
/// request). Re-fetched in the new language after a language switch (the
/// backend localizes the copy), and whenever the session changes.
final notificationFeedProvider = FutureProvider.autoDispose<NotificationFeed>((Ref ref) {
  ref.watch(contentLanguageProvider);
  final AuthState auth = ref.watch(authControllerProvider);
  if (auth is! Authenticated) return NotificationFeed.empty;
  return ref.watch(notificationsRepositoryProvider).feed();
});

/// Bell badge count — 0 while loading / signed out / on error.
final unreadNotificationsCountProvider = Provider.autoDispose<int>(
  (Ref ref) => ref.watch(notificationFeedProvider).value?.unreadCount ?? 0,
);
