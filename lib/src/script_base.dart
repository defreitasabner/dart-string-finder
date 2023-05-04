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

// class FileManager {
//   Future<FoundString> openFile({required String filePath}) async {
//   final File file = File(filePath);
//   if(await file.exists()) {
//     FoundString stringFinder = FoundString(filePath: filePath);
//     Stream<String> lines = file.openRead()
//       .transform(utf8.decoder)
//       .transform(LineSplitter());
//       int lineCount = 1;
//     await for(String line in lines) {
//       List<String> stringsInLine = searchForInnerStrings(
//         text: line, 
//         removeImports: true,
//         removeMapKeys: true,
//         removePart: true,
//       );
//       if(stringsInLine.isNotEmpty){
//         for(String string in stringsInLine) {
//           stringFinder.stringsPerLine[string] = [];
//           stringFinder.stringsPerLine[string]!.add(lineCount);
//         }
//       }
//       lineCount++;
//     }
//     return stringFinder;
//     } else {
//       throw Exception('File do not exists');
//     }
//   }
// }

class StringFinder {

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
}

class FoundString {
  final String filePath;
  final Map<String, List<int>> stringsPerLine = {};

  FoundString({
    required this.filePath,
  });
}