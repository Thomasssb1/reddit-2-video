import 'dart:convert';
import 'dart:io';

class SubtitleConfig {
  final File tts;
  late final segments;

  SubtitleConfig.fromFile({
    required this.tts,
    required File configFile,
  }) {
    final json = jsonDecode(configFile.readAsStringSync());
    segments = json['segments'];
  }

  SubtitleConfig.none() : tts = File('') {
    segments = {};
  }
}
