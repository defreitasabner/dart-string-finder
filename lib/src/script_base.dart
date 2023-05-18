import 'dart:async';
import 'dart:convert';
import 'dart:io';

class DartFileFinder {
  final String dirPath;
  final List<String>? ignoreDirs;

  DartFileFinder({
    required this.dirPath,
    this.ignoreDirs,
  });

  Future<List<FileSystemEntity>> searchForDartFiles({
    bool removeIgnoredDirs = true
  }) async {
    if(await Directory(dirPath).exists()) {
      List<FileSystemEntity> dirList = await Directory(dirPath).list(recursive: true).toList();
      List<FileSystemEntity> dartFiles = [];
      for(FileSystemEntity entity in dirList) {
        if(entity.path.contains('.dart') && !entity.path.contains('.g.dart')) {
          dartFiles.add(entity);
        }
      }
      if(removeIgnoredDirs && ignoreDirs != null && ignoreDirs!.isNotEmpty) {
        for(String ignoredDir in ignoreDirs!) {
          dartFiles = removeIgnoredDartFiles(list: dartFiles, ignoredDir: ignoredDir);
        }
      }
      return dartFiles;
    } else {
      throw Exception('Source Dir do not exists');
    }
  }

  List<FileSystemEntity> removeIgnoredDartFiles({
    required List<FileSystemEntity> list, 
    required String ignoredDir,
  }) {
    return list.where(
      (entity) => !entity.path.toString().contains(ignoredDir)
    ).toList();
  }

}

class InputedData {
  final String filePath;
  final List<String> lines;
  InputedData({
    required this.filePath,
    required this.lines,
  });
}

class FileManager {

  List<InputedData> extractedData = [];

  Future<void> readDartFilePerLines({required String filePath}) async {
    final File file = File(filePath);
    if(await file.exists()) {
      List<String> lines = await file.readAsLines();
      InputedData inputData = InputedData(filePath: filePath, lines: lines);
      extractedData.add(inputData);
    } else {
      throw Exception('File do not exists');
    }
  }

  void writeReferenceFile({required String filepath, required Map<String, List<String>> data}) {
    final File file = File(filepath);
    final IOSink sink = file.openWrite();
    for(String key in data.keys) {
      sink.write('$key:\n');
      for(String specificLines in data[key]!) {
        sink.write('$specificLines\n');
      }
      sink.write('\n\n');
    }
    sink.close();
  }

  Future<Map<String, dynamic>> readJsonFile({ required String filepath }) async {
    final File file = File(filepath);
    if(await file.exists()) {
      final String content = file.readAsStringSync();
      JsonDecoder jsonDecoder = JsonDecoder();
      try {
        Map<String, dynamic> json = jsonDecoder.convert(content);
        return json;
      } catch (_) {
      }
        return {};
    } else {
      throw Exception('File do not exists');
    }
  }

  void writeJsonFile({required String outputFilePath, required Map<String, dynamic> data}) {
    final File file = File(outputFilePath);
    final IOSink sink = file.openWrite();
    JsonEncoder jsonEncoder = JsonEncoder.withIndent('  ');
    String json = jsonEncoder.convert(data);
    sink.write(json.replaceAll(r'\\', r'\'));
    sink.close();
  }

  Future<void> updateJsonFile({ required String filepath, required Map<String, dynamic> newData }) async {
    final Map<String, dynamic> previousJson = await readJsonFile(filepath: filepath);
    for(String key in newData.keys) {
      if(previousJson[key] != null) {
        newData[key] = previousJson[key];
      }
    }
    writeJsonFile(outputFilePath: filepath, data: newData);
  }

  Future<void> writeOrUpdateJsonFile({
    required String outputFileName,
    required String outputDirPath,
    required Map<String, dynamic> newData,
  }) async{
    final outputDir = Directory(outputDirPath);
    if(await outputDir.exists()) {
      final listFiles = outputDir.listSync();
      for(FileSystemEntity file in listFiles) {
        if(file.path.contains(outputFileName)) {
          return updateJsonFile(filepath: file.path, newData: newData);
        }
      }
      return writeJsonFile(outputFilePath: outputFileName, data: newData);
    } else {
      throw Exception('Output Directory do not exists.');
    }
  }

}

class StringFinder {

  List<FoundString> stringsFoundPerFile = [];

  void getAllInnerString({required String filePath, required List<String> textLines,}) {
    FoundString foundStrings = FoundString(filePath: filePath);
    int lineCount = 1;
    for(final String line in textLines) {
      List<String> strings = searchForInnerStrings(text: line, onlyi18nPattern: true);
      if(strings.isNotEmpty) {
        for(String string in strings) {
          foundStrings.stringsPerLine[string] = [];
          foundStrings.stringsPerLine[string]!.add(lineCount);
        }
      }
      lineCount++;
    }
    stringsFoundPerFile.add(foundStrings);
  }

  List<String> searchForInnerStrings({required String text, bool onlyi18nPattern = false}) {
    // ("|'){1}[^'"]*("|'){1}([.][i][1][8][n][(][)]){1}
    RegExp pattern = onlyi18nPattern ? RegExp(r'("'
                                              r"|'){1}[^'"
                                              r'"]*'
                                              r'("'
                                              r"|'){1}([.][i][1][8][n][(][)]){1}") : RegExp("[\",']\w*[\",']");
    Iterable<RegExpMatch> matches = pattern.allMatches(text);
    List<String> stringsFound = [];
    for (Match match in matches) {
      if(match[0] != null) {
        String treatedMatch = match[0]!.replaceAll('"', '').replaceAll("'", '');
        if(onlyi18nPattern) {
          stringsFound.add(treatedMatch.replaceAll('.i18n()', ''));
        } else {
          stringsFound.add(treatedMatch); 
        }
      }
    }
    return stringsFound;
  }

  Map<String,List<String>> generateReferenceFileData() {
    Map<String,List<String>> allStrings = {};
    for(FoundString stringFinder in stringsFoundPerFile) {
      for (String key in stringFinder.stringsPerLine.keys) {
        List<int> lines = stringFinder.stringsPerLine[key]!;
        String fileLines = '${stringFinder.filePath}: ${lines.toString()}';
        if(!allStrings.keys.contains(key)) {
          allStrings[key] = [];
        }
        allStrings[key]!.add(fileLines);
      }
    }
    return allStrings;
  }

  Map<String, String> generateJsonFileData() {
    Map<String, String> allStrings = {};
    for (FoundString foundString in stringsFoundPerFile) {
      for(String string in foundString.stringsPerLine.keys) {
        allStrings[string] = string;
      }
    }
    return allStrings;
  }

  bool containsImport({required String text}) {
    RegExp pattern = RegExp(r"^import\s['].*[']");
    return pattern.hasMatch(text);
  }

  bool containsPart({required String text}) {
    RegExp pattern = RegExp(r"^part\s['].*[']");
    return pattern.hasMatch(text);
  }

  bool containsMapKeys({required String text}) {
    return text.contains('"]') || text.contains("']");
  }

  bool validateString({
    required String text,
    required bool removeImports,
    required bool removePart,
    required bool removeMapKeys,
    }) {
    if(removeImports && containsImport(text: text)) {return true;}
    else if(removePart && containsPart(text: text)) {return true;}
    else if(removeMapKeys && containsMapKeys(text: text)) {return true;}
    else {return false;}
  }
}

class FoundString {
  final String filePath;
  final Map<String, List<int>> stringsPerLine = {};

  FoundString({
    required this.filePath,
  });
}