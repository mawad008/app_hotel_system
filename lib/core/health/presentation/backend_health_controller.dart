import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/core_providers.dart';
import '../../errors/error_mapper.dart';
import '../../presentation/ui_state.dart';
import '../domain/backend_health.dart';
import '../domain/health_repository.dart';

/// Drives the "Backend connectivity" card on the foundation screen. Demonstrates
/// the full UI → state → repository → data source path with explicit
/// loading / success / failure states (mobile/docs/feature_guide.md Step 6).
class BackendHealthController extends AsyncNotifier<BackendHealth> {
  @override
  Future<BackendHealth> build() {
    final HealthRepository repository = ref.watch(healthRepositoryProvider);
    return repository.check();
  }

  Future<void> refresh() async {
    state = const AsyncValue<BackendHealth>.loading();
    state = await AsyncValue.guard(
      () => ref.read(healthRepositoryProvider).check(),
    );
  }
}

final backendHealthControllerProvider =
    AsyncNotifierProvider.autoDispose<BackendHealthController, BackendHealth>(
  BackendHealthController.new,
);

/// Adapts the Riverpod [AsyncValue] to the app's [UiState] so widgets use a
/// single state vocabulary. A [Failure] thrown by the repository is surfaced
/// as [UiFailure]; any other error is mapped defensively.
UiState<BackendHealth> backendHealthUiState(AsyncValue<BackendHealth> value) {
  return value.map(
    data: (AsyncData<BackendHealth> d) => UiState<BackendHealth>.success(d.value),
    loading: (_) => const UiLoading<BackendHealth>(),
    error: (AsyncError<BackendHealth> e) =>
        UiState<BackendHealth>.failure(ErrorMapper.toFailure(e.error)),
  );
}
