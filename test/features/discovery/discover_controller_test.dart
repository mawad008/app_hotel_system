import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/presentation/ui_state.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/discover_controller.dart';
import 'package:hotel_guest_app/features/discovery/presentation/state/discovery_providers.dart';

import '../../support/auth_test_support.dart';

void main() {
  test('resolves to a success view with the greeting name and featured hotels',
      () async {
    final ProviderContainer c = ProviderContainer(
      overrides: authOverrides(bootSession: completeSession()),
    );
    addTearDown(c.dispose);
    c.listen(discoverControllerProvider, (_, _) {});

    DiscoverView? view;
    for (int i = 0; i < 50; i++) {
      view = c.read(discoverControllerProvider).value;
      if (view?.greetingName != null) break;
      await Future<void>.delayed(Duration.zero);
    }

    expect(view, isNotNull);
    expect(view!.featuredHotels, isNotEmpty);
    expect(view.greetingName, 'Test'); // "Test Guest" → first name

    expect(
      discoverUiState(c.read(discoverControllerProvider)),
      isA<UiSuccess<DiscoverView>>(),
    );
  });

  test('featured hotels come through the repository', () async {
    final ProviderContainer c = ProviderContainer(
      overrides: authOverrides(),
    );
    addTearDown(c.dispose);

    final hotels =
        await c.read(discoveryRepositoryProvider).featuredHotels();
    expect(hotels.first.id, 'oasis');
  });
}
