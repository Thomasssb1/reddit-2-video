# reddit2video
A simple command line script for generating a tiktok-style video with a large variety of different options to change the output. <br>
At the moment, it is in development and currently has no easy way to setup CLI command usage without cloning the repository yourself.

## Dependencies
Required for usage: [ffmpeg](https://ffmpeg.org/about.html), [dart](https://dart.dev/) 3.0.5 and [python](https://www.python.org/) >=3.
Run this single command if using a linux platform that supports apt-get.
```
$ apt-get install ffmpeg dart python3
```
For other platforms, check the individual installing guides. If your platform is not Windows or MacOS, then check the other option which contains a guide to every supported platform.<br>
<b>ffmpeg: [Windows](https://www.gyan.dev/ffmpeg/builds/), [MacOS](https://evermeet.cx/ffmpeg/), [Other](https://ffmpeg.org/download.html)<br>
dart: [Installation guide](https://dart.dev/get-dart#install) for Windows, Linux and MacOS.<br>
python: [Windows](https://www.python.org/downloads/windows/), [MacOS](https://www.python.org/downloads/macos/), [Other](https://www.python.org/download/other/)
</b>

## Setup
This setup may be a bit tedious for now as it is still currently under development. However, you can still use this project for your own use whilst it is in development. <br>
Clone the repository
``` 
$ git clone https://github.com/Thomasssb1/reddit2video.git
```
Activate the repo so it can be used throughout your system
```
$ cd reddit2video
$ dart pub global activate --source path .
```
Call the method in the command line like so
```
$ reddit-2-video --subreddit AskReddit
```
You can add more args as talked about below.

### Warning
The TTS is not currently perfectly lined up with the subtitles. I will be implementing a better solution to match these up **soon**.<br> Any other issues you might face is likely due to the fact I am still developing this, updates will be releasing daily.

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
