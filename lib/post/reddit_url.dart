import 'package:reddit_2_video/exceptions/exceptions.dart';

import 'package:deep_pick/deep_pick.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RedditUrl {
  static const String linkAuthority = "reddit.com";
  late final String _id;
  late final String _subreddit;

  RedditUrl({
    required String subreddit,
    required String id,
  })  : _subreddit = subreddit,
        _id = id;

  RedditUrl.fromUrl({
    required String url,
  }) {
    try {
      ({String id, String subreddit}) values =
          RedditUrl._extractIdAndSubreddit(url);
      _id = values.id;
      _subreddit = values.subreddit;
    } catch (e) {
      rethrow;
    }
  }

  static Future<RedditUrl> fromSubredditId({
    required String subredditId,
    required String id,
    required http.Client client,
  }) async {
    try {
      String subredditLink =
          await RedditUrl._extractSubredditUrl(subredditId, client);
      String subreddit =
          subredditLink.split("/").lastWhere((e) => e.isNotEmpty);
      return RedditUrl(subreddit: subreddit, id: id);
    } on RedditApiException {
      rethrow;
    }
  }

  static ({String id, String subreddit}) _extractIdAndSubreddit(String url) {
    try {
      Uri uri = Uri.parse(url).removeFragment();
      List<String> paths = uri.pathSegments;
      if (paths.isNotEmpty) {
        if (paths.last == '') {
          paths = paths.sublist(0, paths.length - 1);
        }
        // the position of the "comments" path segment in the url
        int commentStringIndex = paths.indexOf('comments');
        if (commentStringIndex == -1) {
          throw InvalidPostUrlException(
              "The link that you have provided along with the --subreddit arg is not a proper link that links directly to a reddit post. Re-run the command but instead with a reddit link that links directly to the reddit post.",
              url);
        } else {
          // TODO: add id verification, i.e. could be any string right now not a valid post id
          return (
            id: paths[commentStringIndex + 1],
            subreddit: paths[commentStringIndex - 1]
          );
        }
      } else {
        throw InvalidPostUrlException(
            "Unable to use the link you have provided along with the --subreddit arg, ensure that you are using a link that links directly to the reddit post.",
            url);
      }
    } on FormatException {
      throw InvalidPostUrlException(
          "The url provided does not have a valid url scheme", url);
    }
  }

  static Future<String> _extractSubredditUrl(
      String subredditId, http.Client redditClient) async {
    // Try to use the api to get the url
    http.Request request = http.Request(
        'GET', Uri.https("reddit.com", "/api/info.json", {"id": subredditId}));
    http.StreamedResponse response = await redditClient.send(request);
    if (response.statusCode == 200) {
      try {
        var body = await response.stream.toBytes();
        var json = jsonDecode(utf8.decode(body));
        return pick(json, "data", "children", 0, "data", "url")
            .asStringOrThrow();
      } on PickException {
        throw RedditApiException(
            message: "Unable to find subreddit url from subreddit id",
            statusCode: response.statusCode);
      }
    } else {
      throw RedditApiException(
          message: "Unable to find subreddit url from subreddit id",
          statusCode: response.statusCode);
    }
  }

  static bool validLink(String url) {
    try {
      RedditUrl.fromUrl(url: url);
    } catch (e) {
      return false;
    }
    return true;
  }

  void checkId() {
    // TODO: implement
    // Checks if the id is valid within the url
  }

  Uri get getUri => Uri.https(linkAuthority, "/r/$_subreddit/comments/$_id");
  Uri get getJsonUri =>
      Uri.https(linkAuthority, "/r/$_subreddit/comments/$_id.json");
  String get id => _id;

  @override
  String toString() {
    return "$linkAuthority/r/$_subreddit/comments/$_id";
  }
}
