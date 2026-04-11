import 'dart:convert';
import 'dart:io';

import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/log/log.dart';
import 'package:reddit_2_video/reddit/reddit_id.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks.dart';

Map<String, dynamic> _logJson(List<Map<String, String>> entries) => {
      '_last_updated': '2025-01-01 00:00:00.000Z',
      'visited': entries,
    };

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('log_test_');
    AppPaths.initForTest(tempDir);
    Directory('${tempDir.path}/.temp').createSync();
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('Log.fromFile', () {
    test('creates log file with empty visited list if it does not exist',
        () async {
      await Log.fromFile();
      final logFile = AppPaths.resolve('.temp/visited_log.json');
      expect(logFile.existsSync(), isTrue);
      final json =
          jsonDecode(logFile.readAsStringSync()) as Map<String, dynamic>;
      expect(json['visited'], isEmpty);
      expect(json.containsKey('_last_updated'), isTrue);
    });

    test('parses existing entries from json', () async {
      final logFile = AppPaths.resolve('.temp/visited_log.json');
      logFile.writeAsStringSync(jsonEncode(_logJson([
        {'post_id': 'abc123', 'subreddit_id': 'AskReddit'},
      ])));

      final log = await Log.fromFile();

      final post = MockRedditPost();
      when(() => post.redditId).thenReturn(RedditId('abc123', 'AskReddit'));
      expect(log.contains(post), isTrue);
    });

    test('handles corrupt file gracefully and warns', () async {
      final logFile = AppPaths.resolve('.temp/visited_log.json');
      logFile.writeAsStringSync('not json {{}}');

      // Should not throw, starts with empty ids
      final log = await Log.fromFile();
      final post = MockRedditPost();
      when(() => post.redditId).thenReturn(RedditId('x', 'y'));
      expect(log.contains(post), isFalse);
    });
  });

  group('Log.add', () {
    test('persists entries with separate post_id and subreddit_id keys',
        () async {
      final log = await Log.fromFile();
      final video = MockRedditVideo();
      final post = MockRedditPost();
      when(() => post.redditId).thenReturn(RedditId('abc123', 'AskReddit'));
      when(() => video.posts).thenReturn([post]);

      log.add(video);

      final json = jsonDecode(
              AppPaths.resolve('.temp/visited_log.json').readAsStringSync())
          as Map<String, dynamic>;
      final visited = json['visited'] as List<dynamic>;
      expect(visited.length, 1);
      expect(visited.first['post_id'], 'abc123');
      expect(visited.first['subreddit_id'], 'AskReddit');
    });

    test('persists a single skipped post', () async {
      final log = await Log.fromFile();
      final post = MockRedditPost();
      when(() => post.redditId).thenReturn(RedditId('skip123', 'AskReddit'));

      log.addPost(post);

      final json = jsonDecode(
              AppPaths.resolve('.temp/visited_log.json').readAsStringSync())
          as Map<String, dynamic>;
      final visited = json['visited'] as List<dynamic>;
      expect(visited.length, 1);
      expect(visited.first['post_id'], 'skip123');
      expect(visited.first['subreddit_id'], 'AskReddit');
      expect(log.contains(post), isTrue);
    });
  });

  group('Log.remove', () {
    test('removes all entries when called with no post', () async {
      final logFile = AppPaths.resolve('.temp/visited_log.json');
      logFile.writeAsStringSync(jsonEncode(_logJson([
        {'post_id': 'abc123', 'subreddit_id': 'AskReddit'},
      ])));

      final log = await Log.fromFile();
      log.remove();

      final json =
          jsonDecode(logFile.readAsStringSync()) as Map<String, dynamic>;
      expect(json['visited'], isEmpty);
    });

    test('removes only the specified entry', () async {
      final logFile = AppPaths.resolve('.temp/visited_log.json');
      logFile.writeAsStringSync(jsonEncode(_logJson([
        {'post_id': 'abc123', 'subreddit_id': 'AskReddit'},
        {'post_id': 'xyz999', 'subreddit_id': 'videos'},
      ])));

      final log = await Log.fromFile();
      final post = MockRedditPost();
      when(() => post.redditId).thenReturn(RedditId('abc123', 'AskReddit'));
      log.remove(post: post);

      final json =
          jsonDecode(logFile.readAsStringSync()) as Map<String, dynamic>;
      final visited =
          (json['visited'] as List<dynamic>).cast<Map<String, dynamic>>();
      expect(visited.any((e) => e['post_id'] == 'abc123'), isFalse);
      expect(visited.any((e) => e['post_id'] == 'xyz999'), isTrue);
    });
  });

  group('temporaryAdd / clearTemporaryFiles', () {
    test('temporaryAdd makes contains return true before permanent add',
        () async {
      final log = await Log.fromFile();
      final video = MockRedditVideo();
      final post = MockRedditPost();
      when(() => post.redditId).thenReturn(RedditId('temp123', 'AskReddit'));
      when(() => video.posts).thenReturn([post]);

      log.temporaryAdd(video);

      expect(log.contains(post), isTrue);
    });

    test('clearTemporaryFiles removes non-protected temp entries', () async {
      final log = await Log.fromFile();
      final extraFile = AppPaths.resolve('.temp/temp.txt');
      extraFile.writeAsStringSync('x');
      final extraDir = AppPaths.resolveDir('.temp/temp_dir');
      extraDir.createSync(recursive: true);
      File('${extraDir.path}/a.txt').writeAsStringSync('x');

      await log.clearTemporaryFiles();

      expect(AppPaths.resolve('.temp/visited_log.json').existsSync(), isTrue);
      expect(extraFile.existsSync(), isFalse);
      expect(extraDir.existsSync(), isFalse);
    });
  });
}
