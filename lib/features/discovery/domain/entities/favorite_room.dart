import 'package:flutter/foundation.dart';

import 'localized_text.dart';

/// A room (room type) the guest saved with the Room Detail heart. Carries
/// just enough to list it without an availability search; price and
/// availability for a stay always come from the availability endpoint.
@immutable
class FavoriteRoom {
  const FavoriteRoom({
    required this.roomTypeId,
    required this.hotelId,
    required this.name,
    this.coverUrl,
  });

  final String roomTypeId;
  final String hotelId;
  final LocalizedText name;

  /// The room type's first gallery photo; `null` when it has none on file.
  final String? coverUrl;

  @override
  bool operator ==(Object other) =>
      other is FavoriteRoom &&
      other.roomTypeId == roomTypeId &&
      other.hotelId == hotelId &&
      other.name == name &&
      other.coverUrl == coverUrl;

  @override
  int get hashCode => Object.hash(roomTypeId, hotelId, name, coverUrl);
}
