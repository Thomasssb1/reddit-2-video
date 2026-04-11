import 'dart:math';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:reddit_2_video/exceptions/reddit_api_exception.dart';

class RedditHttpRetry {
  static Future<http.Response> Function(Uri url) _get = http.get;
  static Future<void> Function(Duration duration) _waitForRetry = waitForRetry;
  static Future<void> Function(Duration duration) _delay = Future.delayed;

  static Future<void> waitForRetry(Duration duration) async {
    print(
        "The Reddit API requires ${duration.inSeconds}s in order to continue. Wait until available? ");
    String wait = stdin.readLineSync() ?? 'n';
    if (wait.toLowerCase() == 'y') {
      await Future.delayed(duration);
    } else {
      throw RedditApiException(
          message:
              "Maximum retries reached, please wait ${duration.inSeconds}s before retrying.",
          statusCode: 429);
    }
  }

  static Future<http.Response> retryHttp(Uri url, {int maxRetries = 5}) async {
    int retryCount = 0;
    while (retryCount < maxRetries) {
      http.Response response = await _get(url);
      if (response.statusCode == 200) {
        return response;
      } else if (response.statusCode == 429) {
        int remainingRequests =
            int.tryParse(response.headers['x-ratelimit-remaining'] ?? '') ?? -1;
        Duration resets = Duration(
            seconds:
                int.tryParse(response.headers['x-ratelimit-reset'] ?? '') ?? 0);
        if (remainingRequests == 0 && resets > Duration.zero) {
          await _waitForRetry(resets);
        }

        num waitTime = int.tryParse(response.headers['retry-after'] ?? '') ??
            pow(2, retryCount);
        await _delay(Duration(seconds: waitTime.ceil()));
        retryCount++;
      } else {
        throw RedditApiException(
            message: "Something went wrong when trying to find a new post.",
            statusCode: response.statusCode);
      }
    }
    throw RedditApiException(
        message:
            "Maximum retries reached. Posts cannot be requested, please wait before trying again.",
        statusCode: 429);
  }

  static void setGetForTest(Future<http.Response> Function(Uri url) handler) {
    _get = handler;
  }

  static void setWaitForRetryForTest(
      Future<void> Function(Duration duration) handler) {
    _waitForRetry = handler;
  }

  static void setDelayForTest(
      Future<void> Function(Duration duration) handler) {
    _delay = handler;
  }

  static void resetForTest() {
    _get = http.get;
    _waitForRetry = waitForRetry;
    _delay = Future.delayed;
  }
}
