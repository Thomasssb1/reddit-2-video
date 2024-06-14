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
      Uri uri = Uri.parse(url).removeFragment();
      List<String> paths = uri.pathSegments;
      if (paths.isNotEmpty) {
        if (paths.last == '') {
          paths = paths.sublist(0, paths.length - 1);
        }
        if (paths.length == 5 &&
            uri.host == 'www.reddit.com' &&
            paths[0] == 'r' &&
            paths[2] == 'comments') {
          // no id verification, i.e. could be any string not a valid id
          _id = paths.last.replaceFirst(".json", "");
        } else {
          throw InvalidPostUrlException(
              "The link that you have provided along with the --subreddit arg is not a proper link that links directly to a reddit post. Re-run the command but instead with a reddit link that links directly to the reddit post.",
              url);
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

  void checkId() {
    // TODO: implement
    // Checks if the id is valid within the url
  }

  Uri get getUri => Uri.https("$linkAuthority/r/$_subreddit/comments/$_id");

  @override
  String toString() {
    return "$linkAuthority/r/$_subreddit/comments/$_id";
  }
}
