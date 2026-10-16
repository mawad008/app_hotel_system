import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/localization/content_language_provider.dart';
import '../../../../core/presentation/cache_for.dart';
import '../../../../core/time/clock.dart';
import '../../data/datasources/api_stay_services_data_source.dart';
import '../../data/datasources/dummy_stay_services_data_source.dart';
import '../../data/datasources/stay_services_data_source.dart';
import '../../data/repositories/stay_services_repository_impl.dart';
import '../../domain/entities/hotel_service.dart';
import '../../domain/entities/service_order.dart';
import '../../domain/repositories/stay_services_repository.dart';

/// Selects the stay-services data source by configuration — mirrors
/// `paymentDataSourceProvider`. Kept alive for the session so an order created
/// here can be re-read by the requests list.
final stayServicesDataSourceProvider =
    Provider<StayServicesDataSource>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? DummyStayServicesDataSource(clock: ref.watch(clockProvider))
      : ApiStayServicesDataSource(ref.watch(apiClientProvider));
});

final stayServicesRepositoryProvider = Provider<StayServicesRepository>(
  (Ref ref) =>
      StayServicesRepositoryImpl(ref.watch(stayServicesDataSourceProvider)),
);

/// The hotel's service catalogue.
final serviceCatalogueProvider = FutureProvider.autoDispose
    .family<ServiceCatalogue, String>((Ref ref, String hotelId) {
  ref.cacheFor(CacheDurations.reference);
  ref.watch(contentLanguageProvider); // refetch after a language switch
  return ref.watch(stayServicesRepositoryProvider).catalogue(hotelId);
});

/// The guest's service orders for a reservation, newest first.
final serviceOrdersProvider = FutureProvider.autoDispose
    .family<List<ServiceOrder>, String>((Ref ref, String reservationId) {
  ref.watch(contentLanguageProvider); // refetch after a language switch
  return ref.watch(stayServicesRepositoryProvider).ordersFor(reservationId);
});

/// A single service order.
typedef ServiceOrderKey = ({String reservationId, String orderId});

final serviceOrderProvider = FutureProvider.autoDispose
    .family<ServiceOrder, ServiceOrderKey>((Ref ref, ServiceOrderKey key) {
  ref.watch(contentLanguageProvider); // refetch after a language switch
  return ref
      .watch(stayServicesRepositoryProvider)
      .orderById(key.reservationId, key.orderId);
});
