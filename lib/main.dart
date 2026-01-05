import 'dart:io' as io;

import 'ansi.dart';
import 'gitmoji.dart';

class Main {
  final int lineCount;
  final String marker;
  final String emptyMarker;
  final io.Stdout stdout = io.stdout;
  final io.Stdin stdin = io.stdin;
  final bool oldLineMode = io.stdin.lineMode;
  final bool oldEchoMode = io.stdin.echoMode;
  final String questionSign;
  final String okSign;
  final String gitmojiQuestion;
  final String titleQuestion;

  var _index = 0;
  final search = StringBuffer();

  late Gitmoji selected;

  Main({
    this.lineCount = 5,
    this.marker = '${Ansi.bold}${Ansi.green}»${Ansi.reset}',
    this.gitmojiQuestion = 'Choose a Gitmoji:',
    this.titleQuestion = 'Inform commit title:',
    this.questionSign = '${Ansi.bold}${Ansi.customYellow}?${Ansi.reset}',
    this.okSign = '${Ansi.bold}${Ansi.green}*${Ansi.reset}',
  }) : emptyMarker = ''.padRight(Ansi.strip(marker).length);

  void run(final List<Gitmoji> gitmojiList) {
    stdin.lineMode = false;
    stdin.echoMode = false;

    /// Emoji selection.
    while (true) {
      final String term = search.toString().toLowerCase();

      final List<Gitmoji> filtered = term.isEmpty
          ? List.of(gitmojiList)
          : gitmojiList.where((gitmoji) => gitmoji.key.contains(term)).toList();

      final List<Gitmoji> emojis = filtered.isEmpty
          ? List.of(gitmojiList)
          : filtered;

      final byte = _render(emojis);

      /// Enter
      if (byte == 10) {
        selected = emojis[_index];
        stdout.writeln('$okSign $gitmojiQuestion $selected');
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

    /// Title
    stdout.write('$questionSign $titleQuestion ');

    final title = stdin.readLineSync();

    /// Run git commit command.
    final parameters = ['commit', '-a', '-m', '${selected.emoji} $title'];

    final process = io.Process.runSync('git', parameters);

    final exitCode = process.exitCode;

    if (exitCode != 0) {
      io.stderr.writeln(parameters.join(' '));
      io.stderr.write(process.stderr);
    }

    io.exit(exitCode);
  }

  int _render(List<Gitmoji> emojis) {
    stdout.write('$questionSign $gitmojiQuestion $search');
    stdout.writeln(Ansi.cursorSavePosition);

    _movementWindow(_index, lineCount, emojis.length).forEach(
      (i) =>
          stdout.writeln('${i == _index ? marker : emptyMarker} ${emojis[i]}'),
    );

    stdout.write(Ansi.cursorRestorePosition);

    final byte = stdin.readByteSync();

    stdout.write(Ansi.carriageReturn + Ansi.clearDisplayDown);

    return byte;
  }

  List<int> _movementWindow(int selected, int lineCount, int max) {
    if (lineCount >= max) return List.generate(max, (i) => i);

    if (max - selected < lineCount) {
      return List.generate(lineCount, (i) => max - lineCount + i);
    }

    return List.generate(lineCount, (i) => selected + i);
  }
}
