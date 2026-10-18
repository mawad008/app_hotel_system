import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/loyalty/data/datasources/dummy_loyalty_data_source.dart';
import 'package:hotel_guest_app/features/loyalty/data/repositories/loyalty_repository_impl.dart';
import 'package:hotel_guest_app/features/loyalty/domain/entities/loyalty_operations.dart';
import 'package:hotel_guest_app/features/loyalty/presentation/state/loyalty_providers.dart';
import 'package:hotel_guest_app/features/loyalty/presentation/state/loyalty_redeem_controller.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/extend_stay.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';
import 'package:hotel_guest_app/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';

import 'loyalty_test_support.dart';

final DateTime _now = DateTime(2026, 9, 8, 11);

class _ReservationRepo implements ReservationRepository {
  _ReservationRepo(this.status, {this.amount = 900});
  final ReservationStatus status;
  final int amount;
  @override
  Future<Reservation> create(CreateReservationRequest request) async =>
      fakeReservation(status: status, amount: amount);
  @override
  Future<Reservation> getById(String id) async =>
      fakeReservation(id: id, status: status, amount: amount);
  @override
  Future<List<Reservation>> list() async => <Reservation>[];

  @override
  Future<Reservation> cancel(String id) async => fakeReservation(id: id);

  @override
  Future<ExtendStayResult> extend(ExtendStayRequest request) async {
    throw UnimplementedError('extend not used in this test');
  }
}

ProviderContainer _container({
  required ReservationStatus status,
  DummyLoyaltyDataSource? source,
  int amount = 900,
}) {
  final ds = source ?? DummyLoyaltyDataSource(clock: () => _now);
  final c = ProviderContainer(overrides: <Override>[
    loyaltyDataSourceProvider.overrideWithValue(ds),
    loyaltyRepositoryProvider.overrideWithValue(LoyaltyRepositoryImpl(ds)),
    reservationRepositoryProvider
        .overrideWithValue(_ReservationRepo(status, amount: amount)),
  ]);
  addTearDown(c.dispose);
  c.listen(loyaltyRedeemControllerProvider, (_, _) {});
  return c;
}

void main() {
  group('LoyaltyRedeemController', () {
    test('redeems against an eligible booking', () async {
      final id = redeemOkActiveId();
      final c = _container(status: ReservationStatus.checkedIn);
      await c.read(loyaltyRedeemControllerProvider.notifier).submit(id, 100);
      final state = c.read(loyaltyRedeemControllerProvider);
      expect(state, isA<RedeemDone>());
      expect(state.resultOrNull!.outcome, LoyaltyRedeemOutcome.redeemed);
    });

    test('an invalid amount is a blocked done', () async {
      final id = redeemOkActiveId();
      final c = _container(status: ReservationStatus.checkedIn);
      await c.read(loyaltyRedeemControllerProvider.notifier).submit(id, 0);
      expect(c.read(loyaltyRedeemControllerProvider).resultOrNull!.outcome,
          LoyaltyRedeemOutcome.invalidAmount);
    });

    test('a changed amount is a distinct request and is allowed through',
        () async {
      final id = redeemAlreadyActiveId();
      final c = _container(status: ReservationStatus.checkedIn);
      final n = c.read(loyaltyRedeemControllerProvider.notifier);
      await n.submit(id, 100);
      expect(c.read(loyaltyRedeemControllerProvider).resultOrNull!.outcome,
          LoyaltyRedeemOutcome.alreadyRedeemed);
      await n.submit(id, 150);
      expect(c.read(loyaltyRedeemControllerProvider).resultOrNull!.outcome,
          LoyaltyRedeemOutcome.alreadyRedeemedDifferent);
    });
  });
}
