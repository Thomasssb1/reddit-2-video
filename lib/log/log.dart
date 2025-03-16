import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:reddit_2_video/exceptions/reddit_api_exception.dart';
import 'package:reddit_2_video/exceptions/warning.dart';
import 'package:reddit_2_video/post/reddit_post.dart';
import 'package:reddit_2_video/reddit_video.dart';

class Log {
  final File _logfile;
  late final HashSet<RedditPost> _urls;
  // Files within .temp to not delete
  final Iterable<String> _protectedFiles = <String>["visited_log.txt"];

  Log._fromFile({
    required File logfile,
    required HashSet<RedditPost> urls,
  })  : _logfile = logfile,
        _urls = urls;

  static Future<Log> fromFile(String prePath) async {
    File logfile = File("$prePath/.temp/visited_log.txt");
    if (!logfile.existsSync()) {
      logfile.createSync();
    }

    http.Client client = http.Client();

    List<RedditPost?> stream = await logfile
        .openRead()
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .asyncMap((line) async {
      String subredditId = line.split("-").last;
      String id = line.split("-").first;
      try {
        return await RedditPost.fromSubredditId(
            subredditId: subredditId, id: id, client: client);
      } on RedditApiException {
        Warning.warn("Unable to find post id $id in subreddit $subredditId.");
        return null;
      }
    }).toList();

    HashSet<RedditPost> lines = HashSet<RedditPost>();
    stream.where((e) => e != null).forEach((e) => lines.add(e!));
    client.close();

    return Log._fromFile(logfile: logfile, urls: lines);
  }

  bool contains(RedditPost post) {
    return _urls.contains(post);
  }

  Function(RedditPost post) _partialAdd(IOSink sink) {
    return (RedditPost post) => _add(post, sink);
  }

  void _add(RedditPost post, IOSink sink) {
    _urls.add(post);
    sink.writeln(post.id);
  }

  void add(RedditVideo video) async {
    IOSink sink = _logfile.openWrite(mode: FileMode.append);
    var partial = _partialAdd(sink);
    video.posts.forEach(partial);
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

  Future<void> clearTemporaryFiles() async {
    Directory tempDirectory = _logfile.parent;

    await tempDirectory
        .list()
        .where((e) => !_protectedFiles.contains(e.uri.pathSegments.last))
        .forEach((e) => e.deleteSync(recursive: true));
  }
}
