class Lexicon {
  final String _grapheme;
  final String _alias;

  const Lexicon({required String grapheme, required String alias})
      : _grapheme = grapheme,
        _alias = alias;

  String get grapheme => _grapheme;
  String get alias => _alias;

  @override
  String toString() {
    return 'grapheme: $_grapheme, alias: $_alias';
  }
}
