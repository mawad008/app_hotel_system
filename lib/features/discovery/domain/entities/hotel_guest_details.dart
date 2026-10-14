import 'package:flutter/foundation.dart';

import 'money.dart';

/// The Hotel Detail content the operator manages from the dashboard hotel
/// form (Figma `HOTEL_Detail_Premium`): check-in/out times, "suitable for",
/// total rooms, the "why choose" highlights and the location section.
///
/// Every field is optional — the detail screen hides a row or a whole
/// section that has no data, it never shows placeholder copy. Strings arrive
/// already resolved to the request locale by the backend (same convention as
/// `HotelReviewSummary`), so they are plain [String]s here.
@immutable
class HotelGuestDetails {
  const HotelGuestDetails({
    this.checkInTime,
    this.checkOutTime,
    this.pricesIncludeTaxes = false,
    this.serviceFee,
    this.taxRate,
    this.suitableFor,
    this.roomsCount,
    this.highlights = const <HotelHighlight>[],
    this.location,
  });

  /// `"HH:MM"` (24h) as stored by the backend; formatted for display by the UI.
  final String? checkInTime;
  final String? checkOutTime;

  /// The hotel says its displayed rates already include taxes (dashboard
  /// hotel form). Room Detail shows the "شاملة" row only when true.
  final bool pricesIncludeTaxes;

  /// The hotel's booking service fee ("رسوم الخدمة"); `null` when it charges
  /// none. Switched on/off and priced from the dashboard hotel form.
  final HotelServiceFee? serviceFee;

  /// The tax % ("نسبة الضريبة") added on top of the stay + service fee when
  /// the hotel's rates exclude taxes; `null` when none (or rates include it).
  final num? taxRate;
  final String? suitableFor;

  /// The tax on a stay priced [stayTotal] plus [serviceFee] — to the halala,
  /// truncated like the backend's `Reservation::taxAmount` (bcmath scale 2).
  /// `null` when the hotel adds no tax.
  Money? taxFor(Money stayTotal, {Money? serviceFee}) {
    final num? rate = taxRate;
    if (rate == null || rate <= 0) return null;
    final num base = stayTotal.amount + (serviceFee?.amount ?? 0);
    return Money(
      amount: (base * rate + 1e-9).floor() / 100,
      currency: stayTotal.currency,
    );
  }

  /// Physical rooms on file; `null` when not reported.
  final int? roomsCount;
  final List<HotelHighlight> highlights;
  final HotelLocation? location;

  @override
  bool operator ==(Object other) =>
      other is HotelGuestDetails &&
      other.checkInTime == checkInTime &&
      other.checkOutTime == checkOutTime &&
      other.pricesIncludeTaxes == pricesIncludeTaxes &&
      other.serviceFee == serviceFee &&
      other.taxRate == taxRate &&
      other.suitableFor == suitableFor &&
      other.roomsCount == roomsCount &&
      listEquals(other.highlights, highlights) &&
      other.location == location;

  @override
  int get hashCode => Object.hash(
    checkInTime,
    checkOutTime,
    pricesIncludeTaxes,
    serviceFee,
    taxRate,
    suitableFor,
    roomsCount,
    Object.hashAll(highlights),
    location,
  );
}

/// A hotel's booking service fee: a fixed amount per booking, or a
/// percentage of the stay price. The server snapshots the real amount on the
/// reservation; [feeFor] is the same arithmetic for the pre-booking display.
@immutable
class HotelServiceFee {
  const HotelServiceFee({required this.isPercentage, required this.value});

  final bool isPercentage;

  /// The fixed amount, or the percentage (0–100).
  final num value;

  /// The fee for a stay priced [stayTotal] — to the halala, truncated like
  /// the backend's `Hotel::serviceFeeFor` (bcmath scale 2).
  Money feeFor(Money stayTotal) {
    final num amount = isPercentage
        ? (stayTotal.amount * value + 1e-9).floor() / 100
        : value;
    return Money(amount: amount, currency: stayTotal.currency);
  }

  @override
  bool operator ==(Object other) =>
      other is HotelServiceFee &&
      other.isPercentage == isPercentage &&
      other.value == value;

  @override
  int get hashCode => Object.hash(isPercentage, value);
}

/// A "why choose this hotel" feature card.
@immutable
class HotelHighlight {
  const HotelHighlight({required this.title, this.subtitle, this.icon});

  final String title;
  final String? subtitle;

  /// Open icon key set by the operator (e.g. `waves`, `wifi`); unknown keys
  /// render a generic icon.
  final String? icon;

  @override
  bool operator ==(Object other) =>
      other is HotelHighlight &&
      other.title == title &&
      other.subtitle == subtitle &&
      other.icon == icon;

  @override
  int get hashCode => Object.hash(title, subtitle, icon);
}

/// The location section: a one-line note, the map pin and nearby places.
@immutable
class HotelLocation {
  const HotelLocation({
    this.note,
    this.latitude,
    this.longitude,
    this.nearbyPlaces = const <NearbyPlace>[],
  });

  final String? note;
  final double? latitude;
  final double? longitude;
  final List<NearbyPlace> nearbyPlaces;

  bool get hasCoordinates => latitude != null && longitude != null;

  /// Whether the section has anything real to show.
  bool get hasContent =>
      (note?.isNotEmpty ?? false) || hasCoordinates || nearbyPlaces.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is HotelLocation &&
      other.note == note &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      listEquals(other.nearbyPlaces, nearbyPlaces);

  @override
  int get hashCode =>
      Object.hash(note, latitude, longitude, Object.hashAll(nearbyPlaces));
}

/// A nearby place with its travel time ("مطار جدة · 25 دقيقة") or, when no
/// travel time is on file, its distance.
@immutable
class NearbyPlace {
  const NearbyPlace({
    required this.name,
    this.travelMinutes,
    this.icon,
    this.category,
    this.distance,
    this.distanceUnit,
    this.latitude,
    this.longitude,
  });

  final String name;
  final int? travelMinutes;
  final String? icon;

  /// Backend `NearbyPlaceCategory` wire value (`airport`, `beach`, …); the
  /// icon fallback when no [icon] key is set.
  final String? category;

  /// Distance in [distanceUnit]; both are null together.
  final double? distance;
  final DistanceUnit? distanceUnit;
  final double? latitude;
  final double? longitude;

  @override
  bool operator ==(Object other) =>
      other is NearbyPlace &&
      other.name == name &&
      other.travelMinutes == travelMinutes &&
      other.icon == icon &&
      other.category == category &&
      other.distance == distance &&
      other.distanceUnit == distanceUnit &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(
    name,
    travelMinutes,
    icon,
    category,
    distance,
    distanceUnit,
    latitude,
    longitude,
  );
}

/// Mirrors the backend `HotelNearbyPlace::DISTANCE_UNITS`.
enum DistanceUnit {
  meters('m'),
  kilometers('km');

  const DistanceUnit(this.wire);

  final String wire;

  static DistanceUnit? fromWire(Object? value) {
    for (final DistanceUnit u in values) {
      if (u.wire == value) return u;
    }
    return null;
  }
}
