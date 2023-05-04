import 'dart:convert';
import 'dart:io';

import 'package:script/src/script_base.dart';

Future<void> main() async {
  String sk8erPath = '../sk8ers/lib';
  String outputPath = './example/files/reference.txt';
  DartFileFinder dartFileFinder = DartFileFinder(
    dirPath: sk8erPath, 
    ignoreDirs: ['mockup/', 'constants/',],
  );
  List<FileSystemEntity> dartFiles = await dartFileFinder.searchForDartFiles();
  
  List<FoundString> filesWithStringsToTranslate = [];
  for(final FileSystemEntity file in dartFiles) {
    FoundString stringFinder = await openFile(filePath: file.path);
    if(stringFinder.stringsPerLine.isNotEmpty) {
      filesWithStringsToTranslate.add(stringFinder);
    }
  }
  Map<String, List<String>> finalData = aggregateStringsFound(list: filesWithStringsToTranslate);
  writeReferenceFile(outputFilePath: outputPath, data: finalData);
}

Future<List<FileSystemEntity>> searchForDartFiles({required String dirPath}) async{
  if(await Directory(dirPath).exists()) {
    List<FileSystemEntity> dirList = await Directory(dirPath).list(recursive: true).toList();
    List<FileSystemEntity> dartFiles = [];
    for(FileSystemEntity entity in dirList) {
      if(entity.path.contains('.dart') && !entity.path.contains('.g.dart')) {
        dartFiles.add(entity);
        print(entity.path);
      }
    }
    return dartFiles;
  } else {
    throw Exception('Source Dir do not exists');
  }
}

Future<FoundString> openFile({required String filePath}) async {
  final File file = File(filePath);
  if(await file.exists()) {
    FoundString stringFinder = FoundString(filePath: filePath);
    Stream<String> lines = file.openRead()
      .transform(utf8.decoder)
      .transform(LineSplitter());
      int lineCount = 1;
    await for(String line in lines) {
      List<String> stringsInLine = searchForInnerStrings(
        text: line, 
        removeImports: true,
        removeMapKeys: true,
        removePart: true,
      );
      if(stringsInLine.isNotEmpty){
        for(String string in stringsInLine) {
          stringFinder.stringsPerLine[string] = [];
          stringFinder.stringsPerLine[string]!.add(lineCount);
        }
      }
      lineCount++;
    }
    return stringFinder;
  } else {
    throw Exception('File do not exists');
  }
}

List<String> searchForInnerStrings({required String text, bool removeImports = false, removeMapKeys = false, removePart = false}) {
  if(removeImports && containsImport(text: text)) return [];
  if(removePart && containsPart(text: text)) return [];
  if(removeMapKeys && containsMapKeys(text: text)) return [];
  RegExp pattern = RegExp("(\"|').*(\"|')");
  Iterable<RegExpMatch> matches = pattern.allMatches(text);
  List<String> stringsFound = [];
  for (Match match in matches) {
    if(match[0] != null) {
      stringsFound.add(match[0]!);  
    }
  }
  return stringsFound;
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

Map<String,List<String>> aggregateStringsFound({required List<FoundString> list}) {
  Map<String,List<String>> allStrings = {};
  for(FoundString stringFinder in list) {
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

void writeReferenceFile({required String outputFilePath, required Map<String, List<String>> data}) {
  final File file = File(outputFilePath);
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
