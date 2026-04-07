import 'dart:io';

class CliDocsGenerator {
  final String executableName;
  final String sourcePathLabel;

  CliDocsGenerator({
    this.executableName = 'reddit-2-video',
    this.sourcePathLabel = 'lib/command/parsed_command.dart',
  });

  String generateFromFile(String path) {
    return generateFromSource(File(path).readAsStringSync());
  }

  String generateFromSource(String source) {
    final options = _parseOptions(source);
    final commands = _parseCommands(source);
    final buffer = StringBuffer()
      ..writeln('# CLI Reference')
      ..writeln()
      ..writeln(
          'This page is generated from `$sourcePathLabel`. Update the CLI parser and redeploy to refresh this reference.')
      ..writeln()
      ..writeln('## Command Overview')
      ..writeln()
      ..writeln('```bash')
      ..writeln('$executableName --subreddit AskReddit [options]')
      ..writeln('$executableName flush --post <reddit-post-id>')
      ..writeln('$executableName install')
      ..writeln('```')
      ..writeln()
      ..writeln('## Default Command')
      ..writeln()
      ..writeln('The default command generates videos from a subreddit or a Reddit post URL.')
      ..writeln()
      ..writeln('```bash')
      ..writeln('$executableName --subreddit AskReddit [options]')
      ..writeln('```')
      ..writeln()
      ..writeln('### Options')
      ..writeln();

    for (final option in options) {
      buffer
        ..writeln('#### `--${option.name}`')
        ..writeln()
        ..writeln('- Type: `${option.kind}`');

      if (option.abbr != null) {
        buffer.writeln('- Short flag: `-${option.abbr}`');
      }
      if (option.valueHelp != null) {
        buffer.writeln('- Value: `${option.valueHelp}`');
      }
      if (option.defaultValue != null) {
        buffer.writeln('- Default: `${option.defaultValue}`');
      }
      if (option.allowedValues.isNotEmpty) {
        buffer.writeln(
            '- Allowed: ${option.allowedValues.map((value) => '`$value`').join(', ')}');
      }
      if (option.isMandatory) {
        buffer.writeln('- Required: yes');
      }
      if (option.help != null) {
        buffer.writeln('- Description: ${option.help}');
      }
      buffer.writeln();
    }

    _writeCommandSection(
      buffer,
      command: commands.firstWhere(
        (command) => command.name == 'install',
        orElse: () => const CliCommandDoc(name: 'install', options: []),
      ),
      usage: '$executableName install',
      description:
          'Installs or bootstraps runtime dependencies. In practice this is a starting point for setup rather than a complete environment installer.',
    );

    _writeCommandSection(
      buffer,
      command: commands.firstWhere(
        (command) => command.name == 'flush',
        orElse: () => const CliCommandDoc(name: 'flush', options: []),
      ),
      usage: '$executableName flush --post <reddit-post-id>',
      description:
          'Manages visited-post state so you can remove a post from the visited log and allow it to be reused.',
    );

    return buffer.toString().trimRight() + '\n';
  }

  void _writeCommandSection(
    StringBuffer buffer, {
    required CliCommandDoc command,
    required String usage,
    required String description,
  }) {
    buffer
      ..writeln('## `${command.name}` Command')
      ..writeln()
      ..writeln(description)
      ..writeln()
      ..writeln('```bash')
      ..writeln(usage)
      ..writeln('```')
      ..writeln()
      ..writeln('### Options')
      ..writeln();

    if (command.options.isEmpty) {
      buffer.writeln('This command has no command-specific options.');
      buffer.writeln();
      return;
    }

    for (final option in command.options) {
      buffer.writeln('#### `--${option.name}`');
      buffer.writeln();
      buffer.writeln('- Type: `${option.kind}`');
      if (option.abbr != null) {
        buffer.writeln('- Short flag: `-${option.abbr}`');
      }
      if (option.help != null) {
        buffer.writeln('- Description: ${option.help}');
      }
      buffer.writeln();
    }
  }

  List<CliOptionDoc> _parseOptions(String source) {
    final parserBlock = _extractMethodBody(source, 'static ArgParser getParser()');
    final options = <CliOptionDoc>[];
    for (final invocation in _extractInvocations(
      parserBlock,
      receivers: ['parser', '..'],
    )) {
      final kind = invocation.method;
      final name = invocation.name;
      final args = invocation.args;

      options.add(CliOptionDoc(
        name: name,
        kind: _normalizeKind(kind),
        abbr: _extractStringValue(args, 'abbr'),
        defaultValue: _extractStringValue(args, 'defaultsTo'),
        help: _normalizeText(_extractStringValue(args, 'help')),
        valueHelp: _extractStringValue(args, 'valueHelp'),
        allowedValues: _extractListValue(args, 'allowed'),
        isMandatory: _extractBoolValue(args, 'mandatory') ?? false,
      ));
    }
    return options;
  }

  List<CliCommandDoc> _parseCommands(String source) {
    final parserBlock = _extractMethodBody(source, 'static ArgParser getParser()');
    final commandVarMatches = RegExp(
      r"var\s+(\w+)\s*=\s*parser\.addCommand\('([^']+)'\);",
    ).allMatches(parserBlock);

    final commands = <CliCommandDoc>[];
    final commandVars = <String, String>{};

    for (final match in commandVarMatches) {
      commandVars[match.group(1)!] = match.group(2)!;
    }

    for (final entry in commandVars.entries) {
      final options = _extractInvocations(
        parserBlock,
        receivers: [entry.key],
      )
          .map((invocation) => CliOptionDoc(
                name: invocation.name,
                kind: _normalizeKind(invocation.method),
                abbr: _extractStringValue(invocation.args, 'abbr'),
                defaultValue:
                    _extractStringValue(invocation.args, 'defaultsTo'),
                help: _normalizeText(
                    _extractStringValue(invocation.args, 'help')),
                valueHelp:
                    _extractStringValue(invocation.args, 'valueHelp'),
                allowedValues:
                    _extractListValue(invocation.args, 'allowed'),
                isMandatory:
                    _extractBoolValue(invocation.args, 'mandatory') ?? false,
              ))
          .toList();

      commands.add(CliCommandDoc(name: entry.value, options: options));
    }

    final directCommandMatches = RegExp(
      r"parser\.addCommand\('([^']+)'\);",
    ).allMatches(parserBlock);

    for (final match in directCommandMatches) {
      final name = match.group(1)!;
      if (commands.any((command) => command.name == name)) {
        continue;
      }
      commands.add(CliCommandDoc(name: name, options: const []));
    }

    return commands;
  }

  List<_Invocation> _extractInvocations(
    String source, {
    required List<String> receivers,
  }) {
    final invocations = <_Invocation>[];
    final patterns = receivers
        .map((receiver) => RegExp.escape(receiver))
        .join('|');
    final startMatches = RegExp(
      '(?:$patterns)\\s*\\.?\\s*(addOption|addFlag|addMultiOption)\\(',
      multiLine: true,
    ).allMatches(source);

    for (final match in startMatches) {
      final method = match.group(1)!;
      final openParenIndex = match.end - 1;
      final closeParenIndex = _findMatchingParen(source, openParenIndex);
      final contents = source.substring(openParenIndex + 1, closeParenIndex);
      final nameMatch = RegExp(r"^\s*'([^']+)'(?:\s*,([\s\S]*))?$", multiLine: true)
          .firstMatch(contents);
      if (nameMatch == null) {
        continue;
      }
      invocations.add(_Invocation(
        method: method,
        name: nameMatch.group(1)!,
        args: nameMatch.group(2)?.trim() ?? '',
      ));
    }

    return invocations;
  }

  int _findMatchingParen(String source, int openParenIndex) {
    var depth = 0;
    var inSingleQuote = false;
    var escaping = false;

    for (var index = openParenIndex; index < source.length; index++) {
      final character = source[index];

      if (inSingleQuote) {
        if (escaping) {
          escaping = false;
          continue;
        }
        if (character == r'\') {
          escaping = true;
          continue;
        }
        if (character == "'") {
          inSingleQuote = false;
        }
        continue;
      }

      if (character == "'") {
        inSingleQuote = true;
        continue;
      }

      if (character == '(') {
        depth++;
      } else if (character == ')') {
        depth--;
        if (depth == 0) {
          return index;
        }
      }
    }

    throw StateError('Unable to find matching closing parenthesis.');
  }

  String _extractMethodBody(String source, String signature) {
    final start = source.indexOf(signature);
    if (start == -1) {
      throw StateError('Unable to find $signature in source file.');
    }

    final bodyStart = source.indexOf('{', start);
    if (bodyStart == -1) {
      throw StateError('Unable to find opening brace for $signature.');
    }

    var depth = 0;
    for (var index = bodyStart; index < source.length; index++) {
      final character = source[index];
      if (character == '{') {
        depth++;
      } else if (character == '}') {
        depth--;
        if (depth == 0) {
          return source.substring(bodyStart + 1, index);
        }
      }
    }

    throw StateError('Unable to find closing brace for $signature.');
  }

  String _normalizeKind(String kind) {
    switch (kind) {
      case 'addFlag':
        return 'flag';
      case 'addMultiOption':
        return 'multi-option';
      default:
        return 'option';
    }
  }

  String? _extractStringValue(String source, String key) {
    final match = RegExp(
      "$key\\s*:\\s*((?:'((?:\\\\'|[^'])*)'\\s*)+)",
      multiLine: true,
    ).firstMatch(source);
    if (match == null) {
      return null;
    }

    return RegExp(r"'((?:\\'|[^'])*)'")
        .allMatches(match.group(1)!)
        .map((item) => item.group(1)!.replaceAll("\\'", "'"))
        .join();
  }

  bool? _extractBoolValue(String source, String key) {
    final match =
        RegExp('$key\\s*:\\s*(true|false)', multiLine: true).firstMatch(source);
    if (match == null) {
      return null;
    }
    return match.group(1) == 'true';
  }

  List<String> _extractListValue(String source, String key) {
    final match = RegExp('$key\\s*:\\s*\\[([\\s\\S]*?)\\]', multiLine: true)
        .firstMatch(source);
    if (match == null) {
      return const [];
    }

    return RegExp(r"'([^']+)'")
        .allMatches(match.group(1)!)
        .map((item) => item.group(1)!)
        .toList();
  }

  String? _normalizeText(String? text) {
    if (text == null) {
      return null;
    }
    return text.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class CliOptionDoc {
  final String name;
  final String kind;
  final String? abbr;
  final String? defaultValue;
  final String? help;
  final String? valueHelp;
  final List<String> allowedValues;
  final bool isMandatory;

  const CliOptionDoc({
    required this.name,
    required this.kind,
    required this.abbr,
    required this.defaultValue,
    required this.help,
    required this.valueHelp,
    required this.allowedValues,
    required this.isMandatory,
  });
}

class CliCommandDoc {
  final String name;
  final List<CliOptionDoc> options;

  const CliCommandDoc({
    required this.name,
    required this.options,
  });
}

class _Invocation {
  final String method;
  final String name;
  final String args;

  const _Invocation({
    required this.method,
    required this.name,
    required this.args,
  });
}
