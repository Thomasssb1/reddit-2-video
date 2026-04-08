import 'dart:convert';
import 'dart:io';
import 'package:mp3_info/mp3_info.dart';

typedef SubtitleWord = ({
  String text,
  Duration start,
  Duration end,
});

class SubtitleConfig {
  static Duration Function(File file) _durationReader =
      (file) => MP3Processor.fromFile(file).duration;

  final File tts;
  late final List<SubtitleWord> words;

  SubtitleConfig.fromFile({
    required this.tts,
    required File configFile,
  }) {
    final rawConfig = configFile.readAsStringSync().trim();

    words = rawConfig.isNotEmpty ? _parseWords(rawConfig) : [];
  }

  SubtitleConfig.none() : tts = File('') {
    words = [];
  }

  List<SubtitleWord> _parseWords(String rawConfig) {
    final audioDuration = _durationReader(tts);
    final lines = rawConfig
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final parsedLines = lines
        .map((line) => Map<String, dynamic>.from(jsonDecode(line) as Map))
        .where((line) => line['type'] == 'word')
        .toList();

    final words = <SubtitleWord>[];
    for (int i = 0; i < parsedLines.length; i++) {
      final lineJson = parsedLines[i];
      final start = Duration(milliseconds: (lineJson['time'] as num).round());
      final end = i + 1 < parsedLines.length
          ? Duration(
              milliseconds: (parsedLines[i + 1]['time'] as num).round(),
            )
          : audioDuration;

      words.add((
        text: lineJson['value'] as String,
        start: start,
        end: end,
      ));
    }
    return words;
  }

  static void setDurationReaderForTest(Duration Function(File file) reader) {
    _durationReader = reader;
  }

  static void resetForTest() {
    _durationReader = (file) => MP3Processor.fromFile(file).duration;
  }
}
