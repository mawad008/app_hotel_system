import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/time/clock.dart';
import '../../data/datasources/api_profile_data_source.dart';
import '../../data/datasources/dummy_profile_data_source.dart';
import '../../data/datasources/profile_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/guest_preferences.dart';
import '../../domain/repositories/profile_repository.dart';

final _dummyProfileProvider = Provider<DummyProfileDataSource>(
  (Ref ref) => DummyProfileDataSource(clock: ref.watch(clockProvider)),
);

final profileDataSourceProvider = Provider<ProfileDataSource>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? ref.watch(_dummyProfileProvider)
      : ApiProfileDataSource(ref.watch(apiClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>(
  (Ref ref) => ProfileRepositoryImpl(ref.watch(profileDataSourceProvider)),
);

/// The guest's server-side preferences + privacy state. Writes go through
/// [GuestAccountSettingsController] so the screen shows the server's answer.
final guestAccountSettingsProvider =
    AsyncNotifierProvider.autoDispose<GuestAccountSettingsController, GuestAccountSettings>(
  GuestAccountSettingsController.new,
);

class GuestAccountSettingsController extends AsyncNotifier<GuestAccountSettings> {
  @override
  Future<GuestAccountSettings> build() => ref.watch(profileRepositoryProvider).settings();

  /// Saves and adopts the server's stored preferences. Throws the `Failure`
  /// so the screen can say why; the previous value stays shown.
  Future<void> savePreferences(GuestPreferences preferences) async {
    final GuestAccountSettings saved =
        await ref.read(profileRepositoryProvider).savePreferences(preferences);
    state = AsyncData<GuestAccountSettings>(saved);
  }

  Future<void> setIdentityRetention({required bool keepForFuture}) async {
    final GuestAccountSettings saved = await ref
        .read(profileRepositoryProvider)
        .setIdentityRetention(keepForFuture: keepForFuture);
    state = AsyncData<GuestAccountSettings>(saved);
  }

  Future<void> requestDataDeletion() async {
    final GuestAccountSettings saved =
        await ref.read(profileRepositoryProvider).requestDataDeletion();
    state = AsyncData<GuestAccountSettings>(saved);
  }
}
