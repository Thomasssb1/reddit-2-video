import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/config/background_video.dart';
import 'package:reddit_2_video/config/empty_noise.dart';
import 'package:reddit_2_video/config/end_card.dart';
import 'package:reddit_2_video/config/lexicons/lexica.dart';
import 'package:reddit_2_video/config/music.dart';
import 'package:reddit_2_video/reddit/reddit_post.dart';
import 'package:reddit_2_video/reddit_video.dart';
import 'package:reddit_2_video/subtitles/subtitles.dart';
import 'package:reddit_2_video/config/voices/voices.dart';

class MockRedditVideo extends Mock implements RedditVideo {}

class MockRedditPost extends Mock implements RedditPost {}

class MockBackgroundVideo extends Mock implements BackgroundVideo {}

class MockParsedCommand extends Mock implements ParsedCommand {}

class MockEndCard extends Mock implements EndCard {}

class MockFile extends Mock implements File {}

class MockLexica extends Mock implements Lexica {}

class MockSubtitles extends Mock implements Subtitles {}

class MockEmptyNoise extends Mock implements EmptyNoise {}

class MockMusic extends Mock implements Music {}

class MockVoices extends Mock implements Voices {}
