import 'package:reddit_2_video/reddit/reddit_comment.dart';
import 'package:reddit_2_video/reddit/reddit_comment_sort_type.dart';
import 'package:reddit_2_video/reddit/reddit_id.dart';
import 'package:reddit_2_video/reddit/reddit_post_sort_type.dart';
import 'package:reddit_2_video/reddit/reddit_video_type.dart';
import 'package:test/test.dart';

void main() {
  group('RedditComment', () {
    test('marks removed comments correctly', () {
      final removed = RedditComment(
        author: 'a',
        body: '[removed]',
        created: DateTime(2024),
        upvotes: 1,
        collapsedReason: null,
      );
      final deleted = RedditComment(
        author: 'a',
        body: 'text',
        created: DateTime(2024),
        upvotes: 1,
        collapsedReason: 'DELETED',
      );

      expect(removed.isRemoved(), isTrue);
      expect(deleted.isRemoved(), isTrue);
    });

    test('wrapBody truncates and toString includes summary fields', () {
      final comment = RedditComment(
        author: 'author',
        body: 'abcdefghijklmnopqrstuvwxyz',
        created: DateTime(2024),
        upvotes: 42,
        collapsedReason: null,
      );

      expect(comment.wrapBody(limit: 5), 'abcde...');
      expect(comment.toString(), contains('Author: author'));
      expect(comment.toString(), contains('Upvotes: 42'));
    });
  });

  group('RedditId', () {
    test('compares equality by composed id', () {
      expect(const RedditId('abc', 't5_x'), const RedditId('abc', 't5_x'));
      expect(const RedditId('abc', 't5_x').toString(), 'abc-t5_x');
    });
  });

  group('RedditCommentSortType', () {
    test('maps names correctly', () {
      expect(RedditCommentSortType.called('best'), RedditCommentSortType.best);
      expect(RedditCommentSortType.called('new'), RedditCommentSortType.newest);
      expect(RedditCommentSortType.called('q&a'), RedditCommentSortType.qanda);
      expect(RedditCommentSortType.called('missing'), isNull);
    });
  });

  group('RedditPostSortType', () {
    test('maps names correctly', () {
      expect(RedditPostSortType.called('top'), RedditPostSortType.top);
      expect(RedditPostSortType.called('new'), RedditPostSortType.newest);
      expect(RedditPostSortType.called('missing'), isNull);
    });
  });

  group('RedditVideoType', () {
    test('maps names correctly', () {
      expect(RedditVideoType.called('multi'), RedditVideoType.multi);
      expect(RedditVideoType.called('post'), RedditVideoType.post);
      expect(RedditVideoType.called('comments'), RedditVideoType.comments);
      expect(RedditVideoType.called('missing'), isNull);
    });
  });
}
