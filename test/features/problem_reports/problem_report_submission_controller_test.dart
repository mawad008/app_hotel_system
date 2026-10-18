import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/features/problem_reports/data/datasources/dummy_problem_report_data_source.dart';
import 'package:hotel_guest_app/features/problem_reports/domain/entities/problem_category.dart';
import 'package:hotel_guest_app/features/problem_reports/domain/entities/problem_report_status.dart';
import 'package:hotel_guest_app/features/problem_reports/domain/entities/problem_urgency.dart';
import 'package:hotel_guest_app/features/problem_reports/domain/entities/submit_problem_report.dart';
import 'package:hotel_guest_app/features/problem_reports/presentation/state/problem_report_providers.dart';
import 'package:hotel_guest_app/features/problem_reports/presentation/state/problem_report_submission_controller.dart';

String _scenarioId(DummyProblemReportScenario scenario) {
  for (int i = 0; i < 4000; i++) {
    final String id = 'RES$i';
    if (DummyProblemReportDataSource.scenarioFor(id) == scenario) return id;
  }
  throw StateError('no reservation id found for $scenario');
}

final DateTime _now = DateTime(2026, 9, 12, 9, 41);

ProviderContainer _container({DummyProblemReportDataSource? source}) {
  final DummyProblemReportDataSource ds =
      source ?? DummyProblemReportDataSource(clock: () => _now);
  final ProviderContainer c = ProviderContainer(overrides: <Override>[
    problemReportDataSourceProvider.overrideWithValue(ds),
  ]);
  addTearDown(c.dispose);
  c.listen(problemReportSubmissionControllerProvider, (_, _) {});
  return c;
}

void main() {
  test('idle -> submitting -> done, and a second identical submit is ignored',
      () async {
    final String id = _scenarioId(DummyProblemReportScenario.none);
    final ProviderContainer c = _container();
    expect(c.read(problemReportSubmissionControllerProvider), isA<ProblemReportIdle>());

    final SubmitProblemReportRequest request = SubmitProblemReportRequest(
      reservationId: id,
      category: ProblemCategory.acHeating,
      urgency: ProblemUrgency.important,
      notes: 'AC has not been cooling since yesterday.',
    );

    final ProblemReportSubmissionController n =
        c.read(problemReportSubmissionControllerProvider.notifier);
    await n.submit(request);

    final ProblemReportActionState state = c.read(problemReportSubmissionControllerProvider);
    expect(state, isA<ProblemReportSubmitDone>());
    expect(state.reportOrNull!.status, ProblemReportStatus.open);
    expect(state.reportOrNull!.category, ProblemCategory.acHeating);

    // Double-tap safe: a repeat of the same request is a no-op (identical
    // state object, not just an equal one).
    await n.submit(request);
    expect(identical(c.read(problemReportSubmissionControllerProvider), state), isTrue);
  });

  test('an edited resubmission (different urgency) is a distinct operation',
      () async {
    final String id = _scenarioId(DummyProblemReportScenario.none);
    final ProviderContainer c = _container();
    final ProblemReportSubmissionController n =
        c.read(problemReportSubmissionControllerProvider.notifier);

    await n.submit(SubmitProblemReportRequest(
      reservationId: id,
      category: ProblemCategory.plumbingWater,
      urgency: ProblemUrgency.normal,
    ));
    final ProblemReportActionState first = c.read(problemReportSubmissionControllerProvider);

    await n.submit(SubmitProblemReportRequest(
      reservationId: id,
      category: ProblemCategory.plumbingWater,
      urgency: ProblemUrgency.urgent,
    ));
    final ProblemReportActionState second = c.read(problemReportSubmissionControllerProvider);

    expect(second.reportOrNull!.id, isNot(first.reportOrNull!.id));
  });

  test('on a successful submit the reports-list provider is invalidated and re-read',
      () async {
    final String id = _scenarioId(DummyProblemReportScenario.none);
    final ProviderContainer c = _container();
    expect(await c.read(problemReportsProvider(id).future), isEmpty);

    await c.read(problemReportSubmissionControllerProvider.notifier).submit(
          SubmitProblemReportRequest(
            reservationId: id,
            category: ProblemCategory.electricityLighting,
            urgency: ProblemUrgency.important,
          ),
        );

    final list = await c.read(problemReportsProvider(id).future);
    expect(list, hasLength(1));
    expect(list.single.category, ProblemCategory.electricityLighting);
  });

  test('an infrastructure failure surfaces as ProblemReportSubmitFailed and a retry recovers',
      () async {
    final String id = _scenarioId(DummyProblemReportScenario.none);
    final DummyProblemReportDataSource ds =
        DummyProblemReportDataSource(clock: () => _now)..failWith = const NetworkException();
    final ProviderContainer c = _container(source: ds);
    final ProblemReportSubmissionController n =
        c.read(problemReportSubmissionControllerProvider.notifier);

    final SubmitProblemReportRequest request = SubmitProblemReportRequest(
      reservationId: id,
      category: ProblemCategory.noiseDisturbance,
      urgency: ProblemUrgency.urgent,
    );
    await n.submit(request);
    expect(c.read(problemReportSubmissionControllerProvider), isA<ProblemReportSubmitFailed>());

    ds.failWith = null;
    await n.submit(request); // same request retried after clearing the fault
    expect(c.read(problemReportSubmissionControllerProvider), isA<ProblemReportSubmitDone>());
  });
}
