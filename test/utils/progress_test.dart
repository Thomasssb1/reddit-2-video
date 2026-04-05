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
    });

    test('clears renderer on stop', () {
      final renderer = FakeTerminalProgressRenderer();
      final tracker = GenerationProgressTracker(renderer: renderer);

      tracker.start();
      tracker.stop();

      expect(renderer.cleared, isTrue);
    });
  });
}
