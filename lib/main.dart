import 'dart:io' as io;

import 'package:gitmoji/nullable_string_extension.dart';
import 'package:gitmoji/position.dart';

import 'ansi.dart';
import 'gitmoji.dart';

class Main {
  final bool debug;
  final int lineCount;
  final String marker;
  final String emptyMarker;
  final io.Stdout stdout = io.stdout;
  final io.Stdin stdin = io.stdin;
  final io.Stdout stderr = io.stderr;
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
  final String executable;

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
    this.executable = 'git',
  }) : emptyMarker = ''.padRight(Ansi.strip(marker).length);

  void run(final List<Gitmoji> gitmojiList) {
    if (_executeCommand(["--version"]) != 0) {
      stderr.writeln("$executable command nor found.");
      io.exit(10);
    }

    stdin.lineMode = false;
    stdin.echoMode = false;

    late Gitmoji selected;

    /// Emoji selection.
    final search = StringBuffer();
    int cursorIndex = 0;
    int index = 0;

    while (true) {
      final String text = search.toString();

      // Start Message Builder
      final List<Gitmoji> filtered = text.isEmpty
          ? List.of(gitmojiList)
          : gitmojiList
                .where((gitmoji) => gitmoji.key.contains(text.toLowerCase()))
                .toList();

      final List<Gitmoji> emojis = filtered.isEmpty
          ? List.of(gitmojiList)
          : filtered;

      stdout.writeln();

      final List<int> lines = _window(index, lineCount, emojis.length);

      for (int i in lines) {
        stdout.writeln('${i == index ? marker : emptyMarker} ${emojis[i]}');
      }

      stdout.write(Ansi.carriageReturn + Ansi.cursorUp(lines.length + 1));

      stdout.write('$questionSign $gitmojiQuestion $search');
      // End Message Builder

      if (cursorIndex < text.length) {
        stdout.write(Ansi.cursorBack(text.length - cursorIndex));
      }

      final byte = stdin.readByteSync();

      stdout.write(Ansi.carriageReturn + Ansi.clearDisplayDown);

      /// Enter
      if (byte == 10) {
        selected = emojis[index];
        break;
      }

      /// Control Char ESC
      if (byte == 27) {
        if (stdin.readByteSync() != 91) continue;

        final newByte = stdin.readByteSync();

        switch (newByte) {
          /// Insert
          case 50:
            if (stdin.readByteSync() == 126) {
              // Ignore
            }
            break;

          /// Delete
          case 51:
            if (stdin.readByteSync() == 126) {
              if (cursorIndex < text.length) {
                search.clear();
                search.write(
                  text.substring(0, cursorIndex) +
                      text.substring(cursorIndex + 1),
                );
              }
            }
            break;

          /// Page Up
          case 53:
            if (stdin.readByteSync() == 126) {
              // Ignore
            }
            break;

          /// Page Down
          case 54:
            if (stdin.readByteSync() == 126) {
              // Ignore
            }
            break;

          /// Arrow Up
          case 65:
            if (index > 0) index--;
            break;

          /// Arrow Down
          case 66:
            if (index < emojis.length - 1) index++;
            break;

          /// Right
          case 67:
            if (cursorIndex < text.length) cursorIndex++;
            break;

          /// Left
          case 68:
            if (cursorIndex > 0) cursorIndex--;
            break;

          /// End
          case 70:
            cursorIndex = text.length;
            break;

          /// Home
          case 72:
            cursorIndex = 0;
            break;

          /// Default
          default:
            stderr.writeln('Control Char: $newByte');
            break;
        }

        continue;
      }

      index = 0;

      /// Backspace
      if (byte == 127) {
        final s = search.toString();
        if (s.isNotEmpty) {
          search.clear();
          search.write(
            text.substring(0, cursorIndex - 1) + text.substring(cursorIndex),
          );
          cursorIndex--;
        }
        continue;
      }

      search.clear();
      search.write(
        text.substring(0, cursorIndex) +
            String.fromCharCode(byte) +
            text.substring(cursorIndex),
      );
      cursorIndex++;
    }

    stdout.writeln('$okSign $gitmojiQuestion $selected');

    /// Title
    final max = 50 - (commitWithEmoji ? 3 : selected.code.length + 1);

    String title = _prompt((buffer) {
      final message = StringBuffer("$questionSign [");

      if (buffer.length > max) message.write(Ansi.bold + Ansi.red);

      message.write(buffer.length.toString().padLeft(2, '0'));

      if (buffer.length > max) message.write(Ansi.reset);

      message.write("/$max] $titleQuestion $buffer");

      return message.toString();
    });

    if (title.isEmpty) {
      stdout.writeln(
        '${Ansi.cursorUp()}${Ansi.carriageReturn}${Ansi.clearEntireLine}'
        '$cancelSign $titleQuestion ',
      );

      stderr.writeln('[ERROR] Empty title!');
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
        '${Ansi.bold}*${Ansi.reset} $bodyQuestion ',
      );
    }

    /// Run git commit command.
    final exitCode = _commit(selected, title.toString(), body);

    io.exit(exitCode);
  }

  List<int> _window(final int selected, final int lineCount, final int max) {
    if (lineCount >= max) return List.generate(max, (i) => i);

    if (max - selected < lineCount) {
      return List.generate(lineCount, (i) => max - lineCount + i);
    }

    return List.generate(lineCount, (i) => selected + i);
  }

  int _commit(final Gitmoji gitmoji, final String title, final String? body) {
    final arguments = [
      'commit',
      if (commitWithAdd) '-a',
      '-m',
      '${commitWithEmoji ? gitmoji.emoji : gitmoji.code} $title',
    ];

    if (body?.isNotEmpty ?? false) arguments.addAll(['-m', '$body']);

    return _executeCommand(arguments);
  }

  int _executeCommand(final List<String> arguments) {
    final process = io.Process.runSync(executable, arguments);

    final exitCode = process.exitCode;

    if (exitCode != 0) {
      stderr.writeln("$executable ${arguments.join(' ')}");
      stderr.write(process.stderr);
    }

    return exitCode;
  }

  String _prompt(
    final String Function(StringBuffer buffer) messageBuilder, {
    Map<int, Function(StringBuffer buffer, Position cursorIndex)>
        controlKeyMap =
        const {},
  }) {
    final buffer = StringBuffer();
    Position cursorIndex = Position();

    final controlMap =
        <int, Function(StringBuffer buffer, Position cursorIndex)>{};

    /// Insert
    controlMap[50] = (_, _) => stdin.readByteSync() == 126;

    /// Delete
    controlMap[51] = (buffer, cursorIndex) {
      if (stdin.readByteSync() == 126) {
        final text = buffer.toString();
        if (cursorIndex.value < text.length) {
          buffer.clear();
          buffer.write(
            text.substring(0, cursorIndex.value) +
                text.substring(cursorIndex.value + 1),
          );
        }
      }
    };

    /// Page Up
    controlMap[53] = (_, _) => stdin.readByteSync() == 126;

    /// Page Down
    controlMap[54] = (_, _) => stdin.readByteSync() == 126;

    /// Arrow Up
    controlMap[65] = (_, _) {};

    /// Arrow Down
    controlMap[66] = (_, _) {};

    /// Right
    controlMap[67] = (buffer, cursorIndex) {
      if (cursorIndex.value < buffer.length) cursorIndex.plus();
    };

    /// Left
    controlMap[68] = (buffer, cursorIndex) {
      if (cursorIndex > 0) cursorIndex.minus();
    };

    /// End
    controlMap[70] = (buffer, cursorIndex) => cursorIndex.value = buffer.length;

    /// Home
    controlMap[72] = (_, cursorIndex) => cursorIndex.value = 0;

    controlMap.addAll(controlKeyMap);

    while (true) {
      final text = buffer.toString();

      stdout.write(messageBuilder(buffer));

      if (cursorIndex < text.length) {
        stdout.write(Ansi.cursorBack(text.length - cursorIndex.value));
      }

      final byte = stdin.readByteSync();

      stdout.write(Ansi.carriageReturn + Ansi.clearDisplayDown);

      /// Enter
      if (byte == 10) break;

      /// Control Char ESC
      if (byte == 27) {
        if (stdin.readByteSync() != 91) continue;

        final newByte = stdin.readByteSync();

        if (controlMap.containsKey(newByte)) {
          controlMap[newByte]!.call(buffer, cursorIndex);
        } else {
          stderr.writeln('Control Char: $newByte');
        }

        continue;
      }

      /// Backspace
      if (byte == 127) {
        if (cursorIndex > 0) {
          final s = buffer.toString();
          if (s.isNotEmpty) {
            buffer.clear();
            buffer.write(
              text.substring(0, cursorIndex.value - 1) +
                  text.substring(cursorIndex.value),
            );
            cursorIndex.minus();
          }
        }
        continue;
      }

      buffer.clear();
      buffer.write(
        text.substring(0, cursorIndex.value) +
            String.fromCharCode(byte) +
            text.substring(cursorIndex.value),
      );
      cursorIndex.plus();
    }

    return buffer.toString();
  }
}
