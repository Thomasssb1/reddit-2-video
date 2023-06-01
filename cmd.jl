include("main.jl")
# -s for sort
# -r for subreddit
# --nsfw for nsfw enabled
# -c for minimum number of comments (default 8)
# --downvotes for enabling downvote calculation
# --awards enabling rewards on overlay
# -v path to your own video
# -m path to mp4 file for music
# --spoiler add spoiler which hides the image/text before showing for 3s
# --date add date to the overlay
# -t change timezome (default is utc)
# -o output location
# -file-type change output file type (mp4, avi etc)
# -framerate specify framerate

function getinputs()
    print("> ")
    info = readline()
    if contains(info, "-s") || contains(info, "-S")
        rsort = match(r"(?<=\b(?i)[-s]\s)(\w+)", info).match
        println(rsort)
    end
    if contains(info, "-r") || contains(info, "-R")
        rsubreddit = match(r"(?<=\b(?i)[-r]\s)(\w+)", info).match
        println(rsubreddit)
    end
    getarticleinfo(rsort, rsubreddit)
end

getinputs();

#command = `cmd /c ffmpeg -f lavfi -i color=size=320x240:duration=10:rate=25:color=blue -vf "drawtext=fontfile=/path/to/font.ttf:fontsize=30:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2:text='Stack Overflow'" output.mp4`
#readchomp(command)