# reddit-2-video

A simple command line script for generating a tiktok-style video with a large variety of different options to change the output. <br>
View the wiki [here](https://github.com/Thomasssb1/reddit-2-video/wiki) for information on how to use reddit-2-video.

## Setup

The easiest way to get started is to download one of the [releases](https://github.com/Thomasssb1/reddit-2-video/releases) but is only compiled for Windows (MacOS and Linux will be compiled on release, for now you will have to compile yourself using `dart compile exe reddit-2-video/bin`).<br>Something going wrong? You may need to [compile yourself](https://github.com/Thomasssb1/reddit-2-video/tree/master#dependencies)<br><br>
**Add the folder to path**<br>
This is different across each operating system. [This gist](https://gist.github.com/nex3/c395b2f8fd4b02068be37c961301caa7) zshows the different methods to add a folder to path - follow the steps but use the folder `reddit-2-video/bin` that you cloned. You need to add the full path to `reddit-2-video/bin` to your system path in environmental variables.<br><br>
**Install dependencies**<br>
If you do not have ffmpeg or [whisper_timestamped](https://github.com/linto-ai/whisper-timestamped), you can run the following command in an _elevated shell_.

```zsh
$ reddit-2-video install
```

This will install ffmpeg and whisper_timestamped that are required to run reddit-2-video. If this does not work, you can install these prerequisites [manually](https://github.com/Thomasssb1/reddit-2-video#dependencies).

<details>
    <summary>For developer builds</summary><br>
    
>Run the following command in your terminal in order to rebuild the executable each time something is changed whilst developing an update. You <u>do not</u> need to add the <b>reddit-2-video/bin</b> folder to path like normal.<br><br>
>
>Clone the repository
>```zsh 
>$ git clone https://github.com/Thomasssb1/reddit-2-video.git
>```
>Activate the repo so it can be used throughout your system
>```zsh
>$ dart pub global activate --source path reddit-2-video
>```
>Ensure that whenever you run the command, you add the `--dev, -d` flag to change the path to pwd.<br>
>You can now run reddit-2-video throughout your file system and rebuild whenever you change the source code.
</details>

## Usage

Call the method in the command line like so

```zsh
$ reddit-2-video --subreddit AmItheAsshole
```

You can add more args to customise the output to your liking as talked about below.

## Commands

To use this, you need to use the command reddit-2-video along with arguments to generate a video. <br>
The only **required** argument is `subreddit`.
<br>
There are many other options which can be used in your command. You can get started by using this command (note that letter case does not matter):

```zsh
reddit-2-video --subreddit AmItheAsshole
```

The above command will fetch videos from the [AmItheAsshole subreddit](https://www.reddit.com/r/AmItheAsshole/) and compile them into a video using all default options set by reddit-2-video. I would recommend looking at the [wiki](https://github.com/Thomasssb1/reddit-2-video/wiki/Documentation) in order to customise to your needs.<br>
You can also use the `-help` flag to view all visible options.

### Examples

Click to expand each of the examples.

<details open>
<summary>Generate a video from an r/AskReddit post</summary><br>

> The below command uses the `--type comments` option in order to compile the video using comments and post title.<br>
>
> ```zsh
> $ reddit-2-video --subreddit AskReddit --type comments --count 10 --alternate=on,on,H0000FF
> ```
>
> The `--count` option is used to tell reddit-2-video to only use posts that have a minimum of 10 comments.<br>
> Using the `--alternate` option is ideal when creating commands which involve multiple users interacting, for more info on how it works, check [here](https://github.com/Thomasssb1/reddit-2-video/wiki/Documentation#flags--options)

</details>
<details>
    <summary>Generate a horror story from r/nosleep</summary><br>

> The below command uses the `--horror` flag in order to change the pitch of the voice to better work for creepy stories.
>
> ```zsh
> $ reddit-2-video --subreddit nosleep --horror --post-confirmation
> ```
>
> The command also uses the `--post-confirmation` flag so that you get to check each post before the video is generated.

</details>
<details>
    <summary>Generate 5 videos from r/pettyrevenge posts </summary><br>

> The below command uses the `--repeat` option in order to generate 5 videos from the subreddit specified.
>
> ```zsh
> $ reddit-2-video --subreddit pettyrevenge --repeat 5 --no-nsfw --youtube-short --censor
> ```
>
> This command also sets the following flags `--no-nsfw` to allow nsfw content, `--youtube-short` to split each video into 1 minute segments for youtube short upload and `--censor` to change what is spoken based on the lexemes provided in `defaults/lexicons/lexeme.xml`.

</details>
<details>
    <summary>Generate a video containing 3 jokes from r/dadjokes</summary><br>

> The below command sets `--type multi` in order to generate a video using multiple posts in one - ignoring comments.
>
> ```zsh
> $ reddit-2-video --subreddit dadjokes --type multi --sort rising --framerate 75
> ```
>
> This command also sets the `sort` option to rising and the `framerate` to 75.

</details>
<details>
    <summary>Generate a video from a reddit post url</summary><br>

> The below command passes a link instead of a subreddit in order to generate a video for a specific post.
>
> ```zsh
> $ reddit-2-video --subreddit https://www.reddit.com/r/TrueOffMyChest/comments/1850nn6/my_husband_is_cheating_on_me_with_our_best_friend/ --end-card <path-to-gif> -v
> ```
>
> This command also adds an end card to the end of the video by using the gif passed to it (in this case it is the placeholder _<path-to-gif>_). It also sets verbosity to true in order to see extra debugging information whilst generating the video.

</details>

## Dependencies

Required for usage: [ffmpeg](https://ffmpeg.org/about.html), [whisper_timestamped](https://github.com/linto-ai/whisper-timestamped)
If you are using a system which supports `apt-get`, you can run the following command to install ffmpeg and dart.
You only need to install dart if you are compiling yourself - as explained below.

```zsh
$ apt-get install ffmpeg dart
```

To install whisper_timestamped, you need to have ffmpeg and python installed. Check how to install [here](https://github.com/linto-ai/whisper-timestamped#installation).<br>
To build the exe, you will need to compile which requires [dart](https://dart.dev/) 3.0.5. Run the following command whilst in the `reddit-2-video` folder.

```zsh
$ dart compile exe bin/reddit-2-video.dart --output=bin/reddit-2-video
```
<details>
    <summary>
    However, <b>if you are using windows</b> you need to add the .exe file extension for it to work
    </summary>

> Run the below command if you are on windows
>
> ```sh
> $ dart compile exe bin/reddit-2-video.dart --output=bin/reddit-2-video.exe
> ```
</details>

You will also need [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions) setup if you plan on using AWS-Polly to generate TTS, which currently is the only option for TTS generation.

### Help

Use the option `--help` or `-h` for more help and information.
