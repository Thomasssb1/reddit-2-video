# reddit2video
A simple command line script for generating a tiktok-style video with a large variety of different options to change the output. <br>
At the moment, it is in development and currently has no easy way to setup CLI command usage without cloning the repository yourself.

## Setup
This setup may be a bit tedious for now as it is still currently under development. However, you can still use this project for your own use whilst it is in development. <br>
Clone the repository
``` 
$ git clone https://github.com/Thomasssb1/reddit2video.git
```
Activate the repo so it can be used throughout your system
```
$ cd reddit2video
$ pub global activate --source path .
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
-s -sort 
  Options are: hot, new, top, rising
--[no-]nsfw
--c 
  Minimum number of comments (defaults to "8")
-d, --[no-]downvotes 
  Display downvotes on overlay
-a, --[no-]awards 
  Display awards on overlay
-v, --video-path 
  (defaults to video inside of defaults folder)
-m, --music-path        
--[no-]spoiler 
  Add a spoiler to the video which hides the image/text before showing for 3s
--[no-]date  
  Add date of when the post was uploaded to the overlay.
-o, --output 
  Location where the generated file will be stored.
--file-type 
    Options are: mp4, avi, mov, flv
--framerate 
  The framerate used when generating the video - using a higher framerate will take longer and produce a larger file. 
    Options are: 15, 30, 45, 60, 75, 120, 144
--timezone 
  Timezone to use when adding date to the post overlay 
    Options are: 'GMT', 'ECT', 'EET', 'PST', 'CST', 'EST'
```
At the moment, the only supported args are:
subreddit, sort, nsfw, c, o, file-type, framerate and comment-sort (undocumented).
### Help
Use the flag `--help` or `-h` for more help and information.
