import 'dart:io';

bool dev = false;

String prePath = dev
    ? Directory.current.path
    : File(Platform.resolvedExecutable).parent.parent.path;
