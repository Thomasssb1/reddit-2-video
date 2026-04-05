import 'dart:io';
import 'dart:math' as math;

import 'package:consola/consola.dart';
import 'package:reddit_2_video/utils/logger.dart';

class ProgressSnapshot {
  final double fraction;
  final String title;
  final String detail;
  final LogSection section;

  const ProgressSnapshot({
    required this.fraction,
    required this.title,
    required this.detail,
    required this.section,
  });
}

class TerminalProgressRenderer {
  final IOSink _stdoutSink;
  final IOSink _stderrSink;
  final bool _enabled;
  int _renderedLines = 0;
  ProgressSnapshot? _snapshot;

  TerminalProgressRenderer({
    IOSink? stdoutSink,
    IOSink? stderrSink,
    bool? enabled,
  })  : _stdoutSink = stdoutSink ?? stdout,
        _stderrSink = stderrSink ?? stderr,
        _enabled = enabled ??
            (stdout.hasTerminal &&
                stdout.supportsAnsiEscapes &&
                stderr.hasTerminal &&
                stderr.supportsAnsiEscapes);

  bool get isEnabled => _enabled;

  void writeMessage(String message, {required bool isError}) {
    final sink = isError ? _stderrSink : _stdoutSink;
    if (!isEnabled) {
      sink.write(message);
      return;
    }

    sink.write(message);
    _redrawFooterPreservingCursor();
  }

  void update(ProgressSnapshot snapshot) {
    if (!isEnabled) return;
    _snapshot = snapshot;
    _redrawFooterPreservingCursor();
  }

  void clear() {
    if (!isEnabled) return;
    _snapshot = null;
    _clearFooter();
  }

  void _clearFooter() {
    if (!isEnabled || _renderedLines == 0) return;

    final footerRows = _footerRows(_renderedLines);
    for (final row in footerRows) {
      Console.moveTo(1, row);
      Console.clearLine();
    }
    _renderedLines = 0;
  }

  void _drawFooter() {
    if (!isEnabled || _snapshot == null) return;

    final snapshot = _snapshot!;
    final columns =
        Console.getWindowWidth() > 0 ? Console.getWindowWidth() : 80;
    final footerRows = _footerRows(2);
    final barWidth = math.max(16, math.min(40, columns ~/ 3));
    final progressBar = ProgressBar.atPosition(
      total: 1000,
      width: barWidth,
      console: Console.instance,
      position: ConsoleCoordinate(1, footerRows.first),
      head: '${logger.formatSection(snapshot.section)} ',
      barFillCharacter: '=',
      tailBuilder: (_, __, percent) =>
          ' ${percent.toStringAsFixed(1)}% ${snapshot.title}',
    )..current = (snapshot.fraction.clamp(0.0, 1.0) * 1000).round();

    Console.draw(progressBar);
    Console.moveTo(1, footerRows.last);
    Console.clearLine();
    Console.write(snapshot.detail);
    _renderedLines = 2;
  }

  void _redrawFooterPreservingCursor() {
    if (!isEnabled) return;

    final cursor = Console.getCursorPosition();
    _clearFooter();
    _drawFooter();
    Console.moveTo(cursor.x, cursor.y);
  }

  List<int> _footerRows(int count) {
    final height =
        Console.getWindowHeight() > 0 ? Console.getWindowHeight() : 24;
    final startRow = math.max(1, height - count + 1);
    return List<int>.generate(count, (index) => startRow + index);
  }
}

class _ProgressTask {
  final String id;
  final double weight;
  final LogSection section;
  String title;
  String detail;
  double totalUnits;
  double completedUnits;
  bool completed;

  _ProgressTask({
    required this.id,
    required this.weight,
    required this.section,
    required this.title,
    required this.detail,
    required this.totalUnits,
  })  : completedUnits = 0,
        completed = false;

  double get fraction {
    if (completed) return 1;
    if (totalUnits <= 0) return 0;
    return (completedUnits / totalUnits).clamp(0.0, 1.0).toDouble();
  }
}

class GenerationProgressTracker {
  final TerminalProgressRenderer renderer;
  final Map<String, _ProgressTask> _tasks = {};
  int _nextTaskId = 0;
  bool _started = false;
  String? _activeTaskId;

  GenerationProgressTracker({TerminalProgressRenderer? renderer})
      : renderer = renderer ?? TerminalProgressRenderer();

  bool get isActive => _started && renderer.isEnabled;

  void start() {
    if (_started || !renderer.isEnabled) return;
    _started = true;
    logger.attachOverlay(renderer.writeMessage);
    renderer.update(const ProgressSnapshot(
      fraction: 0,
      title: 'Starting generation',
      detail: 'Preparing work plan...',
      section: LogSection.setup,
    ));
  }

  void stop() {
    _tasks.clear();
    _activeTaskId = null;
    if (_started) {
      renderer.clear();
      logger.detachOverlay();
    }
    _started = false;
  }

  String createTask({
    required String title,
    required double weight,
    required LogSection section,
    String detail = '',
    double totalUnits = 1,
  }) {
    final taskId = 'task-${_nextTaskId++}';
    _tasks[taskId] = _ProgressTask(
      id: taskId,
      weight: weight,
      section: section,
      title: title,
      detail: detail,
      totalUnits: totalUnits,
    );
    _activeTaskId = taskId;
    _render();
    return taskId;
  }

  void setTotalUnits(String taskId, double totalUnits) {
    final task = _tasks[taskId];
    if (task == null) return;
    task.totalUnits = totalUnits <= 0 ? 1 : totalUnits;
    _activeTaskId = taskId;
    _render();
  }

  void updateTask(String taskId,
      {double? completedUnits, String? detail, String? title}) {
    final task = _tasks[taskId];
    if (task == null) return;

    if (completedUnits != null) {
      task.completedUnits = completedUnits.clamp(0, task.totalUnits).toDouble();
    }
    if (detail != null) {
      task.detail = detail;
    }
    if (title != null) {
      task.title = title;
    }
    _activeTaskId = taskId;
    _render();
  }

  void incrementTask(String taskId,
      {double by = 1, String? detail, String? title}) {
    final task = _tasks[taskId];
    if (task == null) return;
    updateTask(
      taskId,
      completedUnits: task.completedUnits + by,
      detail: detail,
      title: title,
    );
  }

  void completeTask(String taskId, {String? detail}) {
    final task = _tasks[taskId];
    if (task == null) return;
    task.completed = true;
    task.completedUnits = task.totalUnits;
    if (detail != null) {
      task.detail = detail;
    }
    final activeTasks =
        _tasks.values.where((task) => !task.completed).toList(growable: false);
    _activeTaskId = activeTasks.isEmpty ? null : activeTasks.last.id;
    _render();
  }

  void reportStandaloneProgress({
    required String title,
    required String detail,
    required LogSection section,
    required double fraction,
  }) {
    if (!_started) return;
    renderer.update(ProgressSnapshot(
      fraction: fraction.clamp(0.0, 1.0).toDouble(),
      title: title,
      detail: detail,
      section: section,
    ));
  }

  void _render() {
    if (!_started) return;

    if (_tasks.isEmpty) {
      renderer.update(const ProgressSnapshot(
        fraction: 0,
        title: 'Starting generation',
        detail: 'Preparing work plan...',
        section: LogSection.setup,
      ));
      return;
    }

    final totalWeight =
        _tasks.values.fold<double>(0, (sum, task) => sum + task.weight);
    final completedWeight = _tasks.values
        .fold<double>(0, (sum, task) => sum + (task.fraction * task.weight));
    final active = _activeTaskId != null ? _tasks[_activeTaskId] : null;
    final fallback = _tasks.values.last;

    renderer.update(ProgressSnapshot(
      fraction: totalWeight == 0 ? 0 : completedWeight / totalWeight,
      title: (active ?? fallback).title,
      detail: (active ?? fallback).detail,
      section: (active ?? fallback).section,
    ));
  }
}

final generationProgress = GenerationProgressTracker();
