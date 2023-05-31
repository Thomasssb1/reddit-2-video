using HTTP
using DotEnv
import JSON

DotEnv.config(path="info.env")
test = ENV["TEST_DATA"]
println(test)

commentlink = "https://www.reddit.com/comments/$rarticleid.json"

function request(link::String)
    r = HTTP.request("GET", link;)
    println(r.status)
    JSON.parse(String(r.body))
end

function getarticleinfo(rsort::String, rsubreddit::String)
    data = request("https://www.reddit.com/r/$rsubreddit/$rsort.json?")

end

# -s for sort
# -r for subreddit
# --nsfw for nsfw enabled
# -c for minimum number of comments (default 8)

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

#request(articlelink)