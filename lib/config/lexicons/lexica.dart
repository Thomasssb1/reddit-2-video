import 'package:deep_pick/deep_pick.dart';
import 'package:reddit_2_video/app_paths.dart';
import 'package:reddit_2_video/config/config_item.dart';
import 'package:reddit_2_video/config/lexicons/lexicon.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/utils/logger.dart';
import 'package:xml/xml.dart';
import 'dart:io';
import 'dart:convert';
import 'package:reddit_2_video/utils/subprocess/subprocess.dart';
export 'package:reddit_2_video/config/lexicons/lexicon.dart';

class Lexica extends ConfigItem {
  double xmlVersion;
  String languageCode;
  String id;
  List<Lexicon> lexicons;

  Lexica({
    required this.xmlVersion,
    required this.languageCode,
    required this.id,
    required this.lexicons,
    required super.path,
  });

  Lexica.fromXML({
    required File file,
    required this.id,
    this.xmlVersion = 1.0,
    this.languageCode = "en-US",
    this.lexicons = const [],
  }) : super.fromFile(file) {
    XmlDocument document = XmlDocument.parse(path.readAsStringSync());

    String xmlVersion =
        document.firstElementChild?.getAttribute("version") ?? "1.0";
    String languageCode =
        document.getElement("lexicon")?.getAttribute("xml:lang") ?? "en-US";

    List<Lexicon> lexicons = <Lexicon>[];

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

  static List<Lexica> fromConfig({required String configPath}) {
    List<Lexica> lexicas = <Lexica>[];
    final configFile = AppPaths.resolve(configPath);
    for (var (id, file) in _getMetadata(configFile.path)) {
      lexicas.add(Lexica.fromXML(file: file, id: id));
    }

    if (lexicas.length > 5) {
      lexicas = lexicas.sublist(0, 5);

      StringBuffer sb = StringBuffer();
      sb.write(
          "There is a maximum of 5 lexicons you can add in a single request to AWS Polly, using the first 5 lexicons: ");
      for (Lexica lex in lexicas) {
        sb.write("${lex.id},");
      }
      logger.warning(sb.toString());
    }

    return lexicas;
  }

  static Future<void> update(String configPath, List<Lexica> lexicas,
      {bool verbose = false}) async {
    final configFile =
        AppPaths.resolve('defaults/lexicons/lexemes.config.json');
    await _update(configFile.path, lexicas, verbose: verbose);
  }

  static Future<DateTime> _getLastUpdatedFile(File config) async {
    DateTime mostRecent = DateTime(1970, 1, 1);
    await config.parent.list().forEach((f) {
      if (FileSystemEntity.typeSync(f.path) == FileSystemEntityType.file &&
          f != config) {
        DateTime lastUpdated = File(f.path).lastModifiedSync();
        mostRecent =
            mostRecent.compareTo(lastUpdated) < 0 ? lastUpdated : mostRecent;
      }
    });
    return mostRecent;
  }

  static Future<void> _update(String path, List<Lexica> lexicas,
      {bool verbose = false}) async {
    File config = File(path);
    Future<DateTime> lastModified = _getLastUpdatedFile(config);
    Future<DateTime> lastUpdate = _getLastUpdated(path);
    var result = await Future.wait([lastModified, lastUpdate]);
    if (result[0].compareTo(result[1]) > 0) {
      try {
        for (Lexica lex in lexicas) {
          await lex.upload(verbose: verbose);
        }
        _setLastUpdated(DateTime.now(), path);
      } on PollyInvalidPlsLexicon catch (e) {
        logger.warning(e.message);
        return;
      }
    }
  }

  static void _setLastUpdated(DateTime newTime, String path) {
    File config = File(path);
    var json = jsonDecode(config.readAsStringSync());
    json['_last_updated'] = newTime.toString();
    const encoder = JsonEncoder.withIndent('  ');
    config.writeAsStringSync(encoder.convert(json));
  }

  static Future<DateTime> _getLastUpdated(String path) async {
    File config = File(path);
    try {
      var json = jsonDecode(config.readAsStringSync());
      String? updated = pick(json, "_last_updated").asStringOrNull();
      try {
        return (updated == null)
            ? DateTime(1970, 1, 1)
            : DateTime.parse(updated);
      } on FormatException {
        json['_last_updated'] = null;
        IOSink sink = config.openWrite();
        sink.write(jsonEncode(json));
        await sink.close();
        return DateTime(1970, 1, 1);
      }
    } on FormatException {
      throw InvalidFileFormatException("Invalid json file format", config);
    } on PickException {
      throw InvalidFileFormatException("Missing field _last_updated", config);
    }
  }

  static void setLastUpdatedForTest(DateTime newTime, String path) {
    _setLastUpdated(newTime, path);
  }

  static Future<DateTime> getLastUpdatedForTest(String path) {
    return _getLastUpdated(path);
  }

  static List<(String, File)> _getMetadata(String path) {
    File config = File(path);
    try {
      var json = jsonDecode(config.readAsStringSync());
      List<(String, File)> lexemeConfigs =
          pick(json, "lexemes").asListOrThrow<(String, File)>((p0) {
        String id = p0("id").asStringOrThrow();
        String path = p0("file").asStringOrThrow();

        File lexemeFile = File("${config.parent.path}/$path");

        if (!lexemeFile.existsSync()) {
          throw InvalidFileFormatException(
              "File does not exist for $path", config);
        }

        return (id, lexemeFile);
      });
      return lexemeConfigs;
    } on FormatException {
      throw InvalidFileFormatException(
          "Lexeme config file is not in valid json format", config);
    } on PickException {
      throw InvalidFileFormatException(
          "Lexeme config file is not in valid json format", config);
    }
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
    if (path.existsSync()) {
      logger.warning("File $path already exists, overwriting.");
    }
    final xml = document.toXmlString();
    path.writeAsStringSync(xml);
    return xml;
  }

  Future<void> upload({bool verbose = false}) async {
    final result = await Subprocess.exec(
      "aws",
      [
        "polly",
        "put-lexicon",
        "--name",
        id,
        "--content",
        "file://${path.path}"
      ],
      verbose: verbose,
    );

    if (result.exitCode != 0) {
      throw PollyInvalidPlsLexicon(
          "Unable to put lexicon ${path.path}. Lexemes will not be updated.",
          path);
    }
  }

  @override
  String toString() => id;

  @override
  bool operator ==(Object other) {
    if (other is Lexica) {
      bool sameLexicons = other.lexicons.length == lexicons.length;
      if (sameLexicons) {
        for (int i = 0; i < lexicons.length; i++) {
          if (other.lexicons[i] != lexicons[i]) {
            sameLexicons = false;
            break;
          }
        }
      }
      if (other.languageCode == languageCode &&
          other.xmlVersion == xmlVersion &&
          sameLexicons) {
        return true;
      }
    }
    return false;
  }

  @override
  int get hashCode =>
      Object.hash(xmlVersion, languageCode, Object.hashAll(lexicons), path);
}
