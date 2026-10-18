import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/presentation/cache_for.dart';

int _fetches = 0;

final FutureProvider<int> _cached =
    FutureProvider.autoDispose<int>((Ref ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  return ++_fetches;
});

void main() {
  setUp(() {
    _fetches = 0;
    CacheDurations.enabled = true; // off by default in tests
  });
  tearDown(() => CacheDurations.enabled = false);

  testWidgets('keeps the value for its window after the last listener leaves, '
      'then lets it go', (WidgetTester tester) async {
    final ProviderContainer c = ProviderContainer();

    ProviderSubscription<AsyncValue<int>> screen = c.listen(_cached, (_, _) {});
    expect(await c.read(_cached.future), 1);
    screen.close(); // the screen closes

    await tester.pump(const Duration(minutes: 4));
    screen = c.listen(_cached, (_, _) {});
    expect(await c.read(_cached.future), 1, reason: 'reopened in time: no refetch');
    screen.close();

    await tester.pump(const Duration(minutes: 6));
    screen = c.listen(_cached, (_, _) {});
    expect(await c.read(_cached.future), 2, reason: 'window passed: fetched again');
    screen.close();
    c.dispose(); // cancels the running window
  });
}
