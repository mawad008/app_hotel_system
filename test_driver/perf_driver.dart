import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

/// Writes one timeline summary per traced action to
/// `build/<name>.timeline_summary.json` (frame build / raster times, missed
/// frame budgets). Run with:
///
///   flutter drive --profile --dart-define=USE_DUMMY_DATA=true \
///     --driver=test_driver/perf_driver.dart \
///     --target=integration_test/scroll_performance_test.dart
///
/// Afterwards, build releases with `pub get` (no `--no-pub`): the drive run
/// leaves the dev-only `integration_test` plugin in the Android registrant.
Future<void> main() {
  return integrationDriver(
    responseDataCallback: (Map<String, dynamic>? data) async {
      if (data == null) return;
      for (final MapEntry<String, dynamic> entry in data.entries) {
        final driver.Timeline timeline = driver.Timeline.fromJson(
          entry.value as Map<String, dynamic>,
        );
        await driver.TimelineSummary.summarize(timeline).writeTimelineToFile(
          entry.key,
          pretty: true,
          includeSummary: true,
        );
      }
    },
  );
}
