import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/reddit/reddit_id.dart';
import 'package:reddit_2_video/reddit/reddit_post.dart';
import 'package:reddit_2_video/reddit_video.dart';
import 'package:reddit_2_video/utils/logger.dart';

class Log {
  final File _logfile;
  late final HashSet<RedditId> _ids;
  // Files within .temp to not delete
  final Iterable<String> _protectedFiles = <String>["visited_log.json"];
  // Temporary posts to ignore
  final HashSet<RedditId> _tempIds = HashSet();

  Log._fromFile({
    required File logfile,
    required HashSet<RedditId> ids,
  })  : _logfile = logfile,
        _ids = ids;

  static Future<Log> fromFile() async {
    logger.info("Loading visited log.", section: LogSection.setup);
    File logfile = AppPaths.resolve('.temp/visited_log.json');
    if (!logfile.existsSync()) {
      logfile.createSync(recursive: true);
      logfile.writeAsStringSync(_emptyJson());
    }

    final raw = logfile.readAsStringSync();
    final HashSet<RedditId> ids = HashSet();

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final visited = (json['visited'] as List<dynamic>?) ?? [];
      for (final entry in visited) {
        final map = entry as Map<String, dynamic>;
        final postId = map['post_id'] as String?;
        final subredditId = map['subreddit_id'] as String?;
        if (postId != null && subredditId != null) {
          ids.add(RedditId(postId, subredditId));
        }
      }
    } on FormatException {
      logger.warning(
          'visited_log.json is corrupt or empty — starting with a fresh log.');
    }

    return Log._fromFile(logfile: logfile, ids: ids);
  }

  bool contains(RedditPost post) {
    return _ids.contains(post.redditId) || _tempIds.contains(post.redditId);
  }

  void temporaryAdd(RedditVideo video) {
    _tempIds.addAll(video.posts.map((e) => e.redditId));
  }

  void add(RedditVideo video) {
    for (final post in video.posts) {
      _tempIds.remove(post.redditId);
      _ids.add(post.redditId);
    }
    _flush();
  }

  void remove({RedditPost? post}) {
    if (post == null) {
      _ids.clear();
    } else {
      _ids.remove(post.redditId);
    }
    _flush();
  }

  void _flush() {
    _logfile.writeAsStringSync(_encode(_ids));
  }

  static String _emptyJson() => _encode(HashSet());

  static String _encode(HashSet<RedditId> ids) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({
      '_last_updated': DateTime.now().toUtc().toString(),
      'visited': ids
          .map((e) => {'post_id': e.postId, 'subreddit_id': e.subredditId})
          .toList(),
    });
  }

  Future<void> clearTemporaryFiles() async {
    Directory tempDirectory = _logfile.parent;

    await tempDirectory
        .list()
        .where((e) => !_protectedFiles.contains(e.uri.pathSegments.last))
        .forEach((e) => e.deleteSync(recursive: true));
  }
}
