import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/config/background_video.dart';
import 'package:reddit_2_video/config/end_card.dart';
import 'package:reddit_2_video/config/lexicons/lexica.dart';
import 'package:reddit_2_video/reddit/reddit_post.dart';
import 'package:reddit_2_video/reddit_video.dart';

class MockRedditVideo extends Mock implements RedditVideo {}

class MockRedditPost extends Mock implements RedditPost {}

class MockBackgroundVideo extends Mock implements BackgroundVideo {}

class MockParsedCommand extends Mock implements ParsedCommand {}

class MockEndCard extends Mock implements EndCard {}

class MockFile extends Mock implements File {}

class MockLexica extends Mock implements Lexica {}
