enum RedditVideoType {
  multi,
  post,
  comments;

  static RedditVideoType? called(String name) {
    switch (name) {
      case 'multi':
        return RedditVideoType.multi;
      case 'post':
        return RedditVideoType.post;
      case 'comments':
        return RedditVideoType.comments;
      default:
        return null;
    }
  }
}
