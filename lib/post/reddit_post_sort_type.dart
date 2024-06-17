enum RedditPostSortType {
  best(name: 'best'),
  hot(name: 'hot'),
  newest(name: 'newest'),
  top(name: 'top'),
  rising(name: 'rising');

  const RedditPostSortType({
    required this.name,
  });

  final String name;

  static RedditPostSortType? called(String name) {
    switch (name) {
      case 'best':
        return RedditPostSortType.best;
      case 'hot':
        return RedditPostSortType.hot;
      case 'new':
        return RedditPostSortType.newest;
      case 'top':
        return RedditPostSortType.top;
      case 'rising':
        return RedditPostSortType.rising;
      default:
        return null;
    }
  }
}
