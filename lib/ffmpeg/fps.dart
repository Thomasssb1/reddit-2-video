enum FPS {
  fps15(value: 15),
  fps30(value: 30),
  fps45(value: 45),
  fps60(value: 60),
  fps75(value: 75),
  fps120(value: 120),
  fps144(value: 144);

  const FPS({required this.value});

  static FPS fpsValue(int value) {
    return FPS.values
        .firstWhere((e) => e.value == value, orElse: () => FPS.fps45);
  }

  final int value;
}
