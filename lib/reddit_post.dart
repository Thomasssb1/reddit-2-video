import 'package:deep_pick/deep_pick.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'utils/reddit_url.dart';

enum RedditVideoType {
  multi,
  post,
  comments,
}

class RedditPost {
  final RedditVideoType videoType;
  final RedditUrl url;

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

  // TODO: Implement a way to store comments
  late final int _commentCount;

  RedditPost.fromUrl({
    required String url,
    required this.videoType,
  }) : url = RedditUrl.fromUrl(url: url) {
    _fillAttributes();
  }

  RedditPost({
    required String subreddit,
    required String id,
    required this.videoType,
  })  : _subreddit = subreddit,
        url = RedditUrl(subreddit: subreddit, id: id) {
    _fillAttributes();
  }

  void _fillAttributes() async {
    var response = await http.get(url.getUri);
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
}
