import 'dart:convert';
import 'dart:io' as io;
import 'package:gitmoji/ansi.dart';
import 'package:gitmoji/gitmoji.dart';
import 'package:http/http.dart' as http;

void main(List<String> arguments) async {
  final out = io.stdout;
  final stdin = io.stdin;
  final lineCount = 5;
  final marker = '»';
  final emptyMarker = ''.padRight(marker.length);
  final oldLineMode = stdin.lineMode;
  final oldEchoMode = stdin.echoMode;
  final questionSign =
      '${Ansi.bold}${Ansi.color(r: 255, g: 215)}?${Ansi.reset}';
  final okSign = '${Ansi.bold}${Ansi.green}*${Ansi.reset}';
  final gitmojiQuestion = 'Choose a gitmoji:';

  var selected = 0;
  var search = StringBuffer();

  final List<GitMoji> allGitMojis = await _fetchGitMojis();

  late GitMoji selectedGitMoji;

  stdin.lineMode = false;
  stdin.echoMode = false;

  while (true) {
    out.write('$questionSign $gitmojiQuestion $search');
    out.writeln(Ansi.cursorSavePosition);

    final term = search.toString().toLowerCase();

    var emojis = term.isEmpty
        ? List.of(allGitMojis)
        : allGitMojis.where((gitmoji) => gitmoji.key.contains(term)).toList();

    if (emojis.isEmpty) emojis = List.of(allGitMojis);

    _movementWindow(selected, lineCount, emojis.length).forEach(
      (i) => out.writeln(
        '${i == selected ? Ansi.green + marker + Ansi.reset : emptyMarker} '
        '${emojis[i]}',
      ),
    );

    out.write(Ansi.cursorRestorePosition);

    final byte = stdin.readByteSync();

    out.write(Ansi.carriageReturn + Ansi.clearDisplayDown);

    /// Enter
    if (byte == 10) {
      selectedGitMoji = emojis[selected];
      out.writeln('$okSign $gitmojiQuestion $selectedGitMoji');
      break;
    }

    /// Control Char ESC
    if (byte == 27) {
      if (stdin.readByteSync() != 91) continue;

      final newByte = stdin.readByteSync();

      switch (newByte) {
        /// Page Up
        case 53:
          stdin.readByteSync();
          // TODO: Implement
          break;

        /// Page Down
        case 54:
          stdin.readByteSync();
          // TODO: Implement
          break;

        /// Arrow Up
        case 65:
          if (selected > 0) selected--;
          break;

        /// Arrow Down
        case 66:
          if (selected < emojis.length - 1) selected++;
          break;

        /// End
        case 70:
          selected = emojis.length - 1;
          break;

        /// Home
        case 72:
          selected = 0;
          break;

        /// Default
        default:
          io.stderr.writeln('Control Char: $newByte');
      }

      continue;
    }

    selected = 0;

    /// Backspace
    if (byte == 127) {
      final s = search.toString();

      if (s.isNotEmpty) {
        search.clear();
        search.write(s.substring(0, s.length - 1));
      }

      continue;
    }

    search.writeCharCode(byte);
  }

  stdin.lineMode = oldLineMode;
  stdin.echoMode = oldEchoMode;

  io.exit(0);
}

Future<List<GitMoji>> _fetchGitMojis() async {
  final cacheFile = io.File('${io.Directory.systemTemp.path}/gitmoji.cache');
  final cacheExpire = DateTime.now().subtract(Duration(days: 1));

  String jsonString = '';

  if (cacheFile.existsSync() &&
      cacheFile.lastModifiedSync().isAfter(cacheExpire)) {
    print('Cache hit!');
    jsonString = cacheFile.readAsStringSync();
  } else {
    print('Getting definition...');
    jsonString = await _fetchFromWeb();

    if (jsonString.isEmpty && cacheFile.existsSync()) {
      print('Using old cache.');
      jsonString = cacheFile.readAsStringSync();
    }
  }

  if (jsonString.trim().isEmpty) {
    throw Exception('GitMojis definition not found.');
  }

  final body = jsonDecode(jsonString);

  cacheFile.writeAsStringSync(jsonString);

  final List<dynamic> list = body['gitmojis'];

  return list.map((item) {
    final map = item as Map<String, dynamic>;
    return GitMoji(
      emoji: map['emoji'].toString(),
      entity: map['entity'].toString(),
      code: map['code'].toString(),
      description: map['description'].toString().trim(),
      name: map['name'].toString(),
      semver: map['semver']?.toString(),
    );
  }).toList();
}

Future<String> _fetchFromWeb() async {
  try {
    final response = await http.get(
      Uri.parse(
        'https://raw.githubusercontent.com/carloscuesta/gitmoji/refs/heads'
        '/master/packages/gitmojis/src/gitmojis.json',
      ),
    );

    if (response.statusCode < 200 || response.statusCode > 299) return '';

    return response.body;
  } on Exception {
    return '';
  }
}

List<int> _movementWindow(int selected, int lineCount, int max) {
  if (lineCount >= max) return List.generate(max, (i) => i);

  if (max - selected < lineCount) {
    return List.generate(lineCount, (i) => max - lineCount + i);
  }

  return List.generate(lineCount, (i) => selected + i);
}
