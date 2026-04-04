import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
          () => RedditUrl.fromUrl(url: 'https://www.reddit.com/r/AskReddit/'),
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

    group('fromSubredditId', () {
      test('resolves subreddit from api response', () async {
        final client = MockClient((request) async {
          expect(request.url.toString(),
              'https://reddit.com/api/info.json?id=t5_test');
          return http.Response(
            jsonEncode({
              'data': {
                'children': [
                  {
                    'data': {'url': 'https://reddit.com/r/AskReddit/'}
                  }
                ]
              }
            }),
            200,
          );
        });

        final url = await RedditUrl.fromSubredditId(
          subredditId: 't5_test',
          id: 'abc123',
          client: client,
        );

        expect(url.getUri.toString(),
            'https://reddit.com/r/AskReddit/comments/abc123');
      });

      test('throws when api response is missing the subreddit url', () async {
        final client = MockClient(
          (_) async => http.Response(
              jsonEncode({
                'data': {'children': []}
              }),
              200),
        );

        await expectLater(
          () => RedditUrl.fromSubredditId(
            subredditId: 't5_test',
            id: 'abc123',
            client: client,
          ),
          throwsA(isA<RedditApiException>()),
        );
      });

      test('throws when api request fails', () async {
        final client = MockClient((_) async => http.Response('', 503));

        await expectLater(
          () => RedditUrl.fromSubredditId(
            subredditId: 't5_test',
            id: 'abc123',
            client: client,
          ),
          throwsA(
            isA<RedditApiException>().having(
              (e) => e.statusCode,
              'statusCode',
              503,
            ),
          ),
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

      test('returns true for url with fragment', () {
        expect(
          RedditUrl.validLink(
              'https://www.reddit.com/r/AskReddit/comments/abc123/title/#foo'),
          true,
        );
      });
    });
  });
}
