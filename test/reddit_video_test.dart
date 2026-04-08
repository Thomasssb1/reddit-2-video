import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/config/background_video.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/log/log.dart';
import 'package:reddit_2_video/reddit/reddit_http_retry.dart';
import 'package:reddit_2_video/reddit/reddit_id.dart';
import 'package:reddit_2_video/reddit/reddit_post_sort_type.dart';
import 'package:reddit_2_video/reddit_video.dart';
import 'package:reddit_2_video/reddit/reddit_video_type.dart';
import 'package:reddit_2_video/utils/logger.dart';
import 'package:reddit_2_video/utils/subprocess/subprocess.dart';
import 'package:reddit_2_video/ffmpeg/file_type.dart';
import 'package:reddit_2_video/ffmpeg/fps.dart';
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
    RedditHttpRetry.resetForTest();
    Subprocess.resetForTest();
    logger.resetForTest();
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

      test('parses direct link and marks it as temporarily added', () async {
        when(() => command.subredditIsLink).thenReturn(true);
        when(() => command.type).thenReturn(RedditVideoType.post);
        when(() => command.subreddit).thenReturn(
          'https://reddit.com/r/test/comments/abc123/title/',
        );

        RedditHttpRetry.setGetForTest((url) async {
          return http.Response.bytes(
            utf8.encode(jsonEncode([
              {
                'data': {
                  'children': [
                    {
                      'data': {
                        'subreddit': 'test',
                        'subreddit_id': 't5_test',
                        'title': 'Title',
                        'selftext': 'Body',
                        'id': 'abc123',
                        'ups': 1,
                        'created_utc': 1701083780,
                        'spoiler': false,
                        'stickied': false,
                        'over_18': false,
                        'media': false,
                        'num_comments': 5,
                      }
                    }
                  ]
                }
              }
            ])),
            200,
          );
        });

        final log = await Log.fromFile();
        final video = await RedditVideo.parse(command, log);

        expect(video.posts, hasLength(1));
        expect(video.videoType, RedditVideoType.post);
        expect(log.contains(video.posts.first), isTrue);
      });

      test('throws when direct-link post already exists in log', () async {
        when(() => command.subredditIsLink).thenReturn(true);
        when(() => command.type).thenReturn(RedditVideoType.post);
        when(() => command.subreddit).thenReturn(
          'https://reddit.com/r/test/comments/abc123/title/',
        );

        RedditHttpRetry.setGetForTest((url) async {
          return http.Response.bytes(
            utf8.encode(jsonEncode([
              {
                'data': {
                  'children': [
                    {
                      'data': {
                        'subreddit': 'test',
                        'subreddit_id': 't5_test',
                        'title': 'Title',
                        'selftext': 'Body',
                        'id': 'abc123',
                        'ups': 1,
                        'created_utc': 1701083780,
                        'spoiler': false,
                        'stickied': false,
                        'over_18': false,
                        'media': false,
                        'num_comments': 5,
                      }
                    }
                  ]
                }
              }
            ])),
            200,
          );
        });

        final logFile = AppPaths.resolve('.temp/visited_log.json');
        logFile.createSync(recursive: true);
        logFile.writeAsStringSync(jsonEncode({
          '_last_updated': DateTime.now().toUtc().toString(),
          'visited': [
            {'post_id': 'abc123', 'subreddit_id': 't5_test'}
          ],
        }));
        final log = await Log.fromFile();

        await expectLater(
          () => RedditVideo.parse(command, log),
          throwsA(isA<PostAlreadyGeneratedException>()),
        );
      });

      test('parses subreddit listing and returns first eligible post',
          () async {
        when(() => command.subredditIsLink).thenReturn(false);
        when(() => command.subreddit).thenReturn('test');
        when(() => command.sort).thenReturn(RedditPostSortType.top);
        when(() => command.type).thenReturn(RedditVideoType.post);
        when(() => command.postConfirmation).thenReturn(false);
        when(() => command.commentCount).thenReturn(2);
        when(() => command.nsfw).thenReturn(false);

        RedditHttpRetry.setGetForTest((url) async {
          return http.Response.bytes(
            utf8.encode(jsonEncode({
              'data': {
                'children': [
                  {
                    'data': {
                      'subreddit': 'test',
                      'subreddit_id': 't5_test',
                      'title': 'Title',
                      'selftext': 'Body',
                      'id': 'abc123',
                      'ups': 1,
                      'created_utc': 1701083780,
                      'spoiler': false,
                      'stickied': false,
                      'over_18': false,
                      'media': false,
                      'num_comments': 3,
                    }
                  }
                ]
              }
            })),
            200,
          );
        });

        final log = await Log.fromFile();
        final stdoutBuffer = StringBuffer();
        logger.setOutputSinksForTest(stdoutSink: stdoutBuffer);
        final video = await RedditVideo.parse(command, log);

        expect(video.posts, hasLength(1));
        expect(video.posts.first.id, 'abc123-t5_test');

        final output = stdoutBuffer.toString();
        expect(output, contains('Fetching posts from r/test sorted by top.'));
        expect(output, contains('Received 1 post candidates from Reddit.'));
        expect(output, contains('Found 1 eligible post after filtering.'));
        expect(output, contains('Selected post abc123-t5_test.'));
      });

      test('throws PostsExhausted when no eligible posts are returned',
          () async {
        when(() => command.subredditIsLink).thenReturn(false);
        when(() => command.subreddit).thenReturn('test');
        when(() => command.sort).thenReturn(RedditPostSortType.top);
        when(() => command.type).thenReturn(RedditVideoType.post);
        when(() => command.postConfirmation).thenReturn(false);
        when(() => command.commentCount).thenReturn(2);
        when(() => command.nsfw).thenReturn(false);

        RedditHttpRetry.setGetForTest((url) async {
          return http.Response.bytes(
            utf8.encode(jsonEncode({
              'data': {
                'children': [
                  {
                    'data': {
                      'subreddit': 'test',
                      'subreddit_id': 't5_test',
                      'title': 'Title',
                      'selftext': 'Body',
                      'id': 'abc123',
                      'ups': 1,
                      'created_utc': 1701083780,
                      'spoiler': false,
                      'stickied': false,
                      'over_18': true,
                      'media': false,
                      'num_comments': 1,
                    }
                  }
                ]
              }
            })),
            200,
          );
        });

        final log = await Log.fromFile();

        await expectLater(
          () => RedditVideo.parse(command, log),
          throwsA(isA<PostsExhaustedException>()),
        );
      });

      test(
          'confirmPostSelection keeps candidates unchanged and returns accepted multi posts',
          () async {
        final firstPost = MockRedditPost();
        final secondPost = MockRedditPost();
        final thirdPost = MockRedditPost();
        final candidates = [firstPost, secondPost, thirdPost];

        when(() => command.type).thenReturn(RedditVideoType.multi);
        when(() => command.commentCount).thenReturn(2);
        when(() => command.nsfw).thenReturn(false);
        when(() => command.subreddit).thenReturn('test');

        when(() => firstPost.title).thenReturn('First');
        when(() => firstPost.upvotes).thenReturn(10);
        when(() => firstPost.commentCount).thenReturn(5);
        when(() => firstPost.created)
            .thenReturn(DateTime.fromMillisecondsSinceEpoch(1701083780000));
        when(() => firstPost.spoiler).thenReturn(false);
        when(() => firstPost.hasMedia).thenReturn(false);
        when(() => firstPost.nsfw).thenReturn(false);
        when(() => firstPost.body).thenReturn('First body');
        when(() => firstPost.redditId).thenReturn(RedditId('first', 't5_test'));
        when(() => firstPost.id).thenReturn('first-t5_test');

        when(() => secondPost.title).thenReturn('Second');
        when(() => secondPost.upvotes).thenReturn(20);
        when(() => secondPost.commentCount).thenReturn(6);
        when(() => secondPost.created)
            .thenReturn(DateTime.fromMillisecondsSinceEpoch(1701083781000));
        when(() => secondPost.spoiler).thenReturn(false);
        when(() => secondPost.hasMedia).thenReturn(false);
        when(() => secondPost.nsfw).thenReturn(false);
        when(() => secondPost.body).thenReturn('Second body');
        when(() => secondPost.redditId)
            .thenReturn(RedditId('second', 't5_test'));
        when(() => secondPost.id).thenReturn('second-t5_test');

        when(() => thirdPost.title).thenReturn('Third');
        when(() => thirdPost.upvotes).thenReturn(30);
        when(() => thirdPost.commentCount).thenReturn(7);
        when(() => thirdPost.created)
            .thenReturn(DateTime.fromMillisecondsSinceEpoch(1701083782000));
        when(() => thirdPost.spoiler).thenReturn(false);
        when(() => thirdPost.hasMedia).thenReturn(false);
        when(() => thirdPost.nsfw).thenReturn(false);
        when(() => thirdPost.body).thenReturn('Third body');
        when(() => thirdPost.redditId).thenReturn(RedditId('third', 't5_test'));
        when(() => thirdPost.id).thenReturn('third-t5_test');

        final log = await Log.fromFile();
        final responses = ['n', 'y', 'n', 'n', 'n', 'y'].iterator;

        final selected = await RedditVideo.confirmPostSelection(
          candidates: candidates,
          command: command,
          log: log,
          readLine: () {
            expect(responses.moveNext(), isTrue);
            return responses.current;
          },
        );

        expect(candidates, hasLength(3));
        expect(selected, equals([firstPost, thirdPost]));
        expect(log.contains(secondPost), isTrue);
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

      test('runs ffmpeg and succeeds when command is valid', () async {
        final video = RedditVideo(
          posts: [post],
          videoType: RedditVideoType.post,
        );
        final subtitles = MockSubtitles();
        video.subtitles = subtitles;
        final cutVideo = File('${tempDir.path}/cut.mp4')..createSync();

        when(() => command.type).thenReturn(RedditVideoType.post);
        when(() => command.endCard).thenAnswer((_) async => null);
        when(() => command.music).thenReturn(null);
        when(() => command.verbose).thenReturn(false);
        when(() => command.override).thenReturn(false);
        when(() => command.horror).thenReturn(false);
        when(() => command.framerate).thenReturn(FPS.fps45);
        when(() => command.output).thenReturn('output.mp4');
        when(() => command.fileType).thenReturn(FileType.mp4);
        when(() => command.repeat).thenReturn(1);
        when(() => command.youtubeShort).thenReturn(false);

        when(() => backgroundVideo.position).thenReturn(0);
        when(() => subtitles.getTTSFilesAsInput()).thenReturn([]);
        when(() => subtitles.getTTSStream(any())).thenReturn(['[1:a]']);
        when(() => subtitles.assFile)
            .thenReturn(File('${tempDir.path}/sub.ass'));
        when(() => subtitles.duration).thenReturn(const Duration(seconds: 5));
        when(() => subtitles.position = any<int>()).thenReturn(0);

        var ffmpegCalled = false;
        Subprocess.setStartForTest((executable, arguments,
            {workingDirectory,
            environment,
            includeParentEnvironment = true,
            runInShell = false,
            mode = ProcessStartMode.normal}) async {
          ffmpegCalled = true;
          return FakeProcess(exitCode: 0);
        });

        await video.generate(command, backgroundVideo, cutVideo, 1);

        expect(ffmpegCalled, isTrue);
      });

      test('throws FFmpegCommandException when ffmpeg fails', () async {
        final video = RedditVideo(
          posts: [post],
          videoType: RedditVideoType.post,
        );
        final subtitles = MockSubtitles();
        video.subtitles = subtitles;
        final cutVideo = File('${tempDir.path}/cut.mp4')..createSync();

        when(() => command.type).thenReturn(RedditVideoType.post);
        when(() => command.endCard).thenAnswer((_) async => null);
        when(() => command.music).thenReturn(null);
        when(() => command.verbose).thenReturn(false);
        when(() => command.override).thenReturn(false);
        when(() => command.horror).thenReturn(false);
        when(() => command.framerate).thenReturn(FPS.fps45);
        when(() => command.output).thenReturn('output.mp4');
        when(() => command.fileType).thenReturn(FileType.mp4);
        when(() => command.repeat).thenReturn(1);
        when(() => command.youtubeShort).thenReturn(false);

        when(() => backgroundVideo.position).thenReturn(0);
        when(() => subtitles.getTTSFilesAsInput()).thenReturn([]);
        when(() => subtitles.getTTSStream(any())).thenReturn(['[1:a]']);
        when(() => subtitles.assFile)
            .thenReturn(File('${tempDir.path}/sub.ass'));
        when(() => subtitles.duration).thenReturn(const Duration(seconds: 5));
        when(() => subtitles.position = any<int>()).thenReturn(0);

        Subprocess.setStartForTest((executable, arguments,
            {workingDirectory,
            environment,
            includeParentEnvironment = true,
            runInShell = false,
            mode = ProcessStartMode.normal}) async {
          return FakeProcess(exitCode: 1, err: 'render failed');
        });

        await expectLater(
          () => video.generate(command, backgroundVideo, cutVideo, 1),
          throwsA(isA<FFmpegCommandException>().having((e) => e.errorDetail,
              'errorDetail', contains('stderr:\nrender failed'))),
        );
      });

      test('prints plain success path after ffmpeg succeeds', () async {
        final video = RedditVideo(
          posts: [post],
          videoType: RedditVideoType.post,
        );
        final subtitles = MockSubtitles();
        video.subtitles = subtitles;
        final cutVideo = File('${tempDir.path}/cut.mp4')..createSync();

        when(() => command.type).thenReturn(RedditVideoType.post);
        when(() => command.endCard).thenAnswer((_) async => null);
        when(() => command.music).thenReturn(null);
        when(() => command.verbose).thenReturn(false);
        when(() => command.override).thenReturn(false);
        when(() => command.horror).thenReturn(false);
        when(() => command.framerate).thenReturn(FPS.fps45);
        when(() => command.output).thenReturn('final.mp4');
        when(() => command.fileType).thenReturn(FileType.mp4);
        when(() => command.repeat).thenReturn(1);
        when(() => command.youtubeShort).thenReturn(false);

        when(() => backgroundVideo.position).thenReturn(0);
        when(() => subtitles.getTTSFilesAsInput()).thenReturn([]);
        when(() => subtitles.getTTSStream(any())).thenReturn(['[1:a]']);
        when(() => subtitles.assFile)
            .thenReturn(File('${tempDir.path}/sub.ass'));
        when(() => subtitles.duration).thenReturn(const Duration(seconds: 5));
        when(() => subtitles.position = any<int>()).thenReturn(0);

        Subprocess.setStartForTest((executable, arguments,
            {workingDirectory,
            environment,
            includeParentEnvironment = true,
            runInShell = false,
            mode = ProcessStartMode.normal}) async {
          return FakeProcess(exitCode: 0);
        });

        final stdoutBuffer = StringBuffer();
        logger.setOutputSinksForTest(stdoutSink: stdoutBuffer);

        await video.generate(command, backgroundVideo, cutVideo, 1);

        expect(
          stdoutBuffer.toString(),
          contains(
            'Video successfully generated: ${p.join(tempDir.path, 'final.mp4')}',
          ),
        );
        expect(stdoutBuffer.toString(), isNot(contains('[final.mp4](file://')));
      });
    });
  });
}
