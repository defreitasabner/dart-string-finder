A simple package with a CLI to extract all strings marked with method `i18n()`, which is used from [localization package](https://pub.dev/packages/localization). Our package do not translate your strings, it just automatize the process of generate and update JSON files used from this package.

## Getting started
First of all, add `string_finder` to your flutter project:
After that, you could use default settings simple running command:
```bash
dart run string_finder extract -l <locales_separated_by_comma>
```
By default, it will search all strings, inner `.dart` files from your project `lib` folder, marked with this pattern: `"<any_text>".i18n()"`. All strings found will be written on one or more JSON files, within `i18n/` in your `lib/`. If folder `i18n/` do not exists, it will be created. The strings found will be written in JSON file following this pattern:
```json
{
    "<string_found>": "<string_found>"
}
```
It will create a new JSON file for each locale that you define with flag `-l`, for example:
```bash
dart run string_finder extract -l pt,en,es
```
This command will create: `pt_br.json`, `en.json`, and `es.json`. If none locale were provided, it will create a single JSON file named `strings.json` with all strings found. If you add new strings to your project, just run:
```bash
dart run string_finder extract
```
And it will update your previous locale JSON files without overwrite the values of previous translations. Now you just need to translate the values of JSON file.

## Usage

Let's supose that your project has just one string and you are using package localization to translate it. You need to setting up your project correctly and mark your string with method `i18n()`:
```dart
...
Text(
    "Hello World".i18n(),
)
...
```
Now, you could run `string_finder` extract:
```bash
dart run string_finder extract -l en,pt_br
```
Open `pt_BR.json` generated:
```json
{
    "Hello World" : "Hello World"
}
```
and change the value of string to portuguese:
```json
{
    "Hello World" : "Olá Mundo"
}
```
Restart your app to test.

## Additional information
- If you want to use more option use command `help`
- If you want to ignore directories inner your search directory (default is `lib/`), use flag `-i` and list all directories separated by comma
- If you want to search in a different directory, you could define search directory and output directory during command `extract` just using: `dart run string_finder extract <search_directory> <output_directory>`
