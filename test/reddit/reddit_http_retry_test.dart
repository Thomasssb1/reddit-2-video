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

    test('uses waitForRetry when rate limit reset metadata is present',
        () async {
      final waits = <Duration>[];
      final delays = <Duration>[];
      var calls = 0;

      RedditHttpRetry.setWaitForRetryForTest((duration) async {
        waits.add(duration);
      });
      RedditHttpRetry.setDelayForTest((duration) async {
        delays.add(duration);
      });
      RedditHttpRetry.setGetForTest((url) async {
        calls++;
        if (calls == 1) {
          return http.Response('', 429, headers: {
            'x-ratelimit-remaining': '0',
            'x-ratelimit-reset': '3',
            'retry-after': '1',
          });
        }
        return http.Response('ok', 200);
      });

      await RedditHttpRetry.retryHttp(Uri.https('reddit.com', '/test'));

      expect(waits, [Duration(seconds: 3)]);
      expect(delays, [Duration(seconds: 1)]);
    });

    test('throws after max retries are exhausted', () async {
      RedditHttpRetry.setDelayForTest((duration) async {});
      RedditHttpRetry.setGetForTest(
          (url) async => http.Response('', 429, headers: {'retry-after': '1'}));

      await expectLater(
        () => RedditHttpRetry.retryHttp(
          Uri.https('reddit.com', '/test'),
          maxRetries: 2,
        ),
        throwsA(
          isA<RedditApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            429,
          ),
        ),
      );
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
