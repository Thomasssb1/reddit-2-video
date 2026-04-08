import 'dart:io';
import 'package:reddit_2_video/exceptions/subprocess_exception.dart';

const String ansiReset = '\x1b[0m';
const String ansiAsciiCharsetReset = '\x1b(B';
const String ansiRed = '\x1b[31m';
const String ansiGreen = '\x1b[32m';
const String ansiYellow = '\x1b[33m';
const String ansiBlue = '\x1b[34m';
const String ansiMagenta = '\x1b[35m';
const String ansiCyan = '\x1b[36m';
const String ansiUnderline = '\x1b[4m';
const String ansiWhite = '\x1b[37m';

enum LogSection {
  setup(label: 'Setup', color: ansiBlue),
  reddit(label: 'Reddit', color: ansiMagenta),
  backgroundVideo(label: 'Background Video', color: ansiCyan),
  subtitles(label: 'Subtitles', color: ansiYellow),
  generation(label: 'Generation', color: ansiGreen),
  split(label: 'Split', color: ansiWhite),
  install(label: 'Install', color: ansiBlue);

  const LogSection({required this.label, required this.color});

  final String label;
  final String color;
}

class Logger {
  LogSection? _lastPrintedSection;
  void Function(String message, {required bool isError})? _overlayWriter;
  StringSink _stdoutSink = stdout;
  StringSink _stderrSink = stderr;

  String _colorText(String text, String colorCode) {
    if (!stdout.supportsAnsiEscapes) {
      return text;
    }
    return '$ansiAsciiCharsetReset$colorCode$text$ansiReset';
  }

  String formatSection(LogSection section) =>
      _colorText('[${section.label}]', section.color);

  String prefixLines(String message, {LogSection? section}) {
    if (section == null || message.isEmpty) {
      return message;
    }

    final needsSectionBreak =
        _lastPrintedSection != null && _lastPrintedSection != section;
    _lastPrintedSection = section;

    final prefix = '${formatSection(section)} ';
    final trailingNewline = message.endsWith('\n');
    final lines = message.split('\n');
    if (trailingNewline) {
      lines.removeLast();
    }

    final output = lines
        .map((line) => line.isEmpty ? formatSection(section) : '$prefix$line')
        .join('\n');

    final separatedOutput = needsSectionBreak ? '\n$output' : output;

    return trailingNewline ? '$separatedOutput\n' : separatedOutput;
  }

  void _printMessage(String message,
      {LogSection? section,
      String? messageColor,
      bool underline = false,
      bool isError = false}) {
    final formattedMessage = underline
        ? _colorText(message, ansiUnderline)
        : messageColor != null
            ? _colorText(message, messageColor)
            : message;
    emitRaw('$formattedMessage\n', section: section, isError: isError);
  }

  void emitRaw(String message, {LogSection? section, bool isError = false}) {
    final output = prefixLines(message, section: section);
    if (_overlayWriter != null) {
      _overlayWriter!(output, isError: isError);
      return;
    }

    final sink = isError ? _stderrSink : _stdoutSink;
    sink.write(output);
  }

  void info(String message, {LogSection? section}) {
    _printMessage(message, section: section);
  }

  void error(Object error, {LogSection? section}) {
    if (error is SubprocessException) {
      _printMessage(error.message,
          section: section,
          messageColor: ansiRed,
          isError: true,
          underline: true);
      final detail = error.errorDetail;
      if (detail != null && detail != error.message) {
        _printMessage(detail,
            section: section, messageColor: ansiRed, isError: true);
      }
      return;
    }

    _printMessage(error.toString(),
        section: section, messageColor: ansiRed, isError: true);
  }

  void warning(String message, {LogSection? section}) {
    _printMessage(message, section: section, messageColor: ansiYellow);
  }

  void success(String message, {LogSection? section}) {
    _printMessage(message, section: section, messageColor: ansiGreen);
  }

  void underline(String message, {LogSection? section}) {
    _printMessage(message, section: section, underline: true);
  }

  void resetForTest() {
    _lastPrintedSection = null;
    _overlayWriter = null;
    _stdoutSink = stdout;
    _stderrSink = stderr;
  }

  void attachOverlay(
      void Function(String message, {required bool isError}) writer) {
    _overlayWriter = writer;
  }

  void detachOverlay() {
    _overlayWriter = null;
  }

  void setOutputSinksForTest({
    StringSink? stdoutSink,
    StringSink? stderrSink,
  }) {
    _stdoutSink = stdoutSink ?? stdout;
    _stderrSink = stderrSink ?? stderr;
  }
}

final logger = Logger();
