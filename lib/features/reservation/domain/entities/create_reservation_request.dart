import 'package:flutter/foundation.dart';

import '../../../discovery/domain/entities/guest_party.dart';
import '../../../discovery/domain/entities/localized_text.dart';
import '../../../discovery/domain/entities/money.dart';
import '../../../discovery/domain/entities/room_selection.dart';
import '../../../discovery/domain/entities/stay_range.dart';

/// Everything the mobile app can supply to create a reservation.
///
/// The approved backend `POST /api/v1/reservations` (`StoreReservationRequest`)
/// takes `room_type_id`, `room_id?`, `guest_id`, `check_in`, `check_out` and
/// derives `hotel_id` / `status` / `price_snapshot` server-side. That endpoint
/// is currently **staff/dashboard-scoped** (it authorises against hotel access
/// and stamps `created_by_staff_id`); no guest-facing reservation contract is
/// approved yet, and the mobile auth layer does not expose a numeric
/// `guest_id`. So this request carries what the guest app actually knows:
///
/// * the chosen room **type** (string id from discovery) + optional physical
///   [roomId] (always `null` today — the backend allocates the room),
/// * the [stay] and [party],
/// * a [guestReference] standing in for `guest_id` until the contract lands
///   (the verified phone in E.164 form),
/// * a [priceSnapshot] captured at review time (nightly rate × nights — no
///   taxes/fees; the backend re-derives the authoritative snapshot),
/// * display-only [hotelName] / [roomName] so the success screen needs no extra
///   fetch.
@immutable
class CreateReservationRequest {
  const CreateReservationRequest({
    required this.hotelId,
    required this.hotelName,
    required this.roomTypeId,
    required this.roomName,
    required this.stay,
    required this.party,
    required this.guestReference,
    required this.priceSnapshot,
    this.roomId,
    this.attemptToken,
  });

  factory CreateReservationRequest.fromSelection(
    RoomSelection selection, {
    required String guestReference,
  }) {
    return CreateReservationRequest(
      hotelId: selection.hotelId,
      hotelName: selection.hotelName,
      roomTypeId: selection.roomTypeId,
      roomName: selection.roomType.name,
      stay: selection.stay,
      party: selection.party,
      guestReference: guestReference,
      priceSnapshot: selection.stayTotal,
      roomId: selection.roomId,
    );
  }

  final String hotelId;
  final LocalizedText hotelName;
  final String roomTypeId;
  final LocalizedText roomName;
  final StayRange stay;
  final GuestParty party;
  final String guestReference;
  final Money priceSnapshot;
  final String? roomId;

  /// One booking *attempt* (random, from [CreateReservationController]) —
  /// reused when the same Confirm is retried, renewed after a success. Not
  /// part of equality: it identifies the attempt, not the booking criteria.
  final String? attemptToken;

  /// The same request tagged with [token].
  CreateReservationRequest withAttempt(String token) => CreateReservationRequest(
        hotelId: hotelId,
        hotelName: hotelName,
        roomTypeId: roomTypeId,
        roomName: roomName,
        stay: stay,
        party: party,
        guestReference: guestReference,
        priceSnapshot: priceSnapshot,
        roomId: roomId,
        attemptToken: token,
      );

  /// The `Idempotency-Key` header the backend dedupes the create call on
  /// (`[A-Za-z0-9._:-]`, unique per guest). Per attempt — never the criteria
  /// alone, or re-booking the same dates after a cancelled / expired booking
  /// would replay the old one.
  String get serverIdempotencyKey => 'rsv-${attemptToken ?? _sanitized(idempotencyKey)}';

  static String _sanitized(String raw) => raw.replaceAll(RegExp(r'[^A-Za-z0-9._:-]'), '_');

  /// A stable idempotency key for this exact request — used to dedupe repeated
  /// submits and to derive the dummy confirmation code. No time component, no
  /// randomness.
  String get idempotencyKey => <String>[
        hotelId,
        roomTypeId,
        roomId ?? '-',
        stay.checkIn.toIso8601String(),
        stay.checkOut.toIso8601String(),
        '${party.adults}a${party.children}c',
        guestReference,
      ].join('|');

  @override
  bool operator ==(Object other) =>
      other is CreateReservationRequest &&
      other.idempotencyKey == idempotencyKey &&
      other.priceSnapshot == priceSnapshot;

  @override
  int get hashCode => Object.hash(idempotencyKey, priceSnapshot);

  @override
  String toString() => 'CreateReservationRequest($idempotencyKey)';
}
