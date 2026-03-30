import 'dart:io';

import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/reddit_video.dart';
import 'package:reddit_2_video/reddit/reddit_video_type.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

void main() {
  late Directory tempDir;
  late MockRedditPost post;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('reddit_video_test_');
    AppPaths.initForTest(tempDir);
    post = MockRedditPost();
    when(() => post.id).thenReturn('abc123');
    when(() => post.comments).thenReturn([]);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('RedditVideo', () {
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
  });
}
