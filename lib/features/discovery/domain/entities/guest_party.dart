import 'package:flutter/foundation.dart';

/// The number of guests for a stay (`16 · Stay dates & available rooms`, the
/// "عدد الضيوف" sheet). The reference's initial state is two adults, no children.
@immutable
class GuestParty {
  const GuestParty({required this.adults, required this.children});

  final int adults;
  final int children;

  /// Figma default: 2 adults, 0 children.
  static const GuestParty initial = GuestParty(adults: 2, children: 0);

  /// UI-only guard rails so the steppers cannot produce a nonsensical party.
  /// The design shows steppers with no explicit ceiling; 10 of each keeps the
  /// control sane without inventing an occupancy policy.
  static const int minAdults = 1;
  static const int maxAdults = 10;
  static const int minChildren = 0;
  static const int maxChildren = 10;

  int get total => adults + children;

  /// Whether this party fits a room type seating at most [maxOccupancy] guests
  /// (adults and children both count — mirrors Laravel's `room_types.capacity`).
  bool fitsIn(int maxOccupancy) => total <= maxOccupancy;

  GuestParty copyWith({int? adults, int? children}) => GuestParty(
    adults: (adults ?? this.adults).clamp(minAdults, maxAdults),
    children: (children ?? this.children).clamp(minChildren, maxChildren),
  );

  @override
  bool operator ==(Object other) =>
      other is GuestParty &&
      other.adults == adults &&
      other.children == children;

  @override
  int get hashCode => Object.hash(adults, children);

  @override
  String toString() => 'GuestParty(adults: $adults, children: $children)';
}
