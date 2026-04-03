import 'dart:io';
import 'package:path/path.dart' as p;

/// Centralised path resolution for the application.
///
/// Initialise once at startup via [init] (production) or [initForTest] (tests).
/// All asset paths are resolved relative to the root directory.
class AppPaths {
  static late Directory _root;
  static bool _initialised = false;

  /// Call once at startup from main().
  static void init({required bool isDev}) {
    _root = isDev
        ? Directory.current
        : File(Platform.resolvedExecutable).parent.parent;
    _initialised = true;
  }

  /// For testing: override root to a specific directory.
  static void initForTest(Directory root) {
    _root = root;
    _initialised = true;
  }

  static void _assertInitialised() {
    if (!_initialised) {
      throw StateError('AppPaths.init() must be called before accessing paths');
    }
  }

  /// The root path as a string. Use this for `workingDirectory` in
  /// `Process.start` calls where a raw path string is needed.
  static String get rootPath {
    _assertInitialised();
    return _root.path;
  }

  /// Resolve a relative path to a [File] under the root directory.
  static File resolve(String relativePath) {
    _assertInitialised();
    if (p.isAbsolute(relativePath)) {
      return File(relativePath);
    }
    return File(p.join(_root.path, relativePath));
  }

  /// Resolve a relative path to a [Directory] under the root directory.
  static Directory resolveDir(String relativePath) {
    _assertInitialised();
    if (p.isAbsolute(relativePath)) {
      return Directory(relativePath);
    }
    return Directory(p.join(_root.path, relativePath));
  }
}
