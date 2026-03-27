import 'dart:io';

import 'package:reddit_2_video/reddit_video.dart';
import 'package:reddit_2_video/reddit/reddit_post.dart';
import 'package:reddit_2_video/reddit/reddit_video_type.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

void main() {
  final tempPath = '${Directory.current.path}/.temp_test';

  late MockRedditPost post;

  setUp(() {
    post = MockRedditPost();
    when(() => post.id).thenReturn('abc123');
    when(() => post.comments).thenReturn([]);
  });

  tearDown(() {
    // Clean up temp directories created by the tests
    final dir = Directory('$tempPath/.temp');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  group('RedditVideo', () {
    group('id', () {
      test('returns single post id', () {
        final video = RedditVideo(
          posts: [post],
          videoType: RedditVideoType.post,
          prePath: tempPath,
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
          prePath: tempPath,
        );
        expect(video.id, 'aaa-bbb');
      });
    });

    group('RedditVideo.single', () {
      test('wraps single post in list of length 1', () {
        final video = RedditVideo.single(
          post: post,
          videoType: RedditVideoType.post,
          prePath: tempPath,
        );
        expect(video.posts.length, 1);
        expect(video.id, 'abc123');
      });
    });
  });
}
