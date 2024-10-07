import 'dart:io';

abstract class ConfigItem {
  File _path;

  ConfigItem({required String path, required String prePath})
      : _path = _getPath(path, prePath);

  File get path => _path;

  set path(newPath) => _path = path;

  static File _getPath(String path, String prePath) {
    File newFile = File('$prePath$path');
    if (newFile.existsSync()) {
      return newFile;
    } else {
      throw FileSystemException('File $path does not exist', "$prePath$path");
    }
  }
}
