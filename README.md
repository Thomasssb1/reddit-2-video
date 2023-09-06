# reddit-2-video
A simple command line script for generating a tiktok-style video with a large variety of different options to change the output. <br>
View the wiki [here](https://github.com/Thomasssb1/reddit-2-video/wiki) for information on how to use reddit-2-video.

## Setup
The easiest way to get started is to download one of the [releases](https://github.com/Thomasssb1/reddit-2-video/releases). The release includes all of the dart code precompiled ([see other dependencies](https://github.com/Thomasssb1/reddit-2-video#dependencies)).<br><br>
Add the folder to path<br>
This is different across each operating system. [This gist](https://gist.github.com/nex3/c395b2f8fd4b02068be37c961301caa7) shows the different methods to add a folder to path - follow the steps but use the folder `reddit-2-video/bin` that you cloned. You need to add the full path to `reddit-2-video/bin` to your system path in environmental variables.<br><br>
Install dependencies<br>
If you do not have ffmpeg or [whisper_timestamped](https://github.com/linto-ai/whisper-timestamped), you can run the following command in an *elevated shell*.
```sh
$ reddit-2-video install
```
This will install ffmpeg and whisper_timestamped that are required to run reddit-2-video. If this does not work, you can install these prerequisites [manually](https://github.com/Thomasssb1/reddit-2-video#dependencies).
<details>
    <summary>For developer builds</summary><br>
    
>Run the following command in your terminal in order to rebuild the executable each time something is changed whilst developing an update. You <u>do not</u> need to add the <b>reddit-2-video/bin</b> folder to path like normal.<br><br>
>
>Clone the repository
>```sh 
>$ git clone https://github.com/Thomasssb1/reddit-2-video.git
>```
>Activate the repo so it can be used throughout your system
>```sh
>$ dart pub global activate --source path reddit-2-video
>```
>You can now run reddit-2-video throughout your file system and rebuild whenever you change the source code.
</details>

## Usage
Call the method in the command line like so
```sh
$ reddit-2-video --subreddit AskReddit
```
You can add more args to customise the output to your liking as talked about below.

## Commands
To use this, you need to use the command reddit-2-video along with arguments to generate a video. <br>
The only **required** argument is `subreddit`.
<br>
There are many other options which can be used in your command.<br>
You can use the `-help` flag to see them all or view them in detail on the [wiki](https://github.com/Thomasssb1/reddit-2-video/wiki/Documentation).

## Dependencies
**This only applies if you are building the project yourself, you do not need this if you are installing from [releases](https://github.com/Thomasssb1/reddit-2-video/releases)**<br>
Required for usage: [ffmpeg](https://ffmpeg.org/about.html), [dart](https://dart.dev/) 3.0.5.
Run this single command if using a linux platform that supports apt-get.
```sh
$ apt-get install ffmpeg dart
```
For other platforms, check the individual installing guides. If your platform is not Windows or MacOS, then check the other option which contains a guide to every supported platform.<br>
<b>ffmpeg: [Windows](https://www.gyan.dev/ffmpeg/builds/), [MacOS](https://evermeet.cx/ffmpeg/), [Other](https://ffmpeg.org/download.html)<br>
dart: [Installation guide](https://dart.dev/get-dart#install) for Windows, Linux and MacOS.<br>
</b>
You will also need [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions) setup if you plan on using AWS-Polly to generate TTS.

### Help
Use the option `--help` for more help and information.
