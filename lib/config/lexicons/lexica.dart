import 'package:deep_pick/deep_pick.dart';
import 'package:reddit_2_video/command/parsed_command.dart';
import 'package:reddit_2_video/config/config_item.dart';
import 'package:reddit_2_video/config/lexicons/lexicon.dart';
import 'package:reddit_2_video/exceptions/exceptions.dart';
import 'package:reddit_2_video/exceptions/polly_invalid_pls_lexicon.dart';
import 'package:xml/xml.dart';
import 'dart:io';
import 'dart:convert';
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
    required super.prePath,
    required super.path,
  });

  Lexica.fromXML({
    required super.path,
    required super.prePath,
    required this.id,
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

  static List<Lexica> fromConfig(
      {required String configPath, required String prePath}) {
    List<Lexica> lexicas = <Lexica>[];
    for (var (id, file) in _getMetadata("$prePath$configPath")) {
      lexicas.add(Lexica.fromXML(
          path: file.path.replaceFirst(prePath, ''), prePath: prePath, id: id));
    }

    if (lexicas.length > 5) {
      lexicas = lexicas.sublist(0, 5);

      StringBuffer sb = StringBuffer();
      sb.write(
          "There is a maximum of 5 lexicons you can add in a single request to AWS Polly, using the first 5 lexicons: ");
      for (Lexica lex in lexicas) {
        sb.write("${lex.id},");
      }
      Warning.warn(sb.toString());
    }

    return lexicas;
  }

  static Future<void> update(
      String configPath, List<Lexica> lexicas, ParsedCommand command) async {
    await _update("${command.prePath}/defaults/lexicons/lexemes.config.json",
        lexicas, command);
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

  static Future<void> _update(
      String path, List<Lexica> lexicas, ParsedCommand command) async {
    File config = File(path);
    Future<DateTime> lastModified = _getLastUpdatedFile(config);
    Future<DateTime> lastUpdate = _getLastUpdated(path);
    var result = await Future.wait([lastModified, lastUpdate]);
    if (result[0].compareTo(result[1]) > 0) {
      try {
        for (Lexica lex in lexicas) {
          await lex.upload(command);
        }
        _setLastUpdated(DateTime.now(), path);
      } on PollyInvalidPlsLexicon catch (e) {
        Warning.warn(e.message);
        return;
      }
    }
  }

  static void _setLastUpdated(DateTime newTime, String path) {
    File config = File(path);
    var json = jsonDecode(config.readAsStringSync());
    json['_last_updated'] = newTime.toString();

    IOSink sink = config.openWrite();
    const encoder = JsonEncoder.withIndent('  ');
    sink.write(encoder.convert(json));
    sink.close();
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
    if (!path.existsSync()) {
      Warning.warn("File $path already exists, overwriting.");
    }
    return document.toXmlString();
  }

  Future<void> upload(ParsedCommand command) async {
    final process = await Process.start(
        "aws",
        [
          "polly",
          "put-lexicon",
          "--name",
          id,
          "--content",
          "file://${path.path}"
        ],
        workingDirectory: command.prePath);
    if (command.verbose) {
      process.stderr.transform(utf8.decoder).listen((data) {
        stdout.write(data);
      });
      process.stdin.write(process.stdin);
    }
    int code = await process.exitCode;
    if (code != 0) {
      throw PollyInvalidPlsLexicon(
          "Unable to put lexicon ${path.path}. Lexemes will not be updated.",
          path);
    }
  }

  @override
  String toString() => id;

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
