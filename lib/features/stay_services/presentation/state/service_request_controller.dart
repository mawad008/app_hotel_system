import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../../checkout/presentation/state/checkout_providers.dart';
import '../../domain/entities/service_order.dart';
import 'stay_services_providers.dart';

/// The state of the one-shot "request this service" action.
sealed class ServiceRequestState {
  const ServiceRequestState();

  bool get isSubmitting => this is ServiceRequestSubmitting;

  CreateServiceRequest? get requestOrNull => switch (this) {
        ServiceRequestSubmitting(:final CreateServiceRequest request) => request,
        ServiceRequestDone(:final CreateServiceRequest request) => request,
        ServiceRequestFailed(:final CreateServiceRequest request) => request,
        _ => null,
      };

  ServiceOrder? get orderOrNull =>
      this is ServiceRequestDone ? (this as ServiceRequestDone).order : null;

  Failure? get failureOrNull => this is ServiceRequestFailed
      ? (this as ServiceRequestFailed).failure
      : null;
}

class ServiceRequestIdle extends ServiceRequestState {
  const ServiceRequestIdle();
}

class ServiceRequestSubmitting extends ServiceRequestState {
  const ServiceRequestSubmitting(this.request);
  final CreateServiceRequest request;
}

/// The order was created (`requested`). Terminal for this request — a repeat is
/// ignored so the same service is never double-ordered from one screen.
class ServiceRequestDone extends ServiceRequestState {
  const ServiceRequestDone(this.request, this.order);
  final CreateServiceRequest request;
  final ServiceOrder order;
}

class ServiceRequestFailed extends ServiceRequestState {
  const ServiceRequestFailed(this.request, this.failure);
  final CreateServiceRequest request;
  final Failure failure;
}

/// Owns the request-a-service action.
///
/// Guarantees mirror the other workflow controllers: duplicate-submit is a
/// no-op while submitting or after done for the same request; retry is allowed
/// from failed; a stale async result is dropped when a newer request
/// superseded it; the underlying dummy source is idempotent per request.
class ServiceRequestController extends Notifier<ServiceRequestState> {
  @override
  ServiceRequestState build() => const ServiceRequestIdle();

  Future<void> submit(CreateServiceRequest request) async {
    final ServiceRequestState current = state;
    if (current is ServiceRequestSubmitting && current.request == request) {
      return;
    }
    if (current is ServiceRequestDone && current.request == request) return;

    state = ServiceRequestSubmitting(request);
    try {
      final ServiceOrder order = await ref
          .read(stayServicesRepositoryProvider)
          .requestService(request);
      if (_superseded(request)) return;
      state = ServiceRequestDone(request, order);
      ref.invalidate(serviceOrdersProvider(request.reservationId));
      // A chargeable order posts to the stay's folio.
      ref.invalidate(folioProvider(request.reservationId));
    } catch (error) {
      if (_superseded(request)) return;
      state = ServiceRequestFailed(request, ErrorMapper.toFailure(error));
    }
  }

  bool _superseded(CreateServiceRequest request) {
    final ServiceRequestState now = state;
    return now is ServiceRequestSubmitting && now.request != request;
  }

  void reset() => state = const ServiceRequestIdle();
}

final serviceRequestControllerProvider =
    NotifierProvider<ServiceRequestController, ServiceRequestState>(
  ServiceRequestController.new,
);

/// The state of cancelling one specific order — a `.family` per order so two
/// orders' cancellations never share state and a late result can't cross over.
sealed class CancelOrderState {
  const CancelOrderState();
  bool get isSubmitting => this is CancelOrderSubmitting;
  Failure? get failureOrNull =>
      this is CancelOrderFailed ? (this as CancelOrderFailed).failure : null;
}

class CancelOrderIdle extends CancelOrderState {
  const CancelOrderIdle();
}

class CancelOrderSubmitting extends CancelOrderState {
  const CancelOrderSubmitting();
}

class CancelOrderDone extends CancelOrderState {
  const CancelOrderDone(this.order);
  final ServiceOrder order;
}

class CancelOrderFailed extends CancelOrderState {
  const CancelOrderFailed(this.failure);
  final Failure failure;
}

class CancelOrderController extends Notifier<CancelOrderState> {
  CancelOrderController(this._key);

  final ServiceOrderKey _key;

  @override
  CancelOrderState build() {
    return const CancelOrderIdle();
  }

  Future<void> cancel() async {
    if (state is CancelOrderSubmitting) return;
    state = const CancelOrderSubmitting();
    try {
      final ServiceOrder order = await ref
          .read(stayServicesRepositoryProvider)
          .cancelOrder(_key.reservationId, _key.orderId);
      state = CancelOrderDone(order);
      ref.invalidate(serviceOrdersProvider(_key.reservationId));
      ref.invalidate(serviceOrderProvider(_key));
      ref.invalidate(folioProvider(_key.reservationId));
    } catch (error) {
      state = CancelOrderFailed(ErrorMapper.toFailure(error));
    }
  }
}

final cancelOrderControllerProvider = NotifierProvider.family<
    CancelOrderController, CancelOrderState, ServiceOrderKey>(
  CancelOrderController.new,
);
