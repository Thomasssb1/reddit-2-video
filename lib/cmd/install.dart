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

Future<void> installWhisper() async {
  logger.info(
    "Attempting to install whisper-timestamped via pip.",
    section: LogSection.install,
  );
  try {
    var result = await Subprocess.exec(
      'pip',
      ['install', 'git+https://github.com/linto-ai/whisper-timestamped'],
      verbose: true,
      section: LogSection.install,
    );
    int exitCode = result.exitCode;
    if (exitCode != 0) {
      logger.warning(
          "Whilst trying to install whisper-timestamped using pip something went wrong. Error code: $exitCode",
          section: LogSection.install);
    } else {
      logger.success("Successfully installed whisper-timestamped.",
          section: LogSection.install);
    }
  } catch (e) {
    logger.error(
        "Failed to execute pip install for whisper-timestamped. Exception: $e",
        section: LogSection.install);
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
  bool pythonInstalled = await checkInstall('python');
  if (!pythonInstalled) {
    logger.warning(
        "In order to continue, you need to have python installed. Download it here: $ansiReset https://www.python.org/downloads/",
        section: LogSection.install);
  }

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

  bool pipInstalled = await checkInstall('pip');
  if (!pipInstalled) {
    logger.warning(
        "You need to have pip installed in order to install the python dependencies (like whisper-timestamped).",
        section: LogSection.install);
  } else {
    await installWhisper();
  }

  bool awsCLIInstalled = await checkInstall('aws');
  if (!awsCLIInstalled) {
    logger.warning(
        "You need to install AWS CLI in order to use AWS-Polly TTS. \n"
        "You can find out how to do this here:\nhttps://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions",
        section: LogSection.install);
  }

  if (pythonInstalled && ffmpegInstalled && ytDlpInstalled && pipInstalled) {
    logger.success("All core dependencies are installed!",
        section: LogSection.install);
  }
}
