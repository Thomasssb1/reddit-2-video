import 'dart:io';
import 'package:reddit_2_video/utils/prettify.dart';
import 'package:reddit_2_video/utils/run.dart';

Future<bool> installFFmpeg(bool continueGeneration) async {
  print(
      "The command ffmpeg could not be found. Do you want to install ffmpeg in order to continue? [\x1b[32my\x1b[0m/\x1b[31mN\x1b[0m] ");
  String download = stdin.readLineSync() ?? 'n';
  int code = 2;
  if (download.toLowerCase() == 'y') {
    if (Platform.isWindows) {
      bool chocoInstalled = await checkInstall('choco');
      bool wingetInstalled = await checkInstall('winget');
      bool scoopInstalled = await checkInstall('scoop');

      if (chocoInstalled) {
        printSuccess("Attempting to use choco to install ffmpeg.");
        code = await runCommand('choco', ['install', 'ffmpeg', '-y'], true);
        if (code == 0) {
          printSuccess(
              "Successfully installed ffmpeg using choco. ${continueGeneration ? 'Continuing reddit-2-video generation.' : ''}");
          return true;
        } else {
          printWarning(
              "Whilst trying to install ffmpeg using choco something went wrong. Trying to use other methods before aborting. Error code: $code");
        }
      }

      if (wingetInstalled && code != 0) {
        printSuccess("Attempting to use winget to install ffmpeg");
        code = await runCommand('winget', ['install', 'ffmpeg'], true);
        if (code == 0) {
          printSuccess(
              "Successfully installed ffmpeg using winget. ${continueGeneration ? 'Continuing reddit-2-video generation.' : ''}");
          return true;
        } else {
          printWarning(
              "Whilst trying to install ffmpeg using winget something went wrong. Trying to use other methods before aborting. Error code: $code");
        }
      }

      if (scoopInstalled && code != 0) {
        printSuccess("Attempting to use scoop to install ffmpeg");
        code = await runCommand('scoop', ['install', 'ffmpeg'], true);
        if (code == 0) {
          printSuccess(
              "Successfully installed ffmpeg using scoop. ${continueGeneration ? 'Continuing reddit-2-video generation.' : ''}");
          return true;
        } else {
          printWarning(
              "Whilst trying to install ffmpeg using scoop something went wrong. Error code: $code");
        }
      }

      print(
          "You do not have either choco, winget or scoop installed. You need to install one of these in order to use this process to install ffmpeg. Otherwise you need to install ffmpeg yourself.\nLearn more about ways to install ffmpeg here: https://www.gyan.dev/ffmpeg/builds/");

      exit(code);
    } else if (Platform.isLinux) {
      code = await runCommand('sudo', ['apt', 'install', 'ffmpeg'], true);
      if (code == 0) {
        printSuccess(
            "Successfully installed ffmpeg using  sudo apt install. ${continueGeneration ? 'Continuing reddit-2-video generation.' : ''}");
        return true;
      } else {
        printError(
            "Whilst trying to install ffmpeg using choco something went wrong. Error code: $code");
        exit(code);
      }
    } else if (Platform.isMacOS) {
      bool hasBrew = await checkInstall('brew');
      if (hasBrew) {
        code = await runCommand('brew', ['install', 'ffmpeg'], true);
        if (code == 0) {
          printSuccess(
              "Successfully installed ffmpeg using brew. ${continueGeneration ? 'Continuing reddit-2-video generation.' : ''}");
          return true;
        } else {
          printError(
              "Whilst trying to install ffmpeg using brew something went wrong. Error code: $code");
          exit(code);
        }
      } else {
        printError(
            "You need to install brew in order to install ffmpeg. Learn more here: https://brew.sh/. You can also try installing yourself using this guide: https://www.ffmpeg.org/download.html#build-mac");
        exit(code);
      }
    } else {
      printError(
          "Unable to determine device platform. You will need to install ffmpeg yourself before using reddit-2-video.");
    }
  } else {
    printError(
        "Aborted. You need to install ffmpeg in order to use reddit-2-video.\nLearn more here: \x1b[0mhttps://github.com/Thomasssb1/reddit-2-video");
  }
  exit(code);
}

installWhisper() async {
  int wispersuccess = await runCommand('pip3',
      ['install', 'git+https://github.com/linto-ai/whisper-timestamped'], true);
  if (wispersuccess != 0) {
    printWarning(
        "Whilst trying to install whisper-timestamped using pip3 something went wrong. Error code: $wispersuccess");
  }
}

Future<bool> checkInstall(String process) async {
  try {
    await Process.start(process, []);
    return true;
  } on ProcessException catch (e) {
    if (e.errorCode == 2) {
      return false;
    } else {
      printError(
          "Something went wrong. Try again later. Error code: ${e.errorCode}\nError: ${e.message}");
      exit(0);
    }
  }
}
