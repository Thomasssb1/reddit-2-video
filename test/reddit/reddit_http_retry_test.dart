import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:reddit_2_video/exceptions/reddit_api_exception.dart';
import 'package:reddit_2_video/reddit/reddit_http_retry.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() {
    RedditHttpRetry.resetForTest();
  });

  group('RedditHttpRetry.retryHttp', () {
    test('returns immediately on first successful response', () async {
      var calls = 0;
      RedditHttpRetry.setGetForTest((url) async {
        calls++;
        return http.Response('ok', 200);
      });

      final response =
          await RedditHttpRetry.retryHttp(Uri.https('reddit.com', '/test'));

      expect(response.statusCode, 200);
      expect(calls, 1);
    });

    test('retries after 429 and succeeds on a later attempt', () async {
      var calls = 0;
      final delays = <Duration>[];
      RedditHttpRetry.setDelayForTest((duration) async {
        delays.add(duration);
      });
      RedditHttpRetry.setGetForTest((url) async {
        calls++;
        if (calls == 1) {
          return http.Response('', 429, headers: {'retry-after': '2'});
        }
        return http.Response('ok', 200);
      });

      final response =
          await RedditHttpRetry.retryHttp(Uri.https('reddit.com', '/test'));

      expect(response.statusCode, 200);
      expect(calls, 2);
      expect(delays, [Duration(seconds: 2)]);
    });

    test(
        'waits for retry metadata before continuing and throws after maximum retry',
        () async {
      final waits = <Duration>[];
      final delays = <Duration>[];
      final waitCompleter = Completer<void>();

      RedditHttpRetry.setWaitForRetryForTest((duration) async {
        waits.add(duration);
        await waitCompleter.future;
      });
      RedditHttpRetry.setDelayForTest((duration) async {
        delays.add(duration);
      });
      RedditHttpRetry.setGetForTest((url) async {
        return http.Response('', 429, headers: {
          'x-ratelimit-remaining': '0',
          'x-ratelimit-reset': '3',
          'retry-after': '1',
        });
      });

      var completed = false;
      final future = RedditHttpRetry.retryHttp(
        Uri.https('reddit.com', '/test'),
        maxRetries: 1,
      ).whenComplete(() {
        completed = true;
      });

      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      expect(waits, [Duration(seconds: 3)]);
      expect(delays, isEmpty);

      waitCompleter.complete();

      await expectLater(
        future,
        throwsA(
          isA<RedditApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            429,
          ),
        ),
      );
      expect(delays, [Duration(seconds: 1)]);
    });

    test('throws for non-retriable status codes', () async {
      RedditHttpRetry.setGetForTest((url) async => http.Response('', 500));

      await expectLater(
        () => RedditHttpRetry.retryHttp(Uri.https('reddit.com', '/test')),
        throwsA(
          isA<RedditApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });
  });
}
