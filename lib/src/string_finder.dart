class FoundString {
  final String filePath;
  final Map<String, List<int>> stringsPerLine = {};

  FoundString({
    required this.filePath,
  });
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
                                              r"|'){1}([.][i][1][8][n]){1}") : RegExp("[\",']\w*[\",']");
    Iterable<RegExpMatch> matches = pattern.allMatches(text);
    List<String> stringsFound = [];
    for (Match match in matches) {
      if(match[0] != null) {
        String treatedMatch = match[0]!.replaceAll('"', '').replaceAll("'", '');
        if(onlyi18nPattern) {
          stringsFound.add(treatedMatch.replaceAll('.i18n', ''));
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
