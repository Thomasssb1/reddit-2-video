using HTTP
using DotEnv
import JSON

DotEnv.config(path="info.env")
test = ENV["TEST_DATA"]
println(test)

#commentlink = "https://www.reddit.com/comments/$rarticleid.json"

function request(link::String)
    r = HTTP.request("GET", link;)
    println(r.status)
    JSON.parse(String(r.body))
end

function getarticleinfo(rsort, rsubreddit)
    data = request("https://www.reddit.com/r/$rsubreddit/$rsort.json?")
    #print(data)
    title = data["data"]["children"][1]["data"]["title"]
    upvotes = data["data"]["children"][1]["data"]["ups"]
    nsfw = data["data"]["children"][1]["data"]["over_18"]
    author = data["data"]["children"][1]["data"]["author"]

    subname = data["data"]["children"][1]["data"]["subreddit_name_prefixed"]

    print(title)
    sleep(5)
end

#request(articlelink)