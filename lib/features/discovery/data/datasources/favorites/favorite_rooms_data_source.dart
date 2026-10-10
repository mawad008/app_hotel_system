import '../../../../../core/data/data_source.dart';
import '../../../../../core/network/api_client.dart';
import '../../../domain/entities/favorite_room.dart';
import '../../../domain/entities/localized_text.dart';

/// The signed-in guest's saved rooms (the Room Detail heart), newest first.
abstract interface class FavoriteRoomsDataSource {
  Future<List<FavoriteRoom>> fetch();

  Future<void> add(FavoriteRoom room);

  Future<void> remove(String roomTypeId);
}

/// `auth:guest` — `GET /guest/favorites/rooms`,
/// `PUT|DELETE /guest/favorites/rooms/{roomType}` (idempotent).
class ApiFavoriteRoomsDataSource implements FavoriteRoomsDataSource, RemoteDataSource {
  ApiFavoriteRoomsDataSource(this._client);

  final ApiClient _client;

  @override
  Future<List<FavoriteRoom>> fetch() async {
    final Map<String, dynamic> json = await _client.getJson('/guest/favorites/rooms');
    final List<Object?> rows = (json['data'] as List<Object?>?) ?? const <Object?>[];
    return <FavoriteRoom>[
      for (final Object? row in rows)
        if (row is Map<String, Object?> &&
            row['room_type_id'] != null &&
            row['hotel_id'] != null)
          FavoriteRoom(
            roomTypeId: '${row['room_type_id']}',
            hotelId: '${row['hotel_id']}',
            name: LocalizedText(
              ar: '${row['name'] ?? ''}',
              en: '${row['name'] ?? ''}',
            ),
            coverUrl: row['cover_url'] as String?,
          ),
    ];
  }

  @override
  Future<void> add(FavoriteRoom room) =>
      _client.putJson('/guest/favorites/rooms/${room.roomTypeId}');

  @override
  Future<void> remove(String roomTypeId) =>
      _client.deleteJson('/guest/favorites/rooms/$roomTypeId');
}

/// Offline/demo favourites kept for the session.
class DummyFavoriteRoomsDataSource implements FavoriteRoomsDataSource, DummyDataSource {
  final List<FavoriteRoom> _rooms = <FavoriteRoom>[];

  @override
  Future<List<FavoriteRoom>> fetch() async => List<FavoriteRoom>.of(_rooms);

  @override
  Future<void> add(FavoriteRoom room) async {
    if (_rooms.any((FavoriteRoom r) => r.roomTypeId == room.roomTypeId)) return;
    _rooms.insert(0, room);
  }

  @override
  Future<void> remove(String roomTypeId) async =>
      _rooms.removeWhere((FavoriteRoom r) => r.roomTypeId == roomTypeId);
}
