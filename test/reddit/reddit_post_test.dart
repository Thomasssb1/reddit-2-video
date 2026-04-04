import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/reddit/reddit_comment_sort_type.dart';
import 'package:reddit_2_video/reddit/reddit_http_retry.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:reddit_2_video/reddit/reddit_post.dart';

import '../mocks.dart';

Map<String, dynamic> _postData({
  String title = 'My husband is cheating on me with our best friend',
  String body =
      'My ex husband and my ex best friend as no surprise are now in an actual relationship after the ex best friend’s husband found out about the affair.',
  String id = '1850nn6',
  String subreddit = 'TrueOffMyChest',
  String subredditId = 't5_2yuqy',
}) =>
    {
      'subreddit': subreddit,
      'subreddit_id': subredditId,
      'title': title,
      'selftext': body,
      'id': id,
      'ups': 123,
      'created_utc': 1701083780,
      'spoiler': false,
      'stickied': false,
      'over_18': false,
      'media': false,
      'num_comments': 10,
    };

void main() {
  tearDown(() {
    RedditHttpRetry.resetForTest();
  });

  group("RedditPost constructor", () {
    test("from url", () async {
      RedditHttpRetry.setGetForTest((url) async {
        expect(
          url.toString(),
          'https://reddit.com/r/TrueOffMyChest/comments/1850nn6.json',
        );
        return http.Response.bytes(
          utf8.encode(jsonEncode([
            {
              'data': {
                'children': [
                  {'data': _postData()}
                ]
              }
            }
          ])),
          200,
        );
      });

      RedditPost post = await RedditPost.fromUrl(
        url:
            "https://www.reddit.com/r/TrueOffMyChest/comments/1850nn6/my_husband_is_cheating_on_me_with_our_best_friend/",
      );
      expect(post.title, "My husband is cheating on me with our best friend");
      expect(
          post.body,
          contains(
              "My ex husband and my ex best friend as no surprise are now in an actual relationship after the ex best friend’s husband found out about the affair."));
      expect(post.id, "1850nn6-t5_2yuqy");
      expect(post.subreddit, "TrueOffMyChest");
      expect(post.subredditId, "t5_2yuqy");
      expect(
          post.created,
          DateTime.fromMillisecondsSinceEpoch(
              Duration(seconds: 1701083780).inMilliseconds));
      expect(post.nsfw, false);
      expect(post.spoiler, false);
      expect(post.stickied, false);
      expect(post.hasMedia, false);
      expect(post.wrapBody(limit: 4), 'My e...');
      expect(post.toString(), contains('Title: My husband is cheating'));
    });

    test("from id", () async {
      Pick json = Pick({
        "subreddit": "TrueOffMyChest",
        "subreddit_id": "t5_2yuqy",
        "title": "My husband is cheating on me with our best friend",
        "selftext":
            "My ex husband and my ex best friend as no surprise are now in an actual relationship after the ex best friend’s husband found out about the affair.",
        "id": "1850nn6",
        "created_utc": 1701083780,
        "spoiler": false,
        "stickied": false,
        "over_18": false,
        "media": null,
        "comment_count": 0,
      });
      RedditPost post =
          RedditPost.fromId(subreddit: "t5_2yuqy", id: "1850nn6", json: json);
      expect(post.title, "My husband is cheating on me with our best friend");
      expect(post.body,
          "My ex husband and my ex best friend as no surprise are now in an actual relationship after the ex best friend’s husband found out about the affair.");
      expect(post.id, "1850nn6-t5_2yuqy");
      expect(post.subreddit, "TrueOffMyChest");
      expect(post.subredditId, "t5_2yuqy");
      expect(
          post.created,
          DateTime.fromMillisecondsSinceEpoch(
              Duration(seconds: 1701083780).inMilliseconds));
      expect(post.nsfw, false);
      expect(post.spoiler, false);
      expect(post.stickied, false);
      expect(post.hasMedia, false);
      expect(post.commentCount, 0);
    });

    test('throws when response body is empty', () async {
      RedditHttpRetry.setGetForTest((url) async => http.Response('', 200));

      await expectLater(
        () => RedditPost.fromUrl(
          url: 'https://reddit.com/r/test/comments/abc123/title/',
        ),
        throwsA(isA<RedditApiException>()),
      );
    });

    test('throws when json structure is invalid', () async {
      RedditHttpRetry.setGetForTest(
        (url) async => http.Response(jsonEncode([{}]), 200),
      );

      await expectLater(
        () => RedditPost.fromUrl(
          url: 'https://reddit.com/r/test/comments/abc123/title/',
        ),
        throwsA(isA<RedditApiException>()),
      );
    });

    test('fromSubredditId resolves through RedditUrl api client', () async {
      final client = MockClient((request) async {
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
      RedditHttpRetry.setGetForTest((url) async {
        expect(
          url.toString(),
          'https://reddit.com/r/AskReddit/comments/abc123.json',
        );
        return http.Response.bytes(
          utf8.encode(jsonEncode([
            {
              'data': {
                'children': [
                  {
                    'data': _postData(
                      id: 'abc123',
                      subreddit: 'AskReddit',
                      subredditId: 't5_2qh1i',
                    ),
                  }
                ]
              }
            }
          ])),
          200,
        );
      });

      final post = await RedditPost.fromSubredditId(
        subredditId: 't5_2qh1i',
        id: 'abc123',
        client: client,
      );

      expect(post.subreddit, 'AskReddit');
      expect(post.id, 'abc123-t5_2qh1i');
    });

    test('addComments keeps only valid non-removed comments up to count',
        () async {
      final command = MockParsedCommand();
      when(() => command.commentSort).thenReturn(RedditCommentSortType.best);
      when(() => command.commentCount).thenReturn(1);

      final post = RedditPost.fromId(
        subreddit: 'TrueOffMyChest',
        id: '1850nn6',
        json: Pick(_postData()),
      );

      RedditHttpRetry.setGetForTest((url) async {
        return http.Response(
          jsonEncode([
            {},
            {
              'data': {
                'children': [
                  {
                    'data': {
                      'author': 'user1',
                      'body':
                          'This comment is long enough to survive filtering.',
                      'created': 1701083780,
                      'ups': 15,
                    }
                  },
                  {
                    'data': {
                      'author': 'user2',
                      'body': '[removed]',
                      'created': 1701083781,
                      'ups': 8,
                    }
                  },
                  {
                    'data': {
                      'author': 'user3',
                      'body': 'too short',
                      'created': 1701083782,
                      'ups': 3,
                    }
                  }
                ]
              }
            }
          ]),
          200,
        );
      });

      await post.addComments(command);

      expect(post.comments, hasLength(1));
      expect(post.comments.single.author, 'user1');
    });

    test('addComments throws when request fails', () async {
      final command = MockParsedCommand();
      when(() => command.commentSort).thenReturn(RedditCommentSortType.best);
      when(() => command.commentCount).thenReturn(1);

      final post = RedditPost.fromId(
        subreddit: 'TrueOffMyChest',
        id: '1850nn6',
        json: Pick(_postData()),
      );

      RedditHttpRetry.setGetForTest((url) async => http.Response('', 503));

      await expectLater(
        () => post.addComments(command),
        throwsA(isA<RedditApiException>()),
      );
    });

    test('equality compares posts by id', () {
      final first = RedditPost.fromId(
        subreddit: 'TrueOffMyChest',
        id: '1850nn6',
        json: Pick(_postData(title: 'first')),
      );
      final second = RedditPost.fromId(
        subreddit: 'TrueOffMyChest',
        id: '1850nn6',
        json: Pick(_postData(title: 'second')),
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });
}
