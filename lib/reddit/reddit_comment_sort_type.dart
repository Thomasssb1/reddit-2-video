enum RedditCommentSortType {
  best(name: 'best'),
  top(name: 'top'),
  newest(name: 'new'),
  controversial(name: 'controversial'),
  old(name: 'old'),
  qanda(name: 'q&a');

  const RedditCommentSortType({
    required this.name,
  });

  final String name;

  static RedditCommentSortType? called(String name) {
    switch (name) {
      case 'best':
        return RedditCommentSortType.best;
      case 'top':
        return RedditCommentSortType.top;
      case 'new':
        return RedditCommentSortType.newest;
      case 'controversial':
        return RedditCommentSortType.controversial;
      case 'old':
        return RedditCommentSortType.old;
      case 'q&a':
        return RedditCommentSortType.qanda;
      default:
        return null;
    }
  }
}
