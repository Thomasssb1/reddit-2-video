import 'dart:convert';
import 'dart:io';
import 'package:reddit_2_video/utils/http.dart';
import 'package:reddit_2_video/utils/log.dart';
import 'package:reddit_2_video/utils/prettify.dart';
import 'package:http/http.dart' as http;
import 'package:deep_pick/deep_pick.dart';
import 'package:reddit_2_video/utils/generate_files.dart';

/// get the data from the post such as title and body text
Future<(String, List<dynamic>)> getPostData(
  String subreddit,
  String sort,
  bool nsfw,
  int commentCount,
  String commentSort,
  bool postConfirm,
  String type,
) async {
  // make client so that multiple https requests can be made easily
  var client = http.Client();
  List<dynamic> postData = [];
  // check if the subreddit arg passed is a link
  bool isLink = validateLink(subreddit);
  // make a link from the subreddit if it is not already a link
  Uri linkUri = Uri.https("reddit.com", "/r/$subreddit/$sort.json");

  if (isLink) {
    // update the uri
    linkUri = Uri.parse("$subreddit.json");
    if (type == 'multi') {
      // can't use a singular link if you want to have multiple posts
      printError("Unable to use multi type with a direct link to a post, use a subreddit instead or change type.");
      exit(1);
    }
  }

  late String id;

  // send a get request to the link
  var response = await client.get(Uri.https(linkUri.authority, linkUri.path));
  // check if the response returned is valid otherwise exit with an error
  bool valid = checkStatusCode(response, "Post");

  if (valid) {
    // generate json data
    var json = jsonDecode(utf8.decode(response.bodyBytes));
    // get all of the necessary data
    // title, id, body, upvotes, created, spoiler, media, nsfw and comment count
    List<dynamic> data = pick(isLink ? json[0] : json, 'data', 'children')
        .asListOrEmpty((p0) {
          if ((!p0('data', 'stickied').asBoolOrFalse())) {
            // ignore any comments pinned to the subreddit (normally mod posts)
            if ((p0('data', 'num_comments').asIntOrNull() ?? 0) >= commentCount) {
              // check if the post has enough comments specified with -c
              if (isLink ? true : nsfw) {
                // if the user has nsfw tag set to true (default)
                return {
                  'title': p0('data', 'title').required().asString(),
                  'id': p0('data', 'id').asStringOrNull(),
                  'subreddit_id': p0('data', 'subreddit_id').asStringOrNull(),
                  'body': p0('data', 'selftext').asStringOrNull() ?? '',
                  'upvotes': p0('data', 'ups').asIntOrNull() ?? 0,
                  'created': p0('data', 'created').letOrNull(
                      (pick) => DateTime.fromMillisecondsSinceEpoch(((pick.asDoubleOrNull() ?? 0.0) * 1000).round())),
                  'spoiler': p0('data', 'spoiler').asBoolOrFalse(),
                  'media': p0('data', 'media').asBoolOrFalse(),
                  'nsfw': p0('data', 'over_18').asBoolOrNull() ?? false,
                  'comments': p0('data', 'num_comments').asIntOrNull() ?? 0
                };
              } else {
                // if the user has nsfw tag set to false
                if (!(p0('data', 'over_18').asBoolOrNull() ?? true)) {
                  // if the post has nsfw tag set to false
                  return {
                    'title': p0('data', 'title').required().asString(),
                    'id': p0('data', 'id').asStringOrNull(),
                    'subreddit_id': p0('data', 'subreddit_id').asStringOrNull(),
                    'body': p0('data', 'selftext').asStringOrNull() ?? '',
                    'upvotes': p0('data', 'ups').asIntOrNull() ?? 0,
                    'created': p0('data', 'created').letOrNull(
                        (pick) => DateTime.fromMicrosecondsSinceEpoch((pick.asDoubleOrNull() ?? 0.0).round())),
                    'spoiler': p0('data', 'spoiler').asBoolOrFalse(),
                    'media': p0('data', 'media').asBoolOrFalse(),
                    'nsfw': false,
                    'comments': p0('data', 'num_comments').asIntOrNull() ?? 0
                  };
                }
              }
            }
          }
          // filter out any null values from the values returned
        })
        .where((element) =>
            element != null &&
            element['id'] != null &&
            checkLog("${element['subreddit_id']}-${element['id']}") == false)
        .toList();
    if (data.isEmpty) {
      if (isLink) {
        printError(
            "The link provided in --subreddit has already had a video been generated previously or the number of comments on the post is too little as specified by the --count option.\n If you have already generated a video for this post you can remove this from the log by running reddit-2-video flush with the -p argument supplied, or change the minimum number of comments required by changing the --count option.");
      } else {
        printError("No posts could be found for the subreddit. Try again with another subreddit.");
      }
      exit(0);
    }
    // if the type is not multi and the user does not need to select a post
    if (type != 'multi' && !postConfirm) {
      // get the first post
      postData = [data[0]];
    }
    // if the user wants to confirm the post and the subreddit arg is not a link
    if (postConfirm && !isLink) {
      // iterate through each post collected previously
      for (final post in data) {
        // output relevant information
        printUnderline("${post['title']}\n");
        print("\x1b[32mUpvotes: ${post['upvotes']}     \x1b[33mComments: ${post['comments']} \x1b[0m\n");
        print(
            "Created: ${post['created']}, ${post['spoiler'] ? 'This post \x1b[31mis\x1b[0m marked as a spoiler' : ''}\n");
        if (post['media']) {
          print("Media: ${post['media']}\n");
        }
        if (nsfw) {
          print("This post is${post['nsfw'] ? '' : ' \x1b[31mnot\x1b[0m'} marked as NSFW.");
        }
        printUnderline("Post ${data.indexOf(post) + 1}/${data.length}.");
        print("Do you want to see the body of the post? [\x1b[32my\x1b[0m/\x1b[31mN\x1b[0m] ");
        // read the cli for what the user entered
        String showBody = stdin.readLineSync() ?? 'n';
        print(showBody);
        // if the user entered yes
        if (showBody.toLowerCase() == 'y') {
          print(post['body']);
        }
        print("Do you want to generate a video for this post? [\x1b[32my\x1b[0m/\x1b[31mN\x1b[0m] ");
        if (type == 'multi') {
          print("You can also enter 'skip' to skip all remaining posts. ");
        }
        // read the cli for what the user entered
        String continueGeneration = stdin.readLineSync() ?? 'n';
        // if the user entered yes
        if (continueGeneration.toLowerCase() == 'y') {
          // add post to postData
          postData.add(post);
          // if the type is not multiple then break the loop as only one post can be selected
          if (type != 'multi') {
            break;
          }
        } // if the user entered skip and the type selected is multi
        else if (continueGeneration.toLowerCase() == 'skip' && type == 'multi') {
          break;
        } // if the user entered no or otherwise
        else {
          print("Continuing to find a new post...\n");
          // if the post is the last post / if the user hasn't selected any posts but have multi type
          if (post == data.last && type != 'multi') {
            printError(
                "All posts have been searched for the subreddit $subreddit, try again later or use a different sort term..");
            exit(1);
          }
        }
      }
    }

    if (type == 'comments') {
      // send a new request to get all comments for the post
      var commentResponse = await client.get(Uri.https(
          "reddit.com", isLink ? linkUri.path : "/r/$subreddit/comments/${data[0]['id']}.json", {"sort": commentSort}));
      // check if the response returned is valid otherwise exit with an error
      bool valid = checkStatusCode(response, "Comment");

      if (valid) {
        // generate json data
        var commentJson = jsonDecode(utf8.decode(commentResponse.bodyBytes));
        // select the body text and author
        // filter to remove comments where body is > 512 and any deleted comments
        List<dynamic> commentData = pick(commentJson, 1, 'data', 'children')
            .asListOrEmpty((p0) {
              return {
                'body': p0('data', 'body').asStringOrNull(),
                'author': p0('data', 'author').asStringOrNull() ?? "Anonymous"
              };
            })
            .where((element) =>
                element['body'] != null &&
                (element['body'] ??= "").length <= 512 &&
                element['body'] != "[removed]" &&
                element['collapsed_reason_code'] != "DELETED")
            .toList();
        // reduce the number of comments
        commentData =
            commentData.sublist(0, commentData.length < 3 * commentCount ? commentData.length : 3 * commentCount);
        // combine postData about comments with post and reduce the data
        id = "${postData[0]['subreddit_id']}-${postData[0]['id']}";
        generateFiles(id);
        postData = postData.map((e) => [e['title'], e['body']]).toList();
        postData[0].addAll(commentData.map((e) => e['body']).toList());
      } // if not valid
      else {
        exit(1);
      }
    } else if (type == 'post') {
      // reduce the data to only contain title and body
      id = "${postData[0]['subreddit_id']}-${postData[0]['id']}";
      generateFiles(id);
      postData = postData.map((e) => [e['title'], e['body']]).toList();
    } else if (type == 'multi') {
      // if the user does not have postConfirm on
      if (!postConfirm) {
        // if the data selected has less than the minimum number of posts (commentCount affects number of posts too)
        if (data.length < commentCount) {
          printWarning(
              "Currently unable to retrieve the specified number of posts ($commentCount). Generating video anyways with ${data.length} posts instead.");
        } // reduce the number of posts
        else {
          postData = data.sublist(0, commentCount);
        }
      } else {
        // if the user selected no posts
        if (postData.isEmpty) {
          printError("You haven't selected any posts. Retry but ensure that atleast one post is selected.");
          exit(1);
        }
        // if the user selected too little posts as specified in commentCount arg
        if (postData.length < commentCount) {
          printWarning(
              "You haven't selected enough posts as specified by the count option ($commentCount). Generating video with only the posts that you have selected.");
        } else {
          // if the user selected too many posts
          if (postData.length > commentCount) {
            printWarning(
                "You have selected too many posts as specified by the count option ($commentCount). Generating video with only $commentCount posts instead. You can change this by editing the -count option.");
          }
          // reduce the number of posts
          postData = postData.sublist(0, commentCount);
        }
      }
      // write each id from each post to the log and reduce data
      id = "${postData[0]['subreddit_id']}-${postData.map((e) => e['id']!).toList().join('-')}";
      generateFiles(id);
      postData = postData.map((e) => [e['title'], e['body']]).toList();
    }
    // end the client
    client.close();
    return (id, postData);
  } else {
    exit(1);
  }
}
