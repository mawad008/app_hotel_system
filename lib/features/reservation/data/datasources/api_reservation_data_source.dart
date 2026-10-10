import '../../../../core/data/data_source.dart';
import '../../../../core/network/api_client.dart';
import '../../../discovery/domain/entities/guest_party.dart';
import '../../../discovery/domain/entities/localized_text.dart';
import '../../domain/entities/create_reservation_request.dart';
import '../../domain/entities/extend_stay.dart';
import '../models/reservation_models.dart';
import 'reservation_data_source.dart';

/// API-backed reservation source.
///
/// Guest reservations are a real, authenticated contract:
/// `POST /guest/reservations` (`StoreGuestReservationRequest`: `room_type_id`,
/// `check_in`, `check_out`, `adults`, `children` — `guest_id` is taken from
/// the `auth:guest` token, never the body) and
/// `GET /guest/reservations/{reservation}` → `GuestReservationResource`. Both
/// resolve ownership server-side; a non-owned or missing id is a plain 404.
class ApiReservationDataSource
    implements ReservationDataSource, RemoteDataSource {
  ApiReservationDataSource(this._client);

  final ApiClient _client;

  @override
  Future<ReservationModel> create(CreateReservationRequest request) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/guest/reservations',
      body: <String, Object?>{
        'room_type_id': int.tryParse(request.roomTypeId) ?? request.roomTypeId,
        'check_in': _isoDate(request.stay.checkIn),
        'check_out': _isoDate(request.stay.checkOut),
        'adults': request.party.adults,
        'children': request.party.children,
      },
      headers: <String, String>{'Idempotency-Key': request.serverIdempotencyKey},
    );
    return _parse(
      json,
      hotelName: request.hotelName,
      roomName: request.roomName,
      party: request.party,
    );
  }

  @override
  Future<List<ReservationModel>> fetchList() async {
    final Map<String, dynamic> json = await _client.getJson('/guest/reservations');
    final List<Object?> rows = (json['data'] as List<Object?>?) ?? const <Object?>[];
    return rows.whereType<Map<String, Object?>>().map((Map<String, Object?> row) {
      final Map<String, Object?>? hotel = row['hotel'] as Map<String, Object?>?;
      final Map<String, Object?>? roomType = row['room_type'] as Map<String, Object?>?;
      return ReservationModel.fromJson(
        row,
        hotelName: hotel == null
            ? const LocalizedText(ar: '', en: '')
            : _text(hotel['name']),
        roomName: roomType == null
            ? const LocalizedText(ar: '', en: '')
            : _text(roomType['name']),
        party: GuestParty(
          adults: (row['adults'] as num?)?.toInt() ?? 1,
          children: (row['children'] as num?)?.toInt() ?? 0,
        ),
      );
    }).toList(growable: false);
  }

  @override
  Future<ReservationModel> cancel(String id) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/guest/reservations/$id/cancel',
    );
    final Map<String, Object?> data =
        (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
    final Map<String, Object?>? hotel = data['hotel'] as Map<String, Object?>?;
    final Map<String, Object?>? roomType = data['room_type'] as Map<String, Object?>?;
    return _parse(
      json,
      hotelName: hotel == null
          ? const LocalizedText(ar: '', en: '')
          : _text(hotel['name']),
      roomName: roomType == null
          ? const LocalizedText(ar: '', en: '')
          : _text(roomType['name']),
      party: GuestParty(
        adults: (data['adults'] as num?)?.toInt() ?? 1,
        children: (data['children'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  @override
  Future<ExtendStayResultModel> extend(ExtendStayRequest request) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/guest/reservations/${request.reservationId}/extend',
      body: <String, Object?>{'new_check_out': _isoDate(request.newCheckOut)},
      headers: <String, String>{'Idempotency-Key': request.idempotencyKey},
    );
    final Map<String, Object?> data =
        (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
    return ExtendStayResultModel.fromJson(data);
  }

  @override
  Future<ReservationModel> fetchById(String id) async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/reservations/$id',
    );
    final Map<String, Object?> data =
        (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
    final Map<String, Object?>? hotel = data['hotel'] as Map<String, Object?>?;
    final Map<String, Object?>? roomType =
        data['room_type'] as Map<String, Object?>?;
    return _parse(
      json,
      hotelName: hotel == null
          ? const LocalizedText(ar: '', en: '')
          : _text(hotel['name']),
      roomName: roomType == null
          ? const LocalizedText(ar: '', en: '')
          : _text(roomType['name']),
      party: GuestParty(
        adults: (data['adults'] as num?)?.toInt() ?? 1,
        children: (data['children'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  ReservationModel _parse(
    Map<String, dynamic> json, {
    required LocalizedText hotelName,
    required LocalizedText roomName,
    required GuestParty party,
  }) {
    final Map<String, Object?> data =
        (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
    return ReservationModel.fromJson(
      data,
      hotelName: hotelName,
      roomName: roomName,
      party: party,
    );
  }

  static LocalizedText _text(Object? raw) {
    if (raw is String) return LocalizedText(ar: raw, en: raw);
    return const LocalizedText(ar: '', en: '');
  }

  static String _isoDate(DateTime date) {
    final DateTime d = DateTime(date.year, date.month, date.day);
    final String y = d.year.toString().padLeft(4, '0');
    final String m = d.month.toString().padLeft(2, '0');
    final String dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }
}
