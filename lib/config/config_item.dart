import 'dart:io';
import 'package:reddit_2_video/utils/globals.dart' show prePath;

abstract class ConfigItem {
  final File _path;

  ConfigItem({required String path}) : _path = _getPath(path);

  File get path => _path;

  static File _getPath(String path) {
    File newFile = File('$prePath$path');
    if (newFile.existsSync()) {
      return newFile;
    } else {
      throw FileSystemException('File $path does not exist', path);
    }
  }
}
