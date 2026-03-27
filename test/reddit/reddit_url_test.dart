import 'dart:io';

import 'package:reddit_2_video/reddit/reddit_url.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('RedditUrl', () {
    group('constructor', () {
      test('stores id and subreddit', () {
        final url = RedditUrl(subreddit: 'AskReddit', id: 'abc123');
        expect(url.id, 'abc123');
      });

      test('generates correct getUri', () {
        final url = RedditUrl(subreddit: 'AskReddit', id: 'abc123');
        expect(url.getUri.toString(),
            'https://reddit.com/r/AskReddit/comments/abc123');
      });

      test('generates correct getJsonUri', () {
        final url = RedditUrl(subreddit: 'AskReddit', id: 'abc123');
        expect(url.getJsonUri.toString(),
            'https://reddit.com/r/AskReddit/comments/abc123.json');
      });

      test('toString returns expected format', () {
        final url = RedditUrl(subreddit: 'AskReddit', id: 'abc123');
        expect(url.toString(), 'reddit.com/r/AskReddit/comments/abc123');
      });
    });

    group('fromUrl', () {
      test('parses a valid reddit post URL', () {
        final url = RedditUrl.fromUrl(
            url: 'https://www.reddit.com/r/AskReddit/comments/abc123/title/');
        expect(url.id, 'abc123');
      });

      test('parses URL without trailing slash', () {
        final url = RedditUrl.fromUrl(
            url: 'https://www.reddit.com/r/AskReddit/comments/abc123/title');
        expect(url.id, 'abc123');
      });

      test('throws InvalidPostUrlException for URL without comments segment',
          () {
        expect(
          () => RedditUrl.fromUrl(
              url: 'https://www.reddit.com/r/AskReddit/'),
          throwsA(isA<InvalidPostUrlException>()),
        );
      });

      test('throws InvalidPostUrlException for empty path', () {
        expect(
          () => RedditUrl.fromUrl(url: 'https://reddit.com'),
          throwsA(isA<InvalidPostUrlException>()),
        );
      });
    });

    group('validLink', () {
      test('returns true for a valid reddit post url', () {
        expect(
          RedditUrl.validLink(
              'https://www.reddit.com/r/AskReddit/comments/abc123/title/'),
          true,
        );
      });

      test('returns false for a subreddit url', () {
        expect(
          RedditUrl.validLink('https://www.reddit.com/r/AskReddit/'),
          false,
        );
      });

      test('returns false for an arbitrary string', () {
        expect(RedditUrl.validLink('not_a_url'), false);
      });
    });
  });
}
