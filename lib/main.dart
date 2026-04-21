import 'dart:io' as io;

import 'package:gitmoji/nullable_string_extension.dart';

import 'ansi.dart';
import 'gitmoji.dart';

class Main {
  final bool debug;
  final int lineCount;
  final String marker;
  final String emptyMarker;
  final io.Stdout stdout = io.stdout;
  final io.Stdin stdin = io.stdin;
  final bool oldLineMode = io.stdin.lineMode;
  final bool oldEchoMode = io.stdin.echoMode;
  final String questionSign;
  final String okSign;
  final String cancelSign;
  final String gitmojiQuestion;
  final String titleQuestion;
  final String bodyQuestion;
  final bool commitWithAdd;
  final bool commitWithEmoji;

  Main(
    this.debug, {
    this.lineCount = 5,
    this.marker = '${Ansi.bold}${Ansi.green}»${Ansi.reset}',
    this.gitmojiQuestion = 'Choose a Gitmoji:',
    this.titleQuestion = 'Inform commit title:',
    this.bodyQuestion = 'Inform commit body (optional):',
    this.questionSign = '${Ansi.bold}${Ansi.customYellow}?${Ansi.reset}',
    this.okSign = '${Ansi.bold}${Ansi.green}*${Ansi.reset}',
    this.cancelSign = '${Ansi.bold}${Ansi.red}X${Ansi.reset}',
    this.commitWithAdd = true,
    this.commitWithEmoji = true,
  }) : emptyMarker = ''.padRight(Ansi.strip(marker).length);

  void run(final List<Gitmoji> gitmojiList) {
    late Gitmoji selected;
    final search = StringBuffer();
    int index = 0;

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

      final byte = _render(search, index, emojis);

      /// Enter
      if (byte == 10) {
        selected = emojis[index];
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
            if (index > 0) index--;
            break;

          /// Arrow Down
          case 66:
            if (index < emojis.length - 1) index++;
            break;

          /// End
          case 70:
            index = emojis.length - 1;
            break;

          /// Home
          case 72:
            index = 0;
            break;

          /// Default
          default:
            io.stderr.writeln('Control Char: $newByte');
        }

        continue;
      }

      index = 0;

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

    /// Title
    final max = 50 - (commitWithEmoji ? 3 : selected.code.length + 1);

    final title = StringBuffer();

    while (true) {
      stdout.write(
        '$questionSign [${title.length}/$max] $titleQuestion $title',
      );

      final byte = stdin.readByteSync();

      stdout.write(Ansi.carriageReturn + Ansi.clearDisplayDown);

      /// Enter
      if (byte == 10) break;

      // TODO: Implement left, right, home, end and delete.

      /// Backspace
      if (byte == 127) {
        final s = title.toString();

        if (s.isNotEmpty) {
          title.clear();
          title.write(s.substring(0, s.length - 1));
        }

        continue;
      }

      title.writeCharCode(byte);
    }

    if (title.isEmpty) {
      stdout.writeln(
        '${Ansi.cursorUp()}${Ansi.carriageReturn}${Ansi.clearEntireLine}'
        '$cancelSign $titleQuestion ',
      );

      io.stderr.writeln('[ERROR] Empty title!');
      io.exit(10);
    }

    stdout.writeln('$okSign [${title.length}/$max] $titleQuestion $title');

    stdin.lineMode = oldLineMode;
    stdin.echoMode = oldEchoMode;

    /// Body
    stdout.write('$questionSign $bodyQuestion ');

    final String? body = stdin.readLineSync()?.trim();

    if (body.isNullOrEmpty) {
      stdout.writeln(
        '${Ansi.cursorUp()}${Ansi.carriageReturn}${Ansi.clearEntireLine}'
        '$cancelSign $bodyQuestion ',
      );
    }

    /// Run git commit command.
    final exitCode = _commit(selected, title.toString(), body);

    io.exit(exitCode);
  }

  int _render(
    final StringBuffer search,
    final int index,
    final List<Gitmoji> emojis,
  ) {
    stdout.writeln();

    final List<int> lines = _window(index, lineCount, emojis.length);

    for (int i in lines) {
      stdout.writeln('${i == index ? marker : emptyMarker} ${emojis[i]}');
    }

    stdout.write(Ansi.carriageReturn + Ansi.cursorUp(lines.length + 1));

    stdout.write('$questionSign $gitmojiQuestion $search');

    final byte = stdin.readByteSync();

    stdout.write(Ansi.carriageReturn + Ansi.clearDisplayDown);

    return byte;
  }

  List<int> _window(final int selected, final int lineCount, final int max) {
    if (lineCount >= max) return List.generate(max, (i) => i);

    if (max - selected < lineCount) {
      return List.generate(lineCount, (i) => max - lineCount + i);
    }

    return List.generate(lineCount, (i) => selected + i);
  }

  int _commit(final Gitmoji gitmoji, final String title, final String? body) {
    final parameters = [
      'commit',
      if (commitWithAdd) '-a',
      '-m',
      '${commitWithEmoji ? gitmoji.emoji : gitmoji.code} $title',
    ];

    if (body?.isNotEmpty ?? false) parameters.addAll(['-m', '$body']);

    final process = io.Process.runSync('git', parameters);

    final exitCode = process.exitCode;

    if (exitCode != 0) {
      io.stderr.writeln(parameters.join(' '));
      io.stderr.write(process.stderr);
    }

    return exitCode;
  }
}
