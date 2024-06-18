import 'package:deep_pick/deep_pick.dart';
import 'package:http/http.dart' as http;
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/exceptions/post_already_generated_exception.dart';
import 'package:reddit_2_video/exceptions/posts_exhausted_exception.dart';
import 'package:reddit_2_video/post/reddit_comment_sort_type.dart';
import 'package:reddit_2_video/post/reddit_post_sort_type.dart';
import 'package:reddit_2_video/reddit_video.dart';
import 'dart:convert';
import 'reddit_url.dart';
import 'reddit_video_type.dart';
import 'reddit_comment.dart';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class RedditPost {
  final RedditUrl _url;

  late final String _title;
  late final String _body;
  late final String _subreddit;
  late final String _subredditId;
  late final int _upvotes;
  late final DateTime _created;

  late final bool _spoiler;
  late final bool _nsfw;
  // Posts which are stickied are usually announcements or important
  late final bool _stickied;
  late final bool _over18;
  late final bool _hasMedia;
  late final int _commentCount;

  late final RedditCommentSortType _commentSortType;
  List<RedditComment> comments = [];

  RedditPost.fromUrl({
    required String url,
  }) : _url = RedditUrl.fromUrl(url: url) {
    _fillAttributes();
  }

  RedditPost({
    required String subreddit,
    required String id,
  })  : _subreddit = subreddit,
        _url = RedditUrl(subreddit: subreddit, id: id) {
    _fillAttributes();
  }

  void addComments(ParsedCommand command) async {
    http.Response response = await http
        .get(Uri.https(url.authority, url.path, {"sort": command.sort.name}));

    if (response.statusCode == 200) {
      var json = jsonDecode(utf8.decode(response.bodyBytes));
      List<RedditComment> comments = pick(json, 1, 'data', 'children')
          .asListOrEmpty<RedditComment?>((p0) {
            try {
              return RedditComment(
                  author: p0('data', 'author').asStringOrNull() ?? "Anonymous",
                  body: p0('data', 'body').required().asString(),
                  created: p0('data', 'created').letOrNull((pick) =>
                          DateTime.fromMillisecondsSinceEpoch(
                              ((pick.asDoubleOrNull() ?? 0.0) * 1000)
                                  .round())) ??
                      DateTime.now(),
                  upvotes: p0('data', 'ups').asIntOrNull() ?? 0,
                  collapsedReason:
                      p0('data', 'collapsed_reason').asStringOrNull());
            } on PickException {
              return null;
            }
          })
          .whereType<RedditComment>()
          .where((comment) => comment.body.length <= 32 && !comment.isRemoved())
          .toList();

      comments = comments.sublist(
          0,
          comments.length < 3 * command.commentCount
              ? comments.length
              : 3 * command.commentCount);
    } else {
      throw RedditApiException(
          message:
              "An error occurred whilst trying to fetch the subreddit data. Try again later.",
          statusCode: response.statusCode);
    }
  }

  void generateFiles() {
    // generate relevant files
  }

  void _fillAttributes() async {
    var response = await http.get(_url.getUri);
    // check if 200 OK
    var json = jsonDecode(response.body);
    pick(json[0], 'data', 'children', 0, 'data').asListOrEmpty((p0) {
      _stickied = p0('stickied').asBoolOrFalse();
      _commentCount = p0('num_comments').asIntOrNull() ?? 0;
      _title = p0('title').required().asString();
      _subreddit = p0('subreddit').required().asString();
      _subredditId = p0('subreddit_id').required().asString();
      _body = p0('selftext').required().asString();
      _upvotes = p0('ups').asIntOrNull() ?? 0;
      _created = p0('created').letOrNull((pick) =>
              DateTime.fromMillisecondsSinceEpoch(
                  ((pick.asDoubleOrNull() ?? 0.0) * 1000).round())) ??
          DateTime.now();
      _spoiler = p0('spoiler').asBoolOrFalse();
      _hasMedia = p0('media').asBoolOrFalse();
      _nsfw = p0('over_18').asBoolOrFalse();
    });
  }

  // post attributes
  Uri get url => _url.getUri;
  String get title => _title;
  String get body => _body;
  String get subreddit => _subreddit;
  String get subredditId => _subredditId;
  int get upvotes => _upvotes;
  DateTime get created => _created;
  bool get spoiler => _spoiler;
  bool get nsfw => _nsfw;
  bool get stickied => _stickied;
  bool get over18 => _over18;
  bool get hasMedia => _hasMedia;
  int get commentCount => _commentCount;

  String get id => "${_url.id}-$subredditId";
  RedditCommentSortType get commentSortType => _commentSortType;
}
