import 'dart:io';

import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('simple exceptions', () {
    test('ArgumentConflictException exposes conflicting arguments', () {
      final exception =
          ArgumentConflictException('conflict', '--a', '--b');

      expect(exception.argument1, '--a');
      expect(exception.argument2, '--b');
      expect(exception.toString(), 'conflict');
    });

    test('ArgumentMissingException returns its message', () {
      expect(
        ArgumentMissingException('missing').toString(),
        'missing',
      );
    });

    test('ArgumentNotImplementedException returns its message', () {
      expect(
        ArgumentNotImplementedException('todo').toString(),
        'todo',
      );
    });

    test('EmptyPostSelectionException returns its message', () {
      expect(
        const EmptyPostSelectionException(message: 'empty').toString(),
        'empty',
      );
    });

    test('InvalidFileFormatException exposes file and message', () {
      final file = File('broken.json');
      final exception = InvalidFileFormatException('bad file', file);

      expect(exception.file.path, file.path);
      expect(exception.toString(), 'bad file');
    });

    test('InvalidPostUrlException exposes url in toString', () {
      final exception = InvalidPostUrlException('bad post', 'https://x');

      expect(exception.url, 'https://x');
      expect(exception.toString(), 'bad post, url: https://x');
    });

    test('InvalidVideoUrl exposes uri in toString', () {
      final url = Uri.https('example.com', '/video');
      final exception = InvalidVideoUrl('bad video', url);

      expect(exception.url, url);
      expect(exception.toString(), 'bad video, url: $url');
    });

    test('MaxLengthExceededException stores lengths and message', () {
      final exception = MaxLengthExceededException(
        message: 'too long',
        maxLength: const Duration(seconds: 60),
        actualLength: const Duration(seconds: 75),
      );

      expect(exception.maxLength, const Duration(seconds: 60));
      expect(exception.actualLength, const Duration(seconds: 75));
      expect(exception.toString(), 'too long');
    });

    test('NoCommandException returns its message', () {
      expect(NoCommandException('missing').toString(), 'missing');
    });

    test('OutputFileExistsException exposes file and message', () {
      final file = File('output.mp4');
      const message = 'exists';
      final exception = OutputFileExistsException(
        message: message,
        file: file,
      );

      expect(exception.file.path, file.path);
      expect(exception.toString(), message);
    });

    test('PollyInvalidPlsLexicon exposes file and message', () {
      final file = File('lexicon.xml');
      final exception = PollyInvalidPlsLexicon('invalid', file);

      expect(exception.file.path, file.path);
      expect(exception.toString(), 'invalid');
    });

    test('PostAlreadyGeneratedException keeps optional help text', () {
      const exception = PostAlreadyGeneratedException(
        message: 'done',
        help: 'remove from log',
      );

      expect(exception.help, 'remove from log');
      expect(exception.toString(), 'done');
    });

    test('PostsExhaustedException returns its message', () {
      expect(
        const PostsExhaustedException(message: 'exhausted').toString(),
        'exhausted',
      );
    });

    test('RedditApiException includes status code in toString', () {
      final exception = RedditApiException(
        message: 'rate limited',
        statusCode: 429,
      );

      expect(exception.statusCode, 429);
      expect(exception.toString(), 'rate limited, status code: 429');
    });
  });

  group('SubprocessException', () {
    test('builds errorDetail from detail stderr and stdout in order', () {
      final exception = SubprocessException(
        message: 'failed',
        executable: 'ffmpeg',
        arguments: const ['-i', 'input.mp4'],
        detail: 'high level detail  \n',
        stderr: 'stderr output\n',
        stdout: 'stdout output\n',
      );

      expect(
        exception.errorDetail,
        'high level detail\n\nstderr output\n\nstdout output',
      );
      expect(exception.toString(), 'failed');
    });

    test('ignores blank detail sections', () {
      final exception = SubprocessException(
        message: 'failed',
        executable: 'tool',
        arguments: const [],
        detail: '   ',
        stderr: '',
        stdout: '  ok  \n',
      );

      expect(exception.errorDetail, '  ok');
    });

    test('returns null errorDetail when no detail content exists', () {
      final exception = SubprocessException(
        message: 'failed',
        executable: 'tool',
        arguments: const [],
      );

      expect(exception.errorDetail, isNull);
    });
  });

  group('SubprocessException subclasses', () {
    test('FFmpegCommandException sets ffmpeg executable and command args', () {
      final exception = FFmpegCommandException(
        message: 'render failed',
        command: const ['-i', 'input.mp4'],
        exitCode: 1,
        stderr: 'bad stderr',
        stdout: 'bad stdout',
        detail: 'render detail',
      );

      expect(exception.executable, 'ffmpeg');
      expect(exception.arguments, ['-i', 'input.mp4']);
      expect(exception.command, ['-i', 'input.mp4']);
      expect(exception.exitCode, 1);
      expect(
        exception.errorDetail,
        'render detail\n\nbad stderr\n\nbad stdout',
      );
    });

    test('BackgroundVideoCuttingException keeps url and duration', () {
      final exception = BackgroundVideoCuttingException(
        message: 'cut failed',
        url: 'https://youtube.com/watch?v=1',
        duration: const Duration(seconds: 30),
        executable: 'ffmpeg',
        arguments: const ['-ss', '0'],
      );

      expect(exception.url, 'https://youtube.com/watch?v=1');
      expect(exception.duration, const Duration(seconds: 30));
      expect(exception.executable, 'ffmpeg');
    });

    test('TTSFailedException keeps id and text', () {
      final exception = TTSFailedException(
        message: 'tts failed',
        id: 'abc123',
        text: 'hello world',
        executable: 'aws',
        arguments: const ['polly'],
      );

      expect(exception.id, 'abc123');
      expect(exception.text, 'hello world');
      expect(exception.executable, 'aws');
    });

    test('VideoDownloadFailedException keeps url and detail composition', () {
      final url = Uri.https('example.com', '/video');
      final exception = VideoDownloadFailedException(
        message: 'download failed',
        url: url,
        executable: 'yt-dlp',
        arguments: const ['--format', 'mp4'],
        stderr: 'stderr',
      );

      expect(exception.url, url);
      expect(exception.executable, 'yt-dlp');
      expect(exception.arguments, ['--format', 'mp4']);
      expect(exception.errorDetail, 'stderr');
    });
  });
}
