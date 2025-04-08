import 'dart:math';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:reddit_2_video/exceptions/reddit_api_exception.dart';

class RedditHttpRetry {
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
      print(url);
      http.Response response = await http.get(url);
      print(response.statusCode);
      if (response.statusCode == 200) {
        return response;
      } else if (response.statusCode == 429) {
        int remainingRequests =
            int.tryParse(response.headers['x-ratelimit-remaining'] ?? '') ?? -1;
        Duration resets = Duration(
            seconds:
                int.tryParse(response.headers['x-ratelimit-reset'] ?? '') ?? 0);
        if (remainingRequests == 0 && resets > Duration.zero) {
          waitForRetry(resets);
        }

        num waitTime = int.tryParse(response.headers['retry-after'] ?? '') ??
            pow(2, retryCount);
        await Future.delayed(Duration(seconds: waitTime.ceil()));
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
}
