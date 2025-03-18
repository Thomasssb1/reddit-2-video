import 'package:deep_pick/deep_pick.dart';
import 'package:reddit_2_video/command/parsed_command.dart';

import 'dart:convert';
import 'dart:io';

import 'package:reddit_2_video/config/voice.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';

class Voices {
  static List<Voice> voices = List.empty();

  static void fromFile(
    ParsedCommand command,
  ) {
    File file = File("${command.prePath}/defaults/voice.config.json");
    try {
      var json = jsonDecode(file.readAsStringSync());
      Voices.voices = pick(json, "voices")
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

      if (!Voices.voices.contains(command.voice)) {
        Warning.warn("Unable to use selected --voice, maybe it is disabled?");
      }
    } on PickException {
      throw InvalidFileFormatException(
          "File voices.config.json has an invalid format", file);
    } on FormatException {
      throw InvalidFileFormatException(
          "File voices.config.json is not in json format", file);
    }
    if (!command.voice.standard && !command.ntts) {
      throw ArgumentConflictException(
          "Unable to use a neural voice with standard tts engine.",
          command.voice.toString(),
          "ntts: ${command.ntts}");
    } else if (!command.voice.neural && command.ntts) {
      throw ArgumentConflictException(
          "Unable to use a standard voice with neural tts engine",
          command.voice.toString(),
          "ntts: ${command.ntts}");
    }
  }

  static Voice called(String id) {
    if (Voices.voices.isEmpty) {
      Warning.warn(
          "Ensure voice.config.json is loaded otherwise default voice Brian will be used.");
    }
    return Voices.voices
        .firstWhere((e) => e.id == id, orElse: () => Voice.standard());
  }

  static int _currentVoice = ++_currentVoice % Voices.voices.length;
  static Voice get current => Voices.voices[_currentVoice];
  static void next() => _currentVoice = ++_currentVoice % Voices.voices.length;
  static void set(Voice voice) {
    int index = Voices.voices.indexOf(voice);
    if (index == -1) {
      set(Voice.standard());
    } else {
      _currentVoice = index;
    }
  }

  static void reset() => _currentVoice = 0;
}
