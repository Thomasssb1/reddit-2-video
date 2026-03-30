import 'package:deep_pick/deep_pick.dart';
import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/command/parsed_command.dart';

import 'dart:convert';
import 'dart:io';

import 'package:reddit_2_video/config/voices/voice.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';

class Voices {
  List<Voice> _voices = List.empty();
  int _currentVoice = 0;

  Voices(
    List<Voice> voices,
    Voice currentVoice,
    ParsedCommand command,
  ) {
    if (!currentVoice.standard && !command.ntts) {
      throw ArgumentConflictException(
          "Unable to use a neural voice with standard tts engine.",
          command.voice.toString(),
          "ntts: ${command.ntts}");
    } else if (!currentVoice.neural && command.ntts) {
      throw ArgumentConflictException(
          "Unable to use a standard voice with neural tts engine",
          command.voice.toString(),
          "ntts: ${command.ntts}");
    }

    if (!voices.contains(currentVoice)) {
      Warning.warn("Unable to use selected --voice, maybe it is disabled?");
    }
    int index = voices.indexOf(currentVoice);
    _currentVoice = index == -1 ? 0 : index;
    _voices = voices;
  }

  static List<Voice> fromFile(
    ParsedCommand command,
  ) {
    File file = AppPaths.resolve('defaults/voice.config.json');
    try {
      var json = jsonDecode(file.readAsStringSync());
      return pick(json, "voices")
          .asListOrThrow<Voice?>((p0) {
            String name = p0("name").asStringOrThrow();
            bool neural = p0("neural").asBoolOrFalse();
            bool standard = p0("standard").asBoolOrTrue();
            bool newscaster = p0("newscaster").asBoolOrFalse();
            bool disabled = p0("disabled").asBoolOrFalse();

            // if using neural tts and the voice is not neural, skip
            if (command.ntts && !neural) {
              return null;
              // if using standard tts and the voice is not standard, skip
            } else if (!command.ntts && !standard) {
              return null;
            }

            return Voice(
                id: name,
                neural: neural,
                standard: standard,
                newscaster: newscaster,
                disabled: disabled);
          })
          .whereType<Voice>()
          .where((e) => !e.disabled)
          .toList();
    } on PickException {
      throw InvalidFileFormatException(
          "File voices.config.json has an invalid format", file);
    } on FormatException {
      throw InvalidFileFormatException(
          "File voices.config.json is not in json format", file);
    }
  }

  Voice called(String id) => Voices.find(_voices, id);

  static Voice find(List<Voice> voices, String id) {
    if (voices.isEmpty) {
      Warning.warn(
          "Ensure voice.config.json is loaded otherwise default voice Brian will be used.");
    }
    return voices.firstWhere((e) => e.id == id, orElse: () => Voice.standard());
  }

  Voice get current => _voices[_currentVoice];
  void next() => _currentVoice = ++_currentVoice % _voices.length;
  void set(Voice voice) {
    int index = _voices.indexOf(voice);
    if (index == -1) {
      set(Voice.standard());
    } else {
      _currentVoice = index;
    }
  }

  void reset() => _currentVoice = 0;
}
