# <img src="docs/assets/images/icon.svg" alt="reddit-2-video icon" width="32" valign="middle"> reddit-2-video

[![Docs](https://img.shields.io/badge/docs-GitHub%20Pages-336699)](https://thomasssb1.github.io/reddit-2-video/) [![CI](https://github.com/Thomasssb1/reddit-2-video/actions/workflows/ci.yml/badge.svg)](https://github.com/Thomasssb1/reddit-2-video/actions/workflows/ci.yml) [![Coverage](https://img.shields.io/badge/coverage-91.68%25-green)](https://github.com/Thomasssb1/reddit-2-video/actions/workflows/ci.yml) [![Release](https://img.shields.io/github/v/release/Thomasssb1/reddit-2-video?display_name=tag)](https://github.com/Thomasssb1/reddit-2-video/releases) [![License](https://img.shields.io/github/license/Thomasssb1/reddit-2-video)](https://github.com/Thomasssb1/reddit-2-video/blob/master/LICENSE)

A highly customisable command line script for generating a tiktok-style video offering granular controls over output settings. <br>

View the docs [here](https://thomasssb1.github.io/reddit-2-video/) for information on how to use reddit-2-video.

## Setup

The easiest way to get started is to download one of the [releases](https://github.com/Thomasssb1/reddit-2-video/releases). Release bundles are built for Windows, macOS, and Linux, and ship as a `reddit-2-video/` folder containing `bin/reddit-2-video(.exe)`, `defaults/`, and `.temp/`.<br>Something going wrong? You may need to [compile yourself](https://github.com/Thomasssb1/reddit-2-video/tree/master#dependencies).<br><br>
**Add the folder to path**<br>
This is different across each operating system. [This gist](https://gist.github.com/nex3/c395b2f8fd4b02068be37c961301caa7) shows the different methods to add a folder to path - follow the steps but use the folder `reddit-2-video/bin` that you cloned. You need to add the full path to `reddit-2-video/bin` to your system path in environmental variables.<br><br>
**Install dependencies**<br>
If you do not have the required runtime tools installed, you can run the following command in an _elevated shell_.

```zsh
$ reddit-2-video install
```

This will help you check the core runtime dependencies required to run reddit-2-video. If this does not work, you can install these prerequisites [manually](https://github.com/Thomasssb1/reddit-2-video#dependencies).

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
>You can now run reddit-2-video throughout your file system and rebuild whenever you change the source code.<br>
>**Contributing?**
>
>Add the following filter to ignore checked in file changes touched by the program unless necessary:
>```zsh
>$ git config filter.cleanJsonState.clean "jq '(if has(\"_last_updated\") then ._last_updated=null else . end) | (if has(\"visited\") then .visited=[] else . end)'"
>$ git config filter.cleanJsonState.smudge cat
>$ git config filter.cleanJsonState.required true
>$ git add --renormalize .temp/visited_log.json defaults/lexicons/lexemes.config.json
>```
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
> $ reddit-2-video --subreddit AskReddit --type comments --count 10 --alternate=on,on --title-color H0000FF --output example-1
> ```
>
> The `--count` option is used to tell reddit-2-video to only use posts that have a minimum of 10 comments.<br>
> Using the `--alternate` option is ideal when creating videos which involve multiple users interacting, for more info on how it works check the docs.

</details>
<details>
    <summary>Generate a horror story from r/nosleep</summary><br>

> The below command uses the `--horror` flag in order to change the pitch of the voice to better work for creepy stories.
>
> ```zsh
> $ reddit-2-video --subreddit nosleep --horror --post-confirmation --music <path-to-music> --youtube-short --output example-2.mp4
> ```
>
> The command also uses the `--post-confirmation` flag so that you get to check each post before the video is generated. The `--music` option is used to add an eerie background ambience, `--youtube-short` to split each video into 1 minute segments for youtube short upload.

</details>
<details>
    <summary>Generate 5 videos from r/pettyrevenge posts </summary><br>

> The below command uses the `--repeat` option in order to generate 5 videos from the subreddit specified.
>
> ```zsh
> $ reddit-2-video --subreddit pettyrevenge --repeat 3 --no-nsfw --censor --sort top --output example-3
> ```
>
> This command also sets the following flags `--no-nsfw` to allow nsfw content and `--censor` to change what is spoken based on the lexemes provided in `defaults/lexicons/lexeme.xml`. The `--sort` flag will pull posts from r/pettyrevenge in top-sorted order.

</details>
<details>
    <summary>Generate a video containing 3 jokes from r/dadjokes</summary><br>

> The below command sets `--type multi` in order to generate a video using multiple posts in one - ignoring comments.
>
> ```zsh
> $ reddit-2-video --subreddit dadjokes --type multi --count 3 --sort rising --framerate 75 --output example-4.mp4
> ```
>
> This command also sets the `sort` option to rising and the `framerate` to 75.

</details>
<details>
    <summary>Generate a video from a reddit post url</summary><br>

> The below command passes a link instead of a subreddit in order to generate a video for a specific post.
>
> ```zsh
> $ reddit-2-video --subreddit https://www.reddit.com/r/TrueOffMyChest/comments/t26b1s/i_found_out_that_my_boyfriend_of_2_years_is/ --end-card <path-to-gif> -v --output example-5
> ```
>
> This command also adds an end card to the end of the video by using the gif passed to it (in this case it is the placeholder _\<path-to-gif\>_). It also sets verbosity to true in order to see extra debugging information whilst generating the video.

</details>

## Dependencies

Required for usage: [ffmpeg](https://ffmpeg.org/about.html), [yt-dlp](https://github.com/yt-dlp/yt-dlp), [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions)
If you are using a system which supports `apt-get`, you can run the following command to install ffmpeg and dart.
You only need to install dart if you are compiling yourself - as explained below.

```zsh
$ apt-get install ffmpeg dart
```

To build the packaged release folder, you will need [dart](https://dart.dev/) >= 3.0.5. Run the following command whilst in the `reddit-2-video` folder.

```zsh
$ dart run tool/build_release.dart --output-root build/reddit-2-video
```

<details>
    <summary>
    However, <b>if you are using windows</b> you need to add the .exe file extension for it to work
    </summary>

> Run the below command if you are on windows
>
> ```sh
> $ dart run tool/build_release.dart --output-root build/reddit-2-video --executable-name reddit-2-video.exe
> ```

</details>

The build script refuses unsafe output roots such as `.` or the repository root. Use a dedicated directory such as `build/reddit-2-video`.

This creates the same structure used by release builds: `reddit-2-video/bin/reddit-2-video(.exe)`, `reddit-2-video/defaults/`, and `reddit-2-video/.temp/visited_log.json`.

You will also need [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions) setup if you plan on using AWS-Polly to generate TTS, which currently is the only option for TTS generation.

### Help

Use the option `--help` or `-h` for more help and information.
