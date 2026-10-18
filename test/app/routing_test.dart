import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';
import 'package:hotel_guest_app/core/di/core_providers.dart';
import 'package:hotel_guest_app/features/authentication/presentation/state/auth_controller.dart';

import '../support/test_config.dart';

void main() {
  test('router starts at the foundation route', () {
    final container = ProviderContainer(
      overrides: <Override>[
        appConfigProvider.overrideWithValue(testConfig),
        splashMinDurationProvider.overrideWithValue(Duration.zero),
      ],
    );
    addTearDown(container.dispose);

    final GoRouter router = container.read(appRouterProvider);

    final Iterable<GoRoute> goRoutes =
        router.configuration.routes.whereType<GoRoute>();
    expect(
      goRoutes.map((GoRoute r) => r.path),
      contains(AppRoutes.foundation),
    );
    expect(
      goRoutes.firstWhere((GoRoute r) => r.path == AppRoutes.foundation).name,
      AppRoutes.foundationName,
    );
  });
}
