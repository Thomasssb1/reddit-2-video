import 'dart:io';

abstract class ConfigItem {
  File _path;

  ConfigItem(
      {required String path,
      required String prePath,
      File Function(String, String)? fileFactory})
      : _path = (fileFactory ?? _getPath)(path.replaceFirst("/", ""), prePath);

  /// Initializes a ConfigItem with an already resolved File.
  ConfigItem.fromFile(File path) : _path = path {
    if (!path.existsSync()) {
      throw FileSystemException('File does not exist', path.path);
    }
  }

  File get path => _path;

  set path(newPath) => _path = path;

  static File _getPath(String path, String prePath) {
    File newFile = File('$prePath/$path');
    if (newFile.existsSync()) {
      return newFile;
    } else {
      throw FileSystemException('File $path does not exist', "$prePath/$path");
    }
  }

  /// Public alias for path resolution used by subclasses and factories.
  static File getPathStatic(String path, String prePath) =>
      _getPath(path, prePath);
}
