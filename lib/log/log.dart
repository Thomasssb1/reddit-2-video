import 'dart:async';
import 'dart:collection';

import 'package:reddit_2_video/post/reddit_url.dart';
import 'package:reddit_2_video/post/reddit_post.dart';
import 'dart:io';
import 'dart:convert';

class Log {
  final File _logfile;
  HashSet<RedditPost> _urls = HashSet<RedditPost>();

  Log._fromFile({
    required File logfile,
    required HashSet<RedditPost> urls,
  })  : _logfile = logfile,
        _urls = urls;

  static Future<Log> fromFile(
    File logfile,
  ) async {
    if (!logfile.existsSync()) {
      logfile.createSync();
    }
    Stream<RedditPost> stream = logfile
        .openRead()
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .map((line) => RedditPost(
            subreddit: line.split("-").last, id: line.split("-").first));
    HashSet<RedditPost> lines = HashSet<RedditPost>();
    try {
      await for (RedditPost line in stream) {
        lines.add(line);
      }
    } catch (e) {
      print(e);
    }

    return Log._fromFile(logfile: logfile, urls: lines);
  }

  bool contains(RedditPost post) {
    return _urls.contains(post);
  }

  void add(RedditPost post) async {
    _urls.add(post);
    IOSink sink = _logfile.openWrite();
    sink.writeln(post.id);
    await sink.flush();
    await sink.close();
  }

  void remove({RedditPost? post}) async {
    if (post == null) {
      _urls.clear();
      _logfile.writeAsStringSync('');
    } else {
      _urls.remove(post);
      final lines = await _logfile.readAsLines();
      lines.removeWhere((line) => line == post.id);
      await _logfile.writeAsString(lines.join('\n'));
    }
  }
}
