import 'package:reddit_2_video/utils/logger.dart';
import 'package:reddit_2_video/utils/progress.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  tearDown(() {
    logger.resetForTest();
  });

  group('GenerationProgressTracker', () {
    test('updates renderer with weighted overall progress', () {
      final renderer = FakeTerminalProgressRenderer();
      final tracker = GenerationProgressTracker(renderer: renderer);

      tracker.start();
      final setup = tracker.createTask(
        title: 'Setup',
        weight: 2,
        section: LogSection.setup,
        totalUnits: 2,
      );
      final render = tracker.createTask(
        title: 'Render',
        weight: 6,
        section: LogSection.generation,
        totalUnits: 3,
      );

      tracker.incrementTask(setup);
      tracker.incrementTask(render, by: 1, detail: 'Frame 1');

      expect(renderer.snapshots, isNotEmpty);
      final latest = renderer.snapshots.last;
      expect(latest.fraction, closeTo(0.375, 0.001));
      expect(latest.title, 'Render');
      expect(latest.detail, 'Frame 1');

      tracker.stop();
    });

    test('clears renderer on stop', () {
      final renderer = FakeTerminalProgressRenderer();
      final tracker = GenerationProgressTracker(renderer: renderer);

      tracker.start();
      tracker.stop();

      expect(renderer.cleared, isTrue);
    });

    test('suspends and resumes overlay around interactive work', () async {
      final renderer = FakeTerminalProgressRenderer();
      final tracker = GenerationProgressTracker(renderer: renderer);

      tracker.start();
      tracker.createTask(
        title: 'Select Reddit content',
        weight: 1,
        section: LogSection.reddit,
        totalUnits: 1,
        detail: 'Awaiting confirmation',
      );

      final snapshotCountBeforeSuspend = renderer.snapshots.length;

      await tracker.runWithOverlaySuspended(() async {
        expect(renderer.isSuspended, isTrue);
        tracker.reportStandaloneProgress(
          title: 'Select Reddit content',
          detail: 'Should not redraw while suspended',
          section: LogSection.reddit,
          fraction: 0.5,
        );
      });

      expect(renderer.suspendCalls, 1);
      expect(renderer.resumeCalls, 1);
      expect(renderer.isSuspended, isFalse);
      expect(renderer.cleared, isTrue);
      expect(renderer.snapshots.length, snapshotCountBeforeSuspend + 1);
      expect(
        renderer.snapshots.last.detail,
        'Should not redraw while suspended',
      );

      tracker.stop();
    });

    test('animates spinner while waiting for progress updates', () async {
      final renderer = FakeTerminalProgressRenderer();
      final tracker = GenerationProgressTracker(
        renderer: renderer,
        spinnerInterval: const Duration(milliseconds: 10),
      );

      tracker.start();
      tracker.createTask(
        title: 'Render',
        weight: 1,
        section: LogSection.generation,
        totalUnits: 10,
        detail: 'Waiting for ffmpeg',
      );

      final initialSnapshotCount = renderer.snapshots.length;
      final initialSpinnerFrame = renderer.snapshots.last.spinnerFrame;

      await Future<void>.delayed(const Duration(milliseconds: 35));

      expect(renderer.snapshots.length, greaterThan(initialSnapshotCount));
      expect(
        renderer.snapshots.last.spinnerFrame,
        isNot(equals(initialSpinnerFrame)),
      );

      tracker.stop();
    });
  });
}
