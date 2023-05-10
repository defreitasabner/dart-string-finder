import 'dart:io';

import 'package:script/src/script_base.dart';

String jsonOutputPath = './example/files/pt_BR.json';

Future<void> main() async {
  await extractStrings();
  FileManager fileManager = FileManager();
  dynamic json = await fileManager.readJsonFile(filepath: jsonOutputPath);
  print(json);
}

Future<void> extractStrings() async {
  String sk8erPath = '../sk8ers/lib';
  String referenceOutputPath = './example/files/reference.txt';
  DartFileFinder dartFileFinder = DartFileFinder(
    dirPath: sk8erPath, 
    ignoreDirs: ['mockup/', 'constants/', 'i18n/'],
  );
  List<FileSystemEntity> dartFiles = await dartFileFinder.searchForDartFiles();
  FileManager fileManager = FileManager();
  for(FileSystemEntity file in dartFiles) {
    await fileManager.readDartFilePerLines(filePath: file.path);
  }
  StringFinder stringFinder = StringFinder();
  for(InputedData data in fileManager.extractedData) {
    stringFinder.getAllInnerString(filePath: data.filePath, textLines: data.lines);
  }
  Map<String, List<String>> referenceData = stringFinder.generateReferenceFileData();
  Map<String, String> jsonData = stringFinder.generateJsonFileData();
  fileManager.writeReferenceFile(outputFilePath: referenceOutputPath, data: referenceData);
  fileManager.writeJsonFile(outputFilePath: jsonOutputPath, data: jsonData);
}