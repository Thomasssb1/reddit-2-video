import 'dart:io';

import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/config/background_video.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/log/log.dart';
import 'package:reddit_2_video/reddit_video.dart';
import 'package:reddit_2_video/reddit/reddit_video_type.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

void main() {
  late Directory tempDir;
  late MockRedditPost post;
  late ParsedCommand command;
  late BackgroundVideo backgroundVideo;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('reddit_video_test_');
    AppPaths.initForTest(tempDir);
    post = MockRedditPost();
    command = MockParsedCommand();
    backgroundVideo = MockBackgroundVideo();

    when(() => post.id).thenReturn('abc123');
    when(() => post.comments).thenReturn([]);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('RedditVideo', () {
    group('folder structure', () {
      test('creates .temp/<id> directory on construction', () {
        final video = RedditVideo(
          posts: [post],
          videoType: RedditVideoType.post,
        );

        final expected = Directory('${tempDir.path}/.temp/${video.id}');
        expect(expected.existsSync(), isTrue);
      });
    });

    group('id', () {
      test('returns single post id', () {
        final video = RedditVideo(
          posts: [post],
          videoType: RedditVideoType.post,
        );
        expect(video.id, 'abc123');
      });

      test('joins multiple post ids with dash', () {
        final post1 = MockRedditPost();
        final post2 = MockRedditPost();
        when(() => post1.id).thenReturn('aaa');
        when(() => post2.id).thenReturn('bbb');
        when(() => post1.comments).thenReturn([]);
        when(() => post2.comments).thenReturn([]);

        final video = RedditVideo(
          posts: [post1, post2],
          videoType: RedditVideoType.multi,
        );
        expect(video.id, 'aaa-bbb');
      });
    });

    group('RedditVideo.single', () {
      test('wraps single post in list of length 1', () {
        final video = RedditVideo.single(
          post: post,
          videoType: RedditVideoType.post,
        );
        expect(video.posts.length, 1);
        expect(video.id, 'abc123');
      });
    });

    group('parse (feasible branches)', () {
      test('throws conflict when subreddit is link and type is multi',
          () async {
        when(() => command.subredditIsLink).thenReturn(true);
        when(() => command.type).thenReturn(RedditVideoType.multi);
        when(() => command.subreddit)
            .thenReturn('https://reddit.com/r/x/comments/abc');

        final log = await Log.fromFile();

        expect(
          () => RedditVideo.parse(command, log),
          throwsA(isA<ArgumentConflictException>()),
        );
      });
    });

    group('generate (feasible branches)', () {
      test('throws when subtitles are not attached', () async {
        final video = RedditVideo(
          posts: [post],
          videoType: RedditVideoType.post,
        );

        final cutVideo = File('${tempDir.path}/cut.mp4');
        cutVideo.createSync();

        expect(
          () => video.generate(command, backgroundVideo, cutVideo, 1),
          throwsA(isA<ArgumentMissingException>()),
        );
      });
    });
  });
}
