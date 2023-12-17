import 'dart:io';

import 'package:args/args.dart';

late String prePath;

void setPath(ArgResults args) {
  late bool dev;
  try {
    dev = args['dev'];
  } catch (_) {
    dev = false;
  }
  prePath = dev
      ? Directory.current.path
      : File(Platform.resolvedExecutable).parent.parent.path;
}
