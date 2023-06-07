import 'dart:convert';

import 'package:http/http.dart' as http;

Future<Map> getArticleInfo(subreddit, sort) async {
  var client = http.Client();
  late Map data;
  try {
    var response =
        await client.get(Uri.https("reddit.com", "/r/$subreddit/$sort.json"));
    data = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
  } catch (e) {
    // do error handling
  } finally {
    client.close();
  }
  return data;
}

void generateVideo() {
  // gen video
}
