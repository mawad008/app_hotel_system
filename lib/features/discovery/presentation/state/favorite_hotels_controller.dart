import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../authentication/presentation/state/auth_controller.dart';
import '../../../authentication/presentation/state/auth_state.dart';
import '../../data/datasources/favorites/favorite_hotels_data_source.dart';

final _dummyFavoritesProvider =
    Provider<DummyFavoriteHotelsDataSource>((Ref ref) => DummyFavoriteHotelsDataSource());

final favoriteHotelsDataSourceProvider = Provider<FavoriteHotelsDataSource>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? ref.watch(_dummyFavoritesProvider)
      : ApiFavoriteHotelsDataSource(ref.watch(apiClientProvider));
});

/// What a heart tap did.
enum FavoriteToggleOutcome { saved, removed, signInRequired }

/// The guest's favourite hotel ids — the backend's
/// `guest_favorite_hotels` is the source of truth. Loaded for the signed-in
/// guest (empty when signed out) and reloaded whenever the session changes.
/// A tap updates optimistically, then reconciles: a failed write is reverted
/// and rethrown as a `Failure` for the UI to report.
class FavoriteHotelsController extends Notifier<Set<String>> {
  /// Bumped on every heart tap so a slower initial load never overwrites a
  /// newer local write.
  int _writes = 0;

  /// Completes once the initial server fetch has settled (successfully or
  /// not), so the favourites list can tell "still loading" from "empty".
  Future<void> get loaded => _loaded;
  Future<void> _loaded = Future<void>.value();

  @override
  Set<String> build() {
    final AuthState auth = ref.watch(authControllerProvider);
    _loaded = Future<void>.value();
    if (auth is! Authenticated) return const <String>{};
    _loaded = _load();
    return const <String>{};
  }

  Future<void> _load() async {
    final int writesAtStart = _writes;
    try {
      final Set<String> ids = await ref.read(favoriteHotelsDataSourceProvider).fetchIds();
      if (_writes == writesAtStart) state = ids;
    } catch (_) {
      // Hearts simply render empty when the list can't be fetched; the next
      // tap writes to the server, which stays authoritative.
    }
  }

  bool isFavorite(String hotelId) => state.contains(hotelId);

  Future<FavoriteToggleOutcome> toggle(String hotelId) async {
    if (ref.read(authControllerProvider) is! Authenticated) {
      return FavoriteToggleOutcome.signInRequired;
    }
    _writes++;
    final Set<String> before = state;
    final bool removing = before.contains(hotelId);
    state = removing
        ? (Set<String>.of(before)..remove(hotelId))
        : <String>{...before, hotelId};
    try {
      final FavoriteHotelsDataSource source = ref.read(favoriteHotelsDataSourceProvider);
      if (removing) {
        await source.remove(hotelId);
      } else {
        await source.add(hotelId);
      }
      return removing ? FavoriteToggleOutcome.removed : FavoriteToggleOutcome.saved;
    } catch (error) {
      state = before;
      throw ErrorMapper.toFailure(error);
    }
  }
}

final favoriteHotelsProvider =
    NotifierProvider<FavoriteHotelsController, Set<String>>(
      FavoriteHotelsController.new,
    );
