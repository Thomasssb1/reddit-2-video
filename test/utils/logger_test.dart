import 'package:reddit_2_video/exceptions/subprocess_exception.dart';
import 'package:reddit_2_video/utils/logger.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    logger.setAnsiEscapesForTest(false);
  });

  tearDown(() {
    logger.resetForTest();
  });

  group('Logger.error', () {
    test('logs message and detail for detailed exceptions', () {
      final stderrBuffer = StringBuffer();
      logger.setOutputSinksForTest(stderrSink: stderrBuffer);

      logger.error(
        SubprocessException(
          message: 'Generation failed.',
          detail: 'Token has expired and refresh failed',
          executable: 'test',
          arguments: const [],
        ),
        section: LogSection.setup,
      );

      expect(stderrBuffer.toString(), contains('Generation failed.'));
      expect(
        stderrBuffer.toString(),
        contains('Token has expired and refresh failed'),
      );
      expect(stderrBuffer.toString(), isNot(contains('stderr:')));
    });

    test('logs only message when detail is blank', () {
      final stderrBuffer = StringBuffer();
      logger.setOutputSinksForTest(stderrSink: stderrBuffer);

      logger.error(
        SubprocessException(
          message: 'Generation failed.',
          detail: '   ',
          executable: 'test',
          arguments: const [],
        ),
        section: LogSection.setup,
      );

      expect(
        RegExp('Generation failed\\.').allMatches(stderrBuffer.toString()),
        hasLength(1),
      );
    });

    test('falls back to toString for non-detailed exceptions', () {
      final stderrBuffer = StringBuffer();
      logger.setOutputSinksForTest(stderrSink: stderrBuffer);

      logger.error(Exception('plain error'), section: LogSection.setup);

      expect(stderrBuffer.toString(), contains('Exception: plain error'));
    });
  });

  group('Logger.prefixLines', () {
    test('returns message unchanged when section is null', () {
      expect(logger.prefixLines('plain message'), equals('plain message'));
    });

    test('prefixes each line and preserves trailing newline', () {
      final output = logger.prefixLines(
        'first line\nsecond line\n',
        section: LogSection.setup,
      );

      expect(output, equals('[Setup] first line\n[Setup] second line\n'));
    });

    test('prefixes blank lines with section label only', () {
      final output = logger.prefixLines(
        'first line\n\nthird line',
        section: LogSection.setup,
      );

      expect(output, equals('[Setup] first line\n[Setup]\n[Setup] third line'));
    });

    test('adds a section break when the section changes', () {
      logger.prefixLines('first', section: LogSection.setup);

      final output = logger.prefixLines('second', section: LogSection.reddit);

      expect(output, equals('\n[Reddit] second'));
    });

    test('does not add a section break when the section stays the same', () {
      logger.prefixLines('first', section: LogSection.setup);

      final output = logger.prefixLines('second', section: LogSection.setup);

      expect(output, equals('[Setup] second'));
    });
  });

  group('Logger.emitRaw', () {
    test('writes stdout messages to stdout sink', () {
      final stdoutBuffer = StringBuffer();
      logger.setOutputSinksForTest(stdoutSink: stdoutBuffer);

      logger.emitRaw('hello', section: LogSection.setup);

      expect(stdoutBuffer.toString(), equals('[Setup] hello'));
    });

    test('writes error messages to stderr sink', () {
      final stderrBuffer = StringBuffer();
      logger.setOutputSinksForTest(stderrSink: stderrBuffer);

      logger.emitRaw('hello', section: LogSection.setup, isError: true);

      expect(stderrBuffer.toString(), equals('[Setup] hello'));
    });

    test('sends output through overlay when attached', () {
      final events = <({String message, bool isError})>[];
      logger.attachOverlay((message, {required isError}) {
        events.add((message: message, isError: isError));
      });

      logger.emitRaw('hello', section: LogSection.setup, isError: true);

      expect(events, hasLength(1));
      expect(events.single.message, equals('[Setup] hello'));
      expect(events.single.isError, isTrue);
    });

    test('stops using overlay after it is detached', () {
      final stdoutBuffer = StringBuffer();
      final events = <String>[];
      logger.setOutputSinksForTest(stdoutSink: stdoutBuffer);
      logger.attachOverlay((message, {required isError}) {
        events.add(message);
      });

      logger.emitRaw('through overlay', section: LogSection.setup);
      logger.detachOverlay();
      logger.emitRaw('through sink', section: LogSection.setup);

      expect(events, equals(['[Setup] through overlay']));
      expect(stdoutBuffer.toString(), equals('[Setup] through sink'));
    });
  });

  group('Logger helpers', () {
    test('info writes to stdout with section prefix', () {
      final stdoutBuffer = StringBuffer();
      logger.setOutputSinksForTest(stdoutSink: stdoutBuffer);

      logger.info('hello', section: LogSection.setup);

      expect(stdoutBuffer.toString(), equals('[Setup] hello\n'));
    });

    test('warning writes to stdout with section prefix', () {
      final stdoutBuffer = StringBuffer();
      logger.setOutputSinksForTest(stdoutSink: stdoutBuffer);

      logger.warning('careful', section: LogSection.setup);

      expect(stdoutBuffer.toString(), contains('[Setup] careful\n'));
    });

    test('success writes to stdout with section prefix', () {
      final stdoutBuffer = StringBuffer();
      logger.setOutputSinksForTest(stdoutSink: stdoutBuffer);

      logger.success('done', section: LogSection.setup);

      expect(stdoutBuffer.toString(), contains('[Setup] done\n'));
    });

    test('underline writes to stdout with section prefix', () {
      final stdoutBuffer = StringBuffer();
      logger.setOutputSinksForTest(stdoutSink: stdoutBuffer);

      logger.underline('heading', section: LogSection.setup);

      expect(stdoutBuffer.toString(), contains('[Setup] heading\n'));
    });
  });
}
