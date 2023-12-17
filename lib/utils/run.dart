import 'dart:io';
import 'dart:convert';

Future<int> runCommand(String executable, List<String> arguments, bool verbose,
    [String? workingDirectory]) async {
  final process = await Process.start(executable, arguments,
      workingDirectory: workingDirectory);
  if (verbose) {
    process.stderr.transform(utf8.decoder).listen((data) {
      stdout.write(data);
    });
    process.stdin.write(process.stdin);
  }
  int code = await process.exitCode;
  return code;
}
