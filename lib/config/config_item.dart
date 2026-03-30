import 'dart:io';
import 'package:reddit_2_video/app_paths.dart';

abstract class ConfigItem {
  File _path;

  ConfigItem({required String path})
      : _path = _getPath(path);

  /// Initializes a ConfigItem with an already resolved File.
  ConfigItem.fromFile(File path) : _path = path {
    if (!path.existsSync()) {
      throw FileSystemException('File does not exist', path.path);
    }
  }

  File get path => _path;

  set path(newPath) => _path = path;

  static File _getPath(String path) {
    File newFile = AppPaths.resolve(path);
    if (newFile.existsSync()) {
      return newFile;
    } else {
      throw FileSystemException(
          'File $path does not exist', newFile.path);
    }
  }
}
