import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../authentication/presentation/state/auth_controller.dart';
import '../../../authentication/presentation/state/auth_state.dart';
import '../../data/datasources/favorites/favorite_rooms_data_source.dart';
import '../../domain/entities/favorite_room.dart';
import 'favorite_hotels_controller.dart';

final _dummyFavoriteRoomsProvider = Provider<DummyFavoriteRoomsDataSource>(
  (Ref ref) => DummyFavoriteRoomsDataSource(),
);

final favoriteRoomsDataSourceProvider = Provider<FavoriteRoomsDataSource>((
  Ref ref,
) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? ref.watch(_dummyFavoriteRoomsProvider)
      : ApiFavoriteRoomsDataSource(ref.watch(apiClientProvider));
});

/// The guest's saved rooms, newest first — the backend's
/// `guest_favorite_room_types` is the source of truth. Same lifecycle as
/// [FavoriteHotelsController]: loaded for the signed-in guest, reloaded when
/// the session changes, optimistic toggles reverted on failure.
class FavoriteRoomsController extends Notifier<List<FavoriteRoom>> {
  /// Bumped on every heart tap so a slower initial load never overwrites a
  /// newer local write.
  int _writes = 0;

  /// Completes once the initial server fetch has settled (successfully or
  /// not), so the favourites list can tell "still loading" from "empty".
  Future<void> get loaded => _loaded;
  Future<void> _loaded = Future<void>.value();

  @override
  List<FavoriteRoom> build() {
    final AuthState auth = ref.watch(authControllerProvider);
    _loaded = Future<void>.value();
    if (auth is! Authenticated) return const <FavoriteRoom>[];
    _loaded = _load();
    return const <FavoriteRoom>[];
  }

  /// Pull-to-refresh: refetches from the server while the current list stays
  /// on screen (no empty flash). Signed-out guests have nothing to fetch.
  Future<void> reload() {
    if (ref.read(authControllerProvider) is! Authenticated) {
      return Future<void>.value();
    }
    return _loaded = _load();
  }

  Future<void> _load() async {
    final int writesAtStart = _writes;
    try {
      final List<FavoriteRoom> rooms = await ref
          .read(favoriteRoomsDataSourceProvider)
          .fetch();
      if (_writes == writesAtStart) state = rooms;
    } catch (_) {
      // Hearts simply render empty when the list can't be fetched; the next
      // tap writes to the server, which stays authoritative.
    }
  }

  bool isFavorite(String roomTypeId) =>
      state.any((FavoriteRoom r) => r.roomTypeId == roomTypeId);

  Future<FavoriteToggleOutcome> toggle(FavoriteRoom room) async {
    if (ref.read(authControllerProvider) is! Authenticated) {
      return FavoriteToggleOutcome.signInRequired;
    }
    _writes++;
    final List<FavoriteRoom> before = state;
    final bool removing = isFavorite(room.roomTypeId);
    state = removing
        ? <FavoriteRoom>[
            for (final FavoriteRoom r in before)
              if (r.roomTypeId != room.roomTypeId) r,
          ]
        : <FavoriteRoom>[room, ...before];
    try {
      final FavoriteRoomsDataSource source = ref.read(
        favoriteRoomsDataSourceProvider,
      );
      if (removing) {
        await source.remove(room.roomTypeId);
      } else {
        await source.add(room);
      }
      return removing
          ? FavoriteToggleOutcome.removed
          : FavoriteToggleOutcome.saved;
    } catch (error) {
      state = before;
      throw ErrorMapper.toFailure(error);
    }
  }
}

final favoriteRoomsProvider =
    NotifierProvider<FavoriteRoomsController, List<FavoriteRoom>>(
      FavoriteRoomsController.new,
    );
