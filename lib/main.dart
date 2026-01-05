import 'dart:convert';
import 'dart:io' as io;

import 'package:http/http.dart' as http;

import 'ansi.dart';
import 'gitmoji.dart';

class Main {
  final int lineCount;
  final String marker;
  final String emptyMarker;
  final io.Stdout out = io.stdout;
  final io.Stdin stdin = io.stdin;
  final bool oldLineMode = io.stdin.lineMode;
  final bool oldEchoMode = io.stdin.echoMode;
  final String questionSign;
  final String okSign;
  final String gitmojiQuestion;
  final String titleQuestion;

  var _index = 0;
  final search = StringBuffer();

  late List<GitMoji> gitMojiList;
  late GitMoji selectedGitMoji;

  Main({
    this.lineCount = 5,
    this.marker = '${Ansi.bold}${Ansi.green}»${Ansi.reset}',
    this.gitmojiQuestion = 'Choose a gitmoji:',
    this.titleQuestion = 'Inform commit title:',
    this.questionSign = '${Ansi.bold}${Ansi.customYellow}?${Ansi.reset}',
    this.okSign = '${Ansi.bold}${Ansi.green}*${Ansi.reset}',
  }) : emptyMarker = ''.padRight(Ansi.strip(marker).length);

  Future<void> run() async {
    stdin.lineMode = false;
    stdin.echoMode = false;

    gitMojiList = await _fetchGitMojis();

    while (true) {
      out.write('$questionSign $gitmojiQuestion $search');
      out.writeln(Ansi.cursorSavePosition);

      final term = search.toString().toLowerCase();

      var emojis = term.isEmpty
          ? List.of(gitMojiList)
          : gitMojiList.where((gitmoji) => gitmoji.key.contains(term)).toList();

      if (emojis.isEmpty) emojis = List.of(gitMojiList);

      _movementWindow(_index, lineCount, emojis.length).forEach(
        (i) =>
            out.writeln('${i == _index ? marker : emptyMarker} ${emojis[i]}'),
      );

      out.write(Ansi.cursorRestorePosition);

      final byte = stdin.readByteSync();

      out.write(Ansi.carriageReturn + Ansi.clearDisplayDown);

      /// Enter
      if (byte == 10) {
        selectedGitMoji = emojis[_index];
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
            if (_index > 0) _index--;
            break;

          /// Arrow Down
          case 66:
            if (_index < emojis.length - 1) _index++;
            break;

          /// End
          case 70:
            _index = emojis.length - 1;
            break;

          /// Home
          case 72:
            _index = 0;
            break;

          /// Default
          default:
            io.stderr.writeln('Control Char: $newByte');
        }

        continue;
      }

      _index = 0;

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

    out.write('$questionSign $titleQuestion ');

    final title = stdin.readLineSync();

    final parameters = [
      'commit',
      '-a',
      '-m',
      '${selectedGitMoji.emoji} $title',
    ];

    final process = io.Process.runSync('git', parameters);

    final exitCode = process.exitCode;

    if (exitCode != 0) {
      io.stderr.writeln(parameters.join(' '));
      io.stderr.write(process.stderr);
    }

    io.exit(exitCode);
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
}
