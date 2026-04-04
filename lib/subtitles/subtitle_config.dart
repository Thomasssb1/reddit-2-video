import 'dart:convert';
import 'dart:io';

class SubtitleConfig {
  final File tts;
  late final List<Map<String, dynamic>> segments;

  SubtitleConfig.fromFile({
    required this.tts,
    required File configFile,
  }) {
    final json = jsonDecode(configFile.readAsStringSync());
    segments = (json['segments'] as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  SubtitleConfig.none() : tts = File('') {
    segments = [];
  }
}
