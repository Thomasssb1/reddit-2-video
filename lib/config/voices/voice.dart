enum TTSType {
  polly,
}

class Voice {
  final String id;
  late final bool _neural;
  late final bool _standard;
  late final bool _newscaster;
  bool disabled;
  final TTSType _type = TTSType.polly;

  Voice({
    required this.id,
    bool neural = false,
    bool standard = true,
    bool newscaster = false,
    this.disabled = false,
  })  : _neural = neural,
        _standard = standard,
        _newscaster = newscaster;

  Voice.standard() : this(id: "Brian", neural: true, standard: true);

  bool get neural => _neural;
  bool get standard => _standard;
  bool get newscaster => _newscaster;
  bool get isAWSPolly => _type == TTSType.polly;
  TTSType get type => _type;

  @override
  String toString() {
    return id;
  }

  @override
  bool operator ==(Object other) {
    return (other is Voice) && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
