import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:script/src/script_base.dart';

const String extractCommand = 'extract';
const String helpCommand = 'help';
const String createReferenceFile = 'reference-file';
const String ignoredDirsOptions = 'ignore-dirs';
const String localeOptions = 'locale';
const String verboseMode = 'verbose';

void main(List<String> arguments) {
  exitCode = 0;

  final extractCommandArgParser = ArgParser()
    ..addMultiOption(
      ignoredDirsOptions,
      abbr: 'i',
      valueHelp: 'dirnames',
      help: 'List all directories, separated by comma(,), to ignore inner Search Directory',
    )
    ..addMultiOption(
      localeOptions, 
      abbr: 'l',
      valueHelp: 'language_code',
      help: 'List all locale json file that you want to create.',
    )
    ..addFlag(
      createReferenceFile, 
      abbr: 'r',
      negatable: false, 
      help: 'Create a reference file (.txt) list all strings found by files and lines.'
    )
    ..addFlag(
      verboseMode, 
      abbr: 'v',
      negatable: false,
      help: 'Show additional diagnostic info.' 
    );

  final parser = ArgParser()
    ..addCommand(extractCommand, extractCommandArgParser)
    ..addCommand(helpCommand);

  ArgResults argResults = parser.parse(arguments);

  switch (argResults.command?.name) {
    case extractCommand:
      extractStringsToJson(
        searchDir: argResults.command!.rest[0],
        outputDir: argResults.command!.rest.length > 1 ? argResults.command!.rest[1] : './example/files',
        ignoredDirs: argResults.command![ignoredDirsOptions],
        locales: argResults.command![localeOptions],
        referenceFile: argResults.command![createReferenceFile] as bool,
        verboseMode: argResults.command![verboseMode] as bool,
      );  
      break;
    case helpCommand:
      for(final command in parser.commands.keys) {
        if(command != helpCommand) {
          print('[$command]');
          print(parser.commands[command]?.usage);
        }

      }
      break;
    default:
      exitCode = 2;
      stderr.writeln('Invalid command: ${argResults.command}');
      exit(2);
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

  final outputDirectory = Directory(outputDir);
  List<String> jsonFilesInOutputDir = [];

  stdout.writeln('Search directory: $searchDir');
  stdout.writeln('Ignored directories: $ignoredDirs');
  stdout.writeln('Output directory: $outputDir');
  if(await outputDirectory.exists()) {
    List<FileSystemEntity> files = outputDirectory.listSync(recursive: true);
    stdout.writeln('These json files were found in output directory:');
    for(final file in files) {
      if(file.path.contains('.json')) {
        jsonFilesInOutputDir.add(file.path);
        String filename = path.split(file.path).last;
        stdout.writeln(
          locales.contains(filename.replaceAll('.json', '')) 
            ? '- $filename'
            : '- $filename (CAUTION: it will be overwritten)');
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
    if(referenceFile) {
      Map<String, List<String>> referenceData = stringFinder.generateReferenceFileData();
      fileManager.writeReferenceFile(filepath: '$outputDir/reference.txt', data: referenceData);
    }
    Map<String, dynamic> jsonData = stringFinder.generateJsonFileData();
    stdout.writeln('${jsonData.keys.length} strings were found!');
    if(locales.isNotEmpty) {
      if(jsonFilesInOutputDir.isNotEmpty) {
        for(String filepath in jsonFilesInOutputDir) {
            if(locales.contains(path.split(filepath).last.replaceAll('.json', ''))) {
              fileManager.updateJsonFile(filepath: filepath, newData: jsonData);
              stdout.writeln('- ${path.split(filepath).last} was updated');
            } else {
              fileManager.writeJsonFile(outputFilePath: filepath, data: jsonData);
              stdout.writeln('- ${path.split(filepath).last} was created or overwrite');
            }
        }
      } else {
        stdout.writeln('Creating locale files in $outputDir:');
        for(String locale in locales) {
          fileManager.writeJsonFile(outputFilePath: '$outputDir/$locale.json', data: jsonData);
          stdout.writeln('- $locale.json');
        }
      }
    } else {
      if(jsonFilesInOutputDir.isNotEmpty) {
        stdout.writeln('Updated locale files in $outputDir:');
        for(String filepath in jsonFilesInOutputDir) {
          fileManager.updateJsonFile(filepath: filepath, newData: jsonData);
          stdout.writeln('- ${path.split(filepath).last}');
        }
      } else {
        fileManager.writeJsonFile(outputFilePath: '$outputDir/strings.json', data: jsonData);
        stdout.writeln('Created locale file strings.json in $outputDir');
      }
    }
  } else {
    exit(0);
  }
}