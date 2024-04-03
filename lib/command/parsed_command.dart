import 'package:reddit_2_video/command/command.dart';
import 'package:args/args.dart';
import 'dart:io';
export 'package:reddit_2_video/command/command.dart';

class ParsedCommand {
  final Command? _command;
  final ArgResults? _args;
  final Directory _prePath;

  ParsedCommand({
    required Command? command,
    required ArgResults args,
  })  : _command = command,
        _args = args,
        _prePath = _determinePath(args);

  ParsedCommand.defaultCommand({
    required ArgResults args,
  })  : _command = Command.defaultCommand,
        _args = args,
        _prePath = _determinePath(args);

  ParsedCommand.noArgs({
    required Command command,
  })  : _command = command,
        _args = null,
        _prePath = Directory.current;

  ParsedCommand.none()
      : _command = null,
        _args = null,
        _prePath = Directory.current;

  Command? get command => _command;
  ArgResults? get args => _args;
  String get prePath => _prePath.path;

  bool get isDefault => _command == Command.defaultCommand;
  bool get isDev => _args?['dev'] ?? false;

  static Directory _determinePath(ArgResults args) {
    return args['dev']
        ? Directory.current
        : File(Platform.resolvedExecutable).parent.parent;
  }
}
