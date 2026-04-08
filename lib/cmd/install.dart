import 'dart:io';
import 'package:reddit_2_video/utils/logger.dart';
import 'package:reddit_2_video/utils/subprocess/subprocess.dart';

Future<bool> checkInstall(String command) async {
  try {
    bool isWindows = Platform.isWindows;
    var result = await Subprocess.exec(isWindows ? 'where' : 'which', [command],
        section: LogSection.install);
    return result.exitCode == 0;
  } catch (e) {
    logger.error(
        "An error occurred while checking if '$command' is installed. Exception: $e",
        section: LogSection.install);
    return false;
  }
}

Future<void> checkDependencies() async {
  logger.info("Checking dependencies.", section: LogSection.setup);
  bool ffmpegInstalled = await checkInstall('ffmpeg');
  if (!ffmpegInstalled) {
    logger.warning(
        "ffmpeg is missing. You need to have ffmpeg installed globally to generate videos. Download it here: $ansiReset https://ffmpeg.org/download.html",
        section: LogSection.install);
    exit(1);
  }

  bool ytDlpInstalled = await checkInstall('yt-dlp');
  if (!ytDlpInstalled) {
    logger.warning(
        "yt-dlp is missing. You need to have yt-dlp installed globally to download background videos. Download it here: $ansiReset https://github.com/yt-dlp/yt-dlp",
        section: LogSection.install);
    exit(1);
  }

  bool awsCLIInstalled = await checkInstall('aws');
  if (!awsCLIInstalled) {
    logger.warning(
        "AWS CLI is missing. You need to install AWS CLI in order to use AWS-Polly TTS. \n"
        "You can find out how to do this here:\nhttps://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions",
        section: LogSection.install);
    exit(1);
  }
}

Future<void> runInstallCommand() async {
  bool ffmpegInstalled = await checkInstall('ffmpeg');
  if (!ffmpegInstalled) {
    logger.warning(
        "You need to have ffmpeg installed globally in order to generate videos. Download it here: $ansiReset https://ffmpeg.org/download.html",
        section: LogSection.install);
  }

  bool ytDlpInstalled = await checkInstall('yt-dlp');
  if (!ytDlpInstalled) {
    logger.warning(
        "You need to have yt-dlp installed globally in order to download background videos. Download it here: $ansiReset https://github.com/yt-dlp/yt-dlp",
        section: LogSection.install);
  }

  bool awsCLIInstalled = await checkInstall('aws');
  if (!awsCLIInstalled) {
    logger.warning(
        "You need to install AWS CLI in order to use AWS-Polly TTS. \n"
        "You can find out how to do this here:\nhttps://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions",
        section: LogSection.install);
  }

  if (ffmpegInstalled && ytDlpInstalled && awsCLIInstalled) {
    logger.success("All core dependencies are installed!",
        section: LogSection.install);
  }
}
