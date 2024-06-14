/// Used to warn the user but not necessarily stop the execution of the program.
class Warning {
  final String message;

  Warning.warn(this.message) {
    print(this);
  }

  @override
  String toString() {
    return '\x1b[33m$message\x1b[0m';
  }
}
