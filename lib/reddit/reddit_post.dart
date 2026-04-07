import 'package:deep_pick/deep_pick.dart';
import 'package:http/http.dart' as http;
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/reddit/reddit_comment_sort_type.dart';
import 'package:reddit_2_video/reddit/reddit_id.dart';
import 'package:reddit_2_video/reddit/reddit_http_retry.dart';
import 'dart:convert';
import 'reddit_url.dart';
import 'reddit_comment.dart';
import 'package:reddit_2_video/command/parsed_command.dart';

class RedditPost {
  late final RedditUrl _url;
  late final RedditId _id;

  late final String _title;
  late final String _body;
  String? _subreddit;
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

  RedditPost.url({
    required String url,
  }) : _url = RedditUrl.fromUrl(url: url);

  RedditPost({
    required String subreddit,
    required String id,
  }) : _url = RedditUrl(subreddit: subreddit, id: id);

  static Future<RedditPost> fromUrl({
    required String url,
  }) async {
    RedditPost post = RedditPost.url(url: url);
    try {
      await post._fillAttributes();
    } catch (e) {
      rethrow;
    }
    return post;
  }

  static RedditPost fromId({
    required String subreddit,
    required String id,
    required Pick json,
  }) {
    RedditPost post = RedditPost(subreddit: subreddit, id: id);
    try {
      post._setJsonAttributes(json);
    } catch (e) {
      rethrow;
    }
    return post;
  }

  static Future<RedditPost> fromSubredditId({
    required String subredditId,
    required String id,
    required http.Client client,
  }) async {
    try {
      RedditUrl url = await RedditUrl.fromSubredditId(
          subredditId: subredditId, id: id, client: client);
      return await RedditPost.fromUrl(url: url.toString());
    } on RedditApiException {
      rethrow;
    }
  }

  Future<void> addComments(ParsedCommand command) async {
    http.Response response = await RedditHttpRetry.retryHttp(Uri.https(
        url.authority, "${url.path}.json", {"sort": command.commentSort.name}));

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
          .where((comment) => comment.body.length >= 32 && !comment.isRemoved())
          .toList();

      this.comments = comments.sublist(
          0,
          comments.length < command.commentCount
              ? comments.length
              : command.commentCount);
    } else {
      throw RedditApiException(
          message:
              "An error occurred whilst trying to fetch the subreddit data. Try again later.",
          statusCode: response.statusCode);
    }
  }

  void _setJsonAttributes(Pick pick) {
    try {
      _subreddit = pick('subreddit').asStringOrNull() ?? "Unknown";
      _stickied = pick('stickied').asBoolOrFalse();
      _commentCount = pick('num_comments').asIntOrNull() ?? 0;
      _title = pick('title').asStringOrNull() ?? "Unknown";
      _subredditId = pick('subreddit_id').asStringOrThrow();
      _id = RedditId(pick('id').asStringOrThrow(), _subredditId);
      _body = pick('selftext').asStringOrNull() ?? "";
      _upvotes = pick('ups').asIntOrNull() ?? 0;
      _created = DateTime.fromMillisecondsSinceEpoch(
          ((pick('created_utc').asDoubleOrNull() ?? 0.0) * 1000).round());
      _spoiler = pick('spoiler').asBoolOrFalse();
      _hasMedia = pick('media').asBoolOrFalse();
      _nsfw = pick('over_18').asBoolOrFalse();
    } on PickException {
      String reason = pick('reason').asStringOrNull() ?? "unknown";
      throw RedditApiException(
          message: "Unable to get information for post $_url - reason: $reason",
          statusCode: 200);
    }
  }

  Future<void> _fillAttributes() async {
    http.Response response = await RedditHttpRetry.retryHttp(_url.getJsonUri);
    // check if 200 OK
    if (response.body.isEmpty) {
      throw RedditApiException(
          message:
              "An error occurred whilst trying to fetch the subreddit data. Returned empty response body.",
          statusCode: response.statusCode);
    }
    var json = jsonDecode(utf8.decode(response.bodyBytes));
    Pick p0 = pick(json[0], 'data', 'children', 0, 'data');
    _setJsonAttributes(p0);
  }

  String wrapBody({int limit = 30}) {
    if (body.length < limit) {
      limit = body.length;
    }
    return "${body.substring(0, limit)}...";
  }

  // post attributes
  Uri get url => _url.getUri;
  String get title => _title;
  String get body => _body;
  String get subreddit => _subreddit!;
  String get subredditId => _subredditId;
  int get upvotes => _upvotes;
  DateTime get created => _created;
  bool get spoiler => _spoiler;
  bool get nsfw => _nsfw;
  bool get stickied => _stickied;
  bool get over18 => _over18;
  bool get hasMedia => _hasMedia;
  int get commentCount => _commentCount;

  String get id => _id.toString();
  RedditId get redditId => _id;
  RedditCommentSortType get commentSortType => _commentSortType;

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.writeln("Url: $url");
    sb.writeln("Title: $title");
    sb.writeln("Body: ${wrapBody()}");
    sb.writeln("Subreddit: $subreddit, Upvotes: $upvotes, Created: $created");
    return sb.toString();
  }

  @override
  bool operator ==(Object other) {
    if (other is! RedditPost) {
      return false;
    }
    return id == other.id;
  }

  @override
  int get hashCode => Object.hash(_url.id, _subredditId);
}
