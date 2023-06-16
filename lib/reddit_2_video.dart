import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:deep_pick/deep_pick.dart';

Future<List> getArticleInfo(subreddit, sort) async {
  // make the network request
  var client = http.Client();
  late final json;
  try {
    var response =
        await client.get(Uri.https("reddit.com", "/r/$subreddit/$sort.json"));
    json = jsonDecode(utf8.decode(response.bodyBytes));
  } catch (e) {
    // do error handling
  } finally {
    client.close();
  }
  List<dynamic> data = pick(json, 'data', 'children').asListOrEmpty((p0) {
    print(p0);
    return p0('data').required().asString();
  });
  print(data);
  print(data.length);
  return data;
}

void generateVideo() {
  // gen video
}
