extension BooleanConversion on String {
  bool parseBool() {
    return this == 'on';
  }
}
