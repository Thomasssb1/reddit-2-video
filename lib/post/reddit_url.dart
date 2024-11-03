import 'package:reddit_2_video/exceptions/invalid_post_url_exception.dart';

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
      ({String id, String subreddit}) values = extractIdAndSubreddit(url);
      _id = values.id;
      _subreddit = values.subreddit;
    } catch (e) {
      rethrow;
    }
  }

  ({String id, String subreddit}) extractIdAndSubreddit(String url) {
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
