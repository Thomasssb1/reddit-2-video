enum TTSType {
  polly,
}

enum Voice {
  lotte(id: "Lotte"),
  maxim(id: "Maxim"),
  ayanda(id: "Ayanda"),
  salli(id: "Salli"),
  ola(id: "Ola"),
  arthur(id: "Arthur"),
  ida(id: "Ida"),
  tomoko(id: "Tomoko"),
  remi(id: "Remi"),
  geraint(id: "Geraint"),
  miguel(id: "Miguel"),
  elin(id: "Elin"),
  lisa(id: "Lisa"),
  giorgio(id: "Giorgio"),
  marlene(id: "Marlene"),
  ines(id: "Ines"),
  kajal(id: "Kajal"),
  zhiyu(id: "Zhiyu"),
  zeina(id: "Zeina"),
  suvi(id: "Suvi"),
  karl(id: "Karl"),
  gwyneth(id: "Gwyneth"),
  joanna(id: "Joanna"),
  lucia(id: "Lucia"),
  cristiano(id: "Cristiano"),
  astrid(id: "Astrid"),
  andres(id: "Andres"),
  vicki(id: "Vicki"),
  mia(id: "Mia"),
  vitoria(id: "Vitoria"),
  bianca(id: "Bianca"),
  chantal(id: "Chantal"),
  raveena(id: "Raveena"),
  daniel(id: "Daniel"),
  amy(id: "Amy"),
  liam(id: "Liam"),
  ruth(id: "Ruth"),
  kevin(id: "Kevin"),
  brian(id: "Brian"),
  russell(id: "Russell"),
  aria(id: "Aria"),
  matthew(id: "Matthew"),
  aditi(id: "Aditi"),
  zayd(id: "Zayd"),
  dora(id: "Dora"),
  enrique(id: "Enrique"),
  hans(id: "Hans"),
  hiujin(id: "Hiujin"),
  carmen(id: "Carmen"),
  sofie(id: "Sofie"),
  ivy(id: "Ivy"),
  ewa(id: "Ewa"),
  maja(id: "Maja"),
  gabrielle(id: "Gabrielle"),
  nicole(id: "Nicole"),
  filiz(id: "Filiz"),
  camila(id: "Camila"),
  jacek(id: "Jacek"),
  thiago(id: "Thiago"),
  justin(id: "Justin"),
  celine(id: "Celine"),
  kazuha(id: "Kazuha"),
  kendra(id: "Kendra"),
  arlet(id: "Arlet"),
  ricardo(id: "Ricardo"),
  mads(id: "Mads"),
  hannah(id: "Hannah"),
  mathieu(id: "Mathieu"),
  lea(id: "Lea"),
  sergio(id: "Sergio"),
  hala(id: "Hala"),
  tatyana(id: "Tatyana"),
  penelope(id: "Penelope"),
  naja(id: "Naja"),
  olivia(id: "Olivia"),
  ruben(id: "Ruben"),
  laura(id: "Laura"),
  takumi(id: "Takumi"),
  mizuki(id: "Mizuki"),
  carla(id: "Carla"),
  conchita(id: "Conchita"),
  jan(id: "Jan"),
  kimberly(id: "Kimberly"),
  liv(id: "Liv"),
  adriano(id: "Adriano"),
  lupe(id: "Lupe"),
  joey(id: "Joey"),
  pedro(id: "Pedro"),
  seoyeon(id: "Seoyeon"),
  emma(id: "Emma"),
  niamh(id: "Niamh"),
  stephen(id: "Stephen");

  const Voice({
    required this.id,
  });

  final String id;
  final TTSType _type = TTSType.polly;

  static int _currentVoice = ++_currentVoice % Voice.values.length;
  static Voice get current => Voice.values[_currentVoice];
  static void next() => _currentVoice = ++_currentVoice % Voice.values.length;
  static void set(Voice voice) => _currentVoice = Voice.values.indexOf(voice);

  static Voice called(String id) {
    return Voice.values
        .firstWhere((e) => e.id == id, orElse: () => Voice.matthew);
  }

  bool get isAWSPolly => _type == TTSType.polly;

  TTSType get type => _type;
}
