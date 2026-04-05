import 'package:reddit_2_video/utils/logger.dart';

/// Used to warn the user but not necessarily stop the execution of the program.
class Warning {
  final String message;

  Warning.warn(this.message, {LogSection section = LogSection.setup}) {
    logger.warning(message, section: section);
  }
}
