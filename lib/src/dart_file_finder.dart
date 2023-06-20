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