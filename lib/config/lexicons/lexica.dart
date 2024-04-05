import 'package:reddit_2_video/config/config_item.dart';
import 'package:reddit_2_video/config/lexicons/lexicon.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:xml/xml.dart';

class Lexica extends ConfigItem {
  double xmlVersion;
  String languageCode;
  List<Lexicon> lexicons;

  Lexica({
    required this.xmlVersion,
    required this.languageCode,
    required this.lexicons,
    super.path = 'defaults/config/lexica.xml',
  });

  Lexica.fromXML({
    required super.path,
    this.xmlVersion = 1.0,
    this.languageCode = "en-US",
    this.lexicons = const [],
  }) {
    if (!path.existsSync()) {
      throw FileNotFoundException("File not found", path);
    }
    XmlDocument document = XmlDocument.parse(path.readAsStringSync());

    String xmlVersion =
        document.firstElementChild?.getAttribute("version") ?? "1.0";
    String languageCode =
        document.getElement("lexicon")?.getAttribute("xml:lang") ?? "en-US";

    List<Lexicon> lexicons = List.empty();

    document.findAllElements("lexeme").forEach((lex) {
      try {
        String grapheme = lex.findElements("grapheme").last.innerText;
        String alias = lex.findElements("alias").last.innerText;

        Lexicon lexicon = Lexicon(grapheme: grapheme, alias: alias);
        lexicons.add(lexicon);
      } on StateError {
        throw InvalidFileFormatException("Invalid file format", path);
      }
    });
    try {
      this.xmlVersion = double.parse(xmlVersion);
    } on FormatException {
      throw InvalidFileFormatException("Invalid file format", path);
    }
    this.languageCode = languageCode;
    this.lexicons = lexicons;
  }
}
