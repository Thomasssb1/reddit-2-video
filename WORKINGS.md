## How it works

If you want to see in depth how reddit-2-video works then continue reading otherwise, you can read the shortened down statement below:

> reddit-2-video is written 100% in dart and uses the command line to interact with other moving parts in order to create the working process. Currently reddit-2-video relies on [whisper_timestampd]() for correcting subtitle positioning as well as [ffmpeg]() to create the video with a custom set of arguments determined by the user input. Using the reddit api to fetch videos, data is then processed and passed to [AWS Polly]() to create custom neural tts with the ASS (Advanced SubStation Alpha) file format to create subtitles which can be animated and finetuned to change their appearance as need be.

### Why dart?

The first question you may ask - why use [dart]()? Well, the first reason was that I enjoyed writing apps in flutter and so was able to program in dart confidently. Apart from that, I did start this project off using [julia]() but quickly realised it was not suitable, then moving to a combination of dart and [python](), moving to pure dart allowed me to create code that could be compiled into executables using the `dart compile` command. This meant that the end user did not need to have the proprietary programming language installed on their machine.<br>
There is also a large community surrounding dart, with a lot of resources online. Using [pub.dev]() to find libraries to implement into the app ended up making time consuming parts of this project "less" time consuming.

### Using the "reddit api"

### Why use ASS and not SRT?
