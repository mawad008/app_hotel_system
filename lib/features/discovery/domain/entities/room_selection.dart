import 'package:flutter/foundation.dart';

import 'availability_request.dart';
import 'available_room.dart';
import 'guest_party.dart';
import 'localized_text.dart';
import 'money.dart';
import 'room_type_summary.dart';
import 'stay_range.dart';

/// A room the guest has chosen for a stay, ready to be handed to the future
/// Reservation phase.
///
/// This is deliberately **not** a reservation: nothing has been sent to the
/// backend, no hold is placed, no price is finalised. It captures exactly what
/// the Reservation phase will need to build its request:
///
/// * the hotel ([hotelId] + a display name snapshot),
/// * the room **type** ([roomType]) — the backend baseline requires
///   `room_type_id` and treats `room_id` as nullable, so [roomId] stays `null`
///   until the backend exposes physical-room allocation,
/// * the [stay] and [party],
/// * a [nightlyRate] price snapshot taken from the discovery model at selection
///   time (no taxes, fees or dynamic pricing — the approved baseline uses simple
///   pricing).
@immutable
class RoomSelection {
  const RoomSelection({
    required this.hotelId,
    required this.hotelName,
    required this.roomType,
    required this.stay,
    required this.party,
    required this.nightlyRate,
    this.roomId,
  });

  /// Builds a selection from a bookable [AvailableRoom] in an availability
  /// result. Throws nothing — callers must only offer selection for
  /// [AvailableRoom.isAvailable] rooms.
  factory RoomSelection.fromAvailableRoom({
    required AvailableRoom room,
    required String hotelId,
    required LocalizedText hotelName,
    required StayRange stay,
    required GuestParty party,
  }) {
    return RoomSelection(
      hotelId: hotelId,
      hotelName: hotelName,
      roomType: room.roomType,
      stay: stay,
      party: party,
      nightlyRate: room.roomType.nightlyRate,
    );
  }

  final String hotelId;
  final LocalizedText hotelName;
  final RoomTypeSummary roomType;
  final StayRange stay;
  final GuestParty party;

  /// Price per night captured when the room was selected. Integer currency
  /// units — no floating-point money.
  final Money nightlyRate;

  /// A specific physical room. Always `null` in the current backend phase; the
  /// field exists so the Reservation phase can carry it once the backend
  /// assigns one.
  final String? roomId;

  String get roomTypeId => roomType.id;

  int get nights => stay.nights;

  /// Simple stay total: nightly rate × nights. No taxes or fees.
  Money get stayTotal => nightlyRate * stay.nights;

  /// Whether this selection still corresponds to [request] — same hotel, stay
  /// and party. Used to drop a stale selection when the guest changes criteria.
  bool matches(AvailabilityRequest request) =>
      request.hotelId == hotelId &&
      request.stay == stay &&
      request.party == party;

  RoomSelection copyWith({String? roomId, GuestParty? party}) => RoomSelection(
    hotelId: hotelId,
    hotelName: hotelName,
    roomType: roomType,
    stay: stay,
    party: party ?? this.party,
    nightlyRate: nightlyRate,
    roomId: roomId ?? this.roomId,
  );

  /// Whether [party] can be booked into this room type (occupancy check only —
  /// Laravel stays authoritative).
  bool fits(GuestParty party) => party.fitsIn(roomType.maxOccupancy);

  /// The most adults this room type takes alongside [children] — the stepper
  /// ceiling on the booking summary, so the party can't outgrow the room.
  int maxAdultsWith(int children) => (roomType.maxOccupancy - children).clamp(
    GuestParty.minAdults,
    GuestParty.maxAdults,
  );

  /// The most children this room type takes alongside [adults].
  int maxChildrenWith(int adults) => (roomType.maxOccupancy - adults).clamp(
    GuestParty.minChildren,
    GuestParty.maxChildren,
  );

  @override
  bool operator ==(Object other) =>
      other is RoomSelection &&
      other.hotelId == hotelId &&
      other.hotelName == hotelName &&
      other.roomType == roomType &&
      other.stay == stay &&
      other.party == party &&
      other.nightlyRate == nightlyRate &&
      other.roomId == roomId;

  @override
  int get hashCode => Object.hash(
    hotelId,
    hotelName,
    roomType,
    stay,
    party,
    nightlyRate,
    roomId,
  );

  @override
  String toString() =>
      'RoomSelection($hotelId / ${roomType.id}, $stay, ${party.adults}+${party.children})';
}
