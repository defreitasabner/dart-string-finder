import 'dart:convert';
import 'dart:io';

import 'package:script/script.dart';

Future<void> main() async {
  String sk8erPath = '../sk8ers/lib';
  String testPath = './example/files';
  List<FileSystemEntity> dartFiles = await searchForDartFiles(dirPath: sk8erPath);
  await openFile(filePath: dartFiles[5].path);
}

Future<List<FileSystemEntity>> searchForDartFiles({required String dirPath}) async{
  if(await Directory(dirPath).exists()) {
    List<FileSystemEntity> dirList = await Directory(dirPath).list(recursive: true).toList();
    List<FileSystemEntity> dartFiles = [];
    for(FileSystemEntity entity in dirList) {
      if(entity.path.contains('.dart')) {
        dartFiles.add(entity);
      }
    }
    return dartFiles;
  } else {
    throw Exception('Source Dir do not exists');
  }
}

Future<void> openFile({required String filePath}) async {
  final File file = File(filePath);
  print(filePath);
  if(await file.exists()) {
    Stream<String> lines = file.openRead()
      .transform(utf8.decoder)
      .transform(LineSplitter());
      int lineCount = 1;
      await for(String line in lines) {
        List<String> stringsInLine = searchForInnerStrings(text: line);
        if(stringsInLine.isNotEmpty){
          print('$lineCount : $stringsInLine');
        }
        lineCount++;
      }
  } else {
    throw Exception('File do not exists');
  }
}

List<String> searchForInnerStrings({required String text}) {
  RegExp pattern = RegExp("(\"|').*(\"|')");
  Iterable<RegExpMatch> matches = pattern.allMatches(text);
  List<String> stringsFound = [];
  for (final match in matches) {
    if(match[0] != null) {
      stringsFound.add(match[0]!);
    }
  }
  return stringsFound;
}
