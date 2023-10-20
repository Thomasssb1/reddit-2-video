import 'dart:io';

bool dev = true;

String prePath = dev ? Directory.current.path : File(Platform.resolvedExecutable).parent.parent.path;
