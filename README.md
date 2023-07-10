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

## Commands
To use this, you need to use the command reddit-2-video along with arguments to generate a video. <br>
The only **required** argument is `subreddit`.
<br>
```
--subreddit
-s --sort
Options are: hot (default), new, top, rising
--comment-sort                                                                            
Options are: top (default), best, new, controversial, old, q&a
--c
Minimum number of comments (defaults to 8)
--alternate=<alternate-tts(true/false),alternate-colour(true/false),title-colour(hex)>    
--[no-]post-confirmation
--[no-]nsfw
(defaults to on)
--[no-]spoiler
Add a spoiler to the video which hides the image/text before showing for 3s
--[no-]ntts
Determines whether to use neural tts which is generated locally or googles own TTS which requires internet.
-u --[no-]upvotes
Display upvotes on overlay
-d --[no-]downvotes
Display downvotes on overlay
-a --[no-]awards
Display awards on overlay
-v --video-path=<path>
(defaults to "../defaults/video1.mp4")
--music=<path,volume>
--[no-]date
Add date of when the post was uploaded to the overlay.
-o --output
Location where the generated file will be stored.
--file-type
Options are: mp4 (default), avi, mov, flv
--framerate
The framerate used when generating the video - using a higher framerate will take longer and produce a larger file.
Options are: 15, 30, 45 (default), 60, 75, 120, 144
--[no-]verbose
```
At the moment, the only supported args are:
subreddit, sort, nsfw, c, o, file-type, framerate and comment-sort (undocumented).
### Help
Use the flag `--help` or `-h` for more help and information.
