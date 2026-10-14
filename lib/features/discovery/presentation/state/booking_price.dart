import 'package:flutter/foundation.dart';

import '../../domain/entities/money.dart';
import '../../domain/entities/room_selection.dart';

/// The price rows shown on the booking summary. Pure presentation arithmetic
/// over values the app already holds — the service fee and tax are the
/// hotel's own (`HotelServiceFee`, `HotelGuestDetails.taxRate`), the same
/// figures the server snapshots on booking.
@immutable
class BookingPriceBreakdown {
  const BookingPriceBreakdown({
    required this.roomSubtotal,
    required this.serviceFee,
    required this.total,
    this.tax,
    this.taxRate,
    this.loyaltyDiscount,
  });

  factory BookingPriceBreakdown.of(
    RoomSelection selection, {
    Money? serviceFee,
    Money? tax,
    num? taxRate,
    num loyaltyDiscount = 0,
  }) {
    final Money subtotal = selection.stayTotal;
    final num total = subtotal.amount +
        (serviceFee?.amount ?? 0) +
        (tax?.amount ?? 0) -
        loyaltyDiscount;
    return BookingPriceBreakdown(
      roomSubtotal: subtotal,
      serviceFee: serviceFee,
      tax: tax,
      taxRate: tax == null ? null : taxRate,
      loyaltyDiscount: loyaltyDiscount > 0
          ? Money(amount: loyaltyDiscount, currency: subtotal.currency)
          : null,
      total: Money(amount: total, currency: subtotal.currency),
    );
  }

  final Money roomSubtotal;
  final Money? serviceFee;

  /// The hotel's tax on stay + fee when its rates exclude taxes, and its %.
  final Money? tax;
  final num? taxRate;

  /// The estimated points discount (server decides the final credit).
  final Money? loyaltyDiscount;
  final Money total;
}
