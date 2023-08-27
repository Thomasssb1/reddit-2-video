# reddit-2-video
A simple command line script for generating a tiktok-style video with a large variety of different options to change the output. <br>

## Setup
The easiest way to get started is to download one of the [releases](https://github.com/Thomasssb1/reddit-2-video/releases). The release includes all of the dart code precompiled but still requires python & ffmpeg ([see other dependencies](https://github.com/Thomasssb1/reddit-2-video#dependencies)).<br>
<u>Add the folder to path</u>
This is different across each operating system. [This gist](https://gist.github.com/nex3/c395b2f8fd4b02068be37c961301caa7) shows the different methods to add a folder to path - follow the steps but use the folder `reddit-2-video/bin` that you cloned. You need to add the full path to `reddit-2-video/bin` to your system path in environmental variables.<br>
<u>Install dependencies</u>
If you do not have ffmpeg installed nor the required python libraries, you can run the following command in an *elevated shell*.
```sh
$ reddit-2-video install
```
This will install ffmpeg and python libraries that are required. If this does not work, you can install these prerequisites [manually](https://github.com/Thomasssb1/reddit-2-video#dependencies).
<details>
    <summary>For developer builds</summary><br>
    Run the following command in your terminal in order to rebuild the executable each time something is changed whilst developing an update. You <u>do not</u> need to add the <b>reddit-2-video/bin</b> folder to path like normal.<br>

<u>Clone the repository</u>
```sh 
$ git clone https://github.com/Thomasssb1/reddit-2-video.git
```
<u>Activate the repo so it can be used throughout your system</u>
```sh
$ dart pub global activate --source path reddit-2-video
```
</details>

## Usage

Call the method in the command line like so
```sh
$ reddit-2-video --subreddit AskReddit
```
You can add more args as talked about below.

### Warning
The TTS sometimes skips words due to the regex filter used. Any other issues you might face is likely due to the fact I am still developing this, updates will be releasing daily.<br> Another thing to mention is that I do plan on getting this added to several package managers if possible to streamline the setup process.

Right now you need to add a video file named `video1.mp4` inside of the `reddit-2-video/defaults/` folder. This will be the video that  runs in the background.<br> I am planning on adding video integration where you can download videos from a drive within the tool so that you do not need to do this step yourself.

## Commands
To use this, you need to use the command reddit-2-video along with arguments to generate a video. <br>
The only **required** argument is `subreddit`.
<br>
```
--subreddit
    --subreddit
-s, --sort                                                                            [hot (default), new, top, rising]
    --comment-sort                                                                    [top (default), best, new, controversial, old, q&a]
    --count                                                                           Minimum number of comments
                                                                                      (defaults to "8")
    --type
          [comments] (default)                                                        Creates a video that contains a post title, body and a set number of comments for that post.
          [multi]                                                                     Creates a video that contains multiple posts from a single subreddit, not including comments.
          [post]                                                                      Creates a video that only contains a single post with the title and body.

    --alternate=<alternate-tts(on/off),alternate-colour(on/off),title-colour(hex)>    tts - alternate TTS voice for each comment/post (defaults to off)
                                                                                      colour - alternate text colour for each comment/post (defaults to off)
                                                                                      title-colour - determine title colour for post (defaults to #FF0000)
    --[no-]post-confirmation
    --[no-]nsfw                                                                       (defaults to on)
    --[no-]spoiler                                                                    Add a spoiler to the video which hides the image/text before showing for 3s
    --[no-]ntts                                                                       Determines whether to use neural tts which is generated locally or googles own TTS which requires internet.
                                                                                      (defaults to on)
-v, --video-path=<path>                                                               (defaults to "defaults/video1.mp4")
    --music=<path,volume>
-o, --output                                                                          Location where the generated file will be stored.
                                                                                      (defaults to "final")
    --file-type                                                                       [mp4 (default), avi, mov, flv]
    --framerate                                                                       The framerate used when generating the video - using a higher framerate will take longer and produce a larger file.
                                                                                      [15, 30, 45 (default), 60, 75, 120, 144]
    --[no-]verbose
    --[no-]override
```
At the moment, the only supported args are:
subreddit, sort, nsfw, c, o, file-type, framerate and comment-sort (undocumented).
### Help
Use the flag `-help` for more help and information.
## Dependencies
Required for usage: [ffmpeg](https://ffmpeg.org/about.html), [dart](https://dart.dev/) 3.0.5 and [python](https://www.python.org/) >=3.
Run this single command if using a linux platform that supports apt-get.
```sh
$ apt-get install ffmpeg dart python
```
For other platforms, check the individual installing guides. If your platform is not Windows or MacOS, then check the other option which contains a guide to every supported platform.<br>
<b>ffmpeg: [Windows](https://www.gyan.dev/ffmpeg/builds/), [MacOS](https://evermeet.cx/ffmpeg/), [Other](https://ffmpeg.org/download.html)<br>
dart: [Installation guide](https://dart.dev/get-dart#install) for Windows, Linux and MacOS.<br>
python: [Windows](https://www.python.org/downloads/windows/), [MacOS](https://www.python.org/downloads/macos/), [Other](https://www.python.org/download/other/)
</b>