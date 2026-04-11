enum FileType {
  mp4,
  avi,
  mov,
  flv;

  static FileType? called(String type) {
    switch (type) {
      case 'mp4':
        return FileType.mp4;
      case 'avi':
        return FileType.avi;
      case 'mov':
        return FileType.mov;
      case 'flv':
        return FileType.flv;
      default:
        return null;
    }
  }
}
