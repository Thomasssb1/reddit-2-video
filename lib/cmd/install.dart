import 'dart:io';
import 'package:reddit_2_video/exceptions/warning.dart';
import 'package:reddit_2_video/utils/prettify.dart';
import 'package:reddit_2_video/utils/subprocess.dart';

Future<bool> checkInstall(String command) async {
  try {
    bool isWindows = Platform.isWindows;
    var result =
        await Subprocess.exec(isWindows ? 'where' : 'which', [command]);
    return result.exitCode == 0;
  } catch (e) {
    Warning.warn(
        "Warning: An error occurred while checking if '$command' is installed. Exception: $e");
    return false;
  }
}

Future<void> installWhisper() async {
  print("Attempting to install whisper-timestamped via pip...");
  try {
    var result = await Subprocess.exec(
      'pip',
      ['install', 'git+https://github.com/linto-ai/whisper-timestamped'],
      verbose: true,
    );
    int exitCode = result.exitCode;
    if (exitCode != 0) {
      Warning.warn(
          "Whilst trying to install whisper-timestamped using pip something went wrong. Error code: $exitCode");
    } else {
      printSuccess("Successfully installed whisper-timestamped.");
    }
  } catch (e) {
    Warning.warn(
        "Failed to execute pip install for whisper-timestamped. Exception: $e");
  }
}

Future<void> checkDependencies() async {
  bool ffmpegInstalled = await checkInstall('ffmpeg');
  if (!ffmpegInstalled) {
    Warning.warn(
        "ffmpeg is missing. You need to have ffmpeg installed globally to generate videos. Download it here: ${Prettify.reset}https://ffmpeg.org/download.html");
    exit(1);
  }

  bool ytDlpInstalled = await checkInstall('yt-dlp');
  if (!ytDlpInstalled) {
    Warning.warn(
        "yt-dlp is missing. You need to have yt-dlp installed globally to download background videos. Download it here: ${Prettify.reset}https://github.com/yt-dlp/yt-dlp");
    exit(1);
  }

  bool awsCLIInstalled = await checkInstall('aws');
  if (!awsCLIInstalled) {
    Warning.warn(
        "AWS CLI is missing. You need to install AWS CLI in order to use AWS-Polly TTS. \n"
        "You can find out how to do this here:\nhttps://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions");
    exit(1);
  }
}

Future<void> runInstallCommand() async {
  bool pythonInstalled = await checkInstall('python');
  if (!pythonInstalled) {
    Warning.warn(
        "In order to continue, you need to have python installed. Download it here: ${Prettify.reset}https://www.python.org/downloads/");
  }

  bool ffmpegInstalled = await checkInstall('ffmpeg');
  if (!ffmpegInstalled) {
    Warning.warn(
        "You need to have ffmpeg installed globally in order to generate videos. Download it here: ${Prettify.reset}https://ffmpeg.org/download.html");
  }

  bool ytDlpInstalled = await checkInstall('yt-dlp');
  if (!ytDlpInstalled) {
    Warning.warn(
        "You need to have yt-dlp installed globally in order to download background videos. Download it here: ${Prettify.reset}https://github.com/yt-dlp/yt-dlp");
  }

  bool pipInstalled = await checkInstall('pip');
  if (!pipInstalled) {
    Warning.warn(
        "You need to have pip installed in order to install the python dependencies (like whisper-timestamped).");
  } else {
    await installWhisper();
  }

  bool awsCLIInstalled = await checkInstall('aws');
  if (!awsCLIInstalled) {
    Warning.warn("You need to install AWS CLI in order to use AWS-Polly TTS. \n"
        "You can find out how to do this here:\nhttps://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions");
  }

  if (pythonInstalled && ffmpegInstalled && ytDlpInstalled && pipInstalled) {
    printSuccess("All core dependencies are installed!");
  }
}
