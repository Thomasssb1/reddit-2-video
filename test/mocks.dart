import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/config/background_video.dart';
import 'package:reddit_2_video/config/empty_noise.dart';
import 'package:reddit_2_video/config/end_card.dart';
import 'package:reddit_2_video/config/lexicons/lexica.dart';
import 'package:reddit_2_video/config/music.dart';
import 'package:reddit_2_video/reddit/reddit_post.dart';
import 'package:reddit_2_video/reddit_video.dart';
import 'package:reddit_2_video/subtitles/subtitles.dart';
import 'package:reddit_2_video/config/voices/voices.dart';
import 'package:reddit_2_video/utils/progress.dart';

class MockRedditVideo extends Mock implements RedditVideo {}

class MockRedditPost extends Mock implements RedditPost {}

class MockBackgroundVideo extends Mock implements BackgroundVideo {}

class MockParsedCommand extends Mock implements ParsedCommand {
  @override
  File outputFile(int index) {
    var resolvedOutput = output;
    final resolvedFileType = fileType;
    final fileExtension = p.extension(resolvedOutput);

    if (fileExtension.isNotEmpty) {
      resolvedOutput = p.withoutExtension(resolvedOutput);
    }

    final count = repeat == 1 ? '' : '-$index';
    return File('$resolvedOutput$count.${resolvedFileType.name}');
  }
}

class MockEndCard extends Mock implements EndCard {}

class MockFile extends Mock implements File {}

class MockLexica extends Mock implements Lexica {}

class MockSubtitles extends Mock implements Subtitles {}

class MockEmptyNoise extends Mock implements EmptyNoise {}

class MockMusic extends Mock implements Music {}

class MockVoices extends Mock implements Voices {}

class FakeTerminalProgressRenderer extends TerminalProgressRenderer {
  final List<ProgressSnapshot> snapshots = [];
  bool cleared = false;
  int suspendCalls = 0;
  int resumeCalls = 0;

  FakeTerminalProgressRenderer()
      : super(
          enabled: true,
          stdoutSink: stdout,
          stderrSink: stderr,
        );

  @override
  void update(ProgressSnapshot snapshot) {
    snapshots.add(snapshot);
  }

  @override
  void clear() {
    cleared = true;
  }

  @override
  void suspend() {
    suspendCalls++;
    super.suspend();
  }

  @override
  void resume() {
    resumeCalls++;
    super.resume();
  }

  @override
  void writeMessage(String message, {required bool isError}) {}
}

class FakeProcess implements Process {
  final int _fakeExitCode;
  final Stream<List<int>> _stdout;
  final Stream<List<int>> _stderr;

  FakeProcess({required int exitCode, String out = '', String err = ''})
      : _fakeExitCode = exitCode,
        _stdout = Stream.value(utf8.encode(out)),
        _stderr = Stream.value(utf8.encode(err));

  @override
  Future<int> get exitCode async => _fakeExitCode;

  @override
  int get pid => 1337;

  @override
  IOSink get stdin => IOSink(StreamController<List<int>>().sink);

  @override
  Stream<List<int>> get stderr => _stderr;

  @override
  Stream<List<int>> get stdout => _stdout;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => true;
}
