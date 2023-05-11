import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:script/src/script_base.dart';

const String extractToJson = 'extract';
const String updateJson = 'update';
const String createReferenceFile = 'reference-file';
const String ignoredDirsOptions = 'ignore-dirs';
const String localeOptions = 'locale';
const String verboseMode = 'verbose';

void main(List<String> arguments) {
  exitCode = 0;
  final parser = ArgParser()
    ..addCommand(extractToJson)
    ..addCommand(updateJson)
    ..addMultiOption(ignoredDirsOptions, abbr: 'i')
    ..addMultiOption(localeOptions, abbr: 'l')
    ..addFlag(createReferenceFile, negatable: true, abbr: 'r')
    ..addFlag(verboseMode, negatable: false, abbr: 'v');

  ArgResults argResults = parser.parse(arguments);

  switch (argResults.command!.name) {
    case extractToJson:
      extractStringsToJson(
        searchDir: argResults.command!.rest[0],
        outputDir: argResults.command!.rest.length > 1 ? argResults.command!.rest[1] : './example/files',
        ignoredDirs: argResults[ignoredDirsOptions],
        locales: argResults[localeOptions],
        referenceFile: argResults[createReferenceFile] as bool,
        verboseMode: argResults[verboseMode] as bool,
      );
      break;
    case updateJson:
      break;
    default:
      exitCode = 1;
      break;
  }

}

Future<void> extractStringsToJson({ 
  required String searchDir,
  required String outputDir,
  List<String> ignoredDirs = const [],
  List<String> locales = const [],
  bool referenceFile = false,
  bool verboseMode = false,
}) async {

  stdout.writeln('Search directory: $searchDir');
  stdout.writeln('Ignored directories: $ignoredDirs');
  stdout.writeln('Output directory: $outputDir');
  final jsonDir = Directory(outputDir);
  if(await jsonDir.exists()) {
    List<FileSystemEntity> files = jsonDir.listSync(recursive: true);
    stdout.writeln('We found these json files in output directory:');
    for(final file in files) {
      if(file.path.contains('.json')) {
        String filename = file.path.split('/').last; 
        stdout.writeln(
          locales.contains(filename.replaceAll('.json', '')) 
            ? '- $filename (will be overwritten)'
            : '- $filename');
      }
    }
  } else {
    stdout.writeln('Output directory do not exist, so it will be created during the process');
  }
  stdout.writeln('Do you want to continue? [y/n]');
  String response = stdin.readLineSync() ?? 'n';
  if(response == 'y') {
    DartFileFinder dartFileFinder = DartFileFinder(
      dirPath: searchDir, 
      ignoreDirs: ignoredDirs,
    );
    List<FileSystemEntity> dartFiles = await dartFileFinder.searchForDartFiles();
    if(verboseMode) {
      stdout.writeln('Found ${dartFiles.length} dart files:');
      for(FileSystemEntity file in dartFiles) {
        stdout.writeln(file.path);
      }
    } else {
      stdout.writeln('Found ${dartFiles.length} dart files.');
    }
    FileManager fileManager = FileManager();
    for(FileSystemEntity file in dartFiles) {
      await fileManager.readDartFilePerLines(filePath: file.path);
    }
    StringFinder stringFinder = StringFinder();
    for(InputedData data in fileManager.extractedData) {
      stringFinder.getAllInnerString(filePath: data.filePath, textLines: data.lines);
    }
    Map<String, dynamic> jsonData = stringFinder.generateJsonFileData();
    if(referenceFile) {
      Map<String, List<String>> referenceData = stringFinder.generateReferenceFileData();
      fileManager.writeReferenceFile(filepath: '$outputDir/reference.txt', data: referenceData);
    }
    if(locales.isNotEmpty) {
      stdout.writeln('Creating locale files in $outputDir:');
      for(String locale in locales) {
        fileManager.writeJsonFile(outputFilePath: '$outputDir/$locale.json', data: jsonData);
        stdout.writeln('- $locale.json');
      }
    } else {
      fileManager.writeJsonFile(outputFilePath: '$outputDir/strings.json', data: jsonData);
      stdout.writeln('Created locale file strings.json in $outputDir');
    }
  } else {
    exit(0);
  }
}

Future<void> updateJsonStrings({
  required String dirPath,
  required String jsonDir,
  List<String> ignoredDirs = const [],
  bool referenceFile = false,
  bool verboseMode = false,  
}) async {
  DartFileFinder dartFileFinder = DartFileFinder(
    dirPath: dirPath, 
    ignoreDirs: ignoredDirs,
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
  Map<String, dynamic> jsonData = stringFinder.generateJsonFileData();
  fileManager.updateJsonFile(filepath: jsonDir, newData: jsonData);
}