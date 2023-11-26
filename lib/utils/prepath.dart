import 'dart:io';

late String prePath;

void setPath(bool dev) => prePath = dev ? Directory.current.path : File(Platform.resolvedExecutable).parent.parent.path;
