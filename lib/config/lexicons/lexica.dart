import 'package:reddit_2_video/config/config_item.dart';
import 'package:reddit_2_video/config/lexicons/lexicon.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:xml/xml.dart';
import 'dart:io';
export 'package:reddit_2_video/config/lexicons/lexicon.dart';

class Lexica extends ConfigItem {
  double xmlVersion;
  String languageCode;
  List<Lexicon> lexicons;

  Lexica({
    required this.xmlVersion,
    required this.languageCode,
    required this.lexicons,
    required super.prePath,
    super.path = 'defaults/config/lexica.xml',
  });

  Lexica.fromXML({
    required super.path,
    required super.prePath,
    this.xmlVersion = 1.0,
    this.languageCode = "en-US",
    this.lexicons = const [],
  }) {
    if (!path.existsSync()) {
      throw FileSystemException('File $path does not exist', path.path);
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

  String createXMLFile() {
    final builder = XmlBuilder();
    builder.processing("xml", 'version="$xmlVersion');
    builder.element("lexicon", attributes: {"xml:lang": languageCode},
        nest: () {
      for (Lexicon lexeme in lexicons) {
        builder.element("lexeme", nest: () {
          builder.element("grapheme", nest: lexeme.grapheme);
          builder.element("alias", nest: lexeme.alias);
        });
      }
    });
    final document = builder.buildDocument();
    if (!path.existsSync()) {
      Warning.warn("File $path already exists, overwriting.");
    }
    return document.toXmlString();
  }

  @override
  bool operator ==(Object obj) {
    if (obj is Lexica) {
      if (obj.languageCode == languageCode &&
          obj.xmlVersion == xmlVersion &&
          obj.lexicons.length == lexicons.length &&
          obj.lexicons == lexicons) {
        return true;
      }
    }
    return false;
  }

  @override
  int get hashCode =>
      Object.hash(xmlVersion, languageCode, Object.hashAll(lexicons), path);
}
