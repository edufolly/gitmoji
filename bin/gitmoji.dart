import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';
import 'package:http/http.dart' as http;

class GitMoji {
  final String emoji;
  final String entity;
  final String code;
  final String description;
  final String name;
  final String? semver;

  GitMoji({
    required this.emoji,
    required this.entity,
    required this.code,
    required this.description,
    required this.name,
    required this.semver,
  });

  @override
  String toString() => '$emoji  $description';
}

void main(List<String> arguments) async {
  final out = io.stdout;
  final stdin = io.stdin;
  final columns = out.terminalColumns;
  final lineCount = 5;
  final marker = '=>';
  final emptyMarker = ''.padRight(marker.length);
  var selected = 0;
  var search = StringBuffer();

  final response = await http.get(
    Uri.parse(
      'https://raw.githubusercontent.com/carloscuesta/gitmoji/refs/heads/master/packages/gitmojis/src/gitmojis.json',
    ),
  );

  final body = jsonDecode(response.body);

  out.writeln('Status: ${response.statusCode}');

  final List<dynamic> list = body['gitmojis'];

  final List<GitMoji> gitmojis = list.map((item) {
    final map = item as Map<String, dynamic>;
    return GitMoji(
      emoji: map['emoji'].toString(),
      entity: map['entity'].toString(),
      code: map['code'].toString(),
      description: map['description'].toString(),
      name: map['name'].toString(),
      semver: map['semver']?.toString(),
    );
  }).toList();

  out.writeln('GitMojis: ${gitmojis.length}');

  out.writeln('Columns: ${out.terminalColumns}');

  stdin.lineMode = false;
  stdin.echoMode = false;

  while (true) {
    final term = search.toString().toLowerCase();

    final emojis = List.of(gitmojis).where((gitmoji) {
      if (term.isEmpty) return true;
      return gitmoji.description.toLowerCase().contains(term);
    }).toList();

    for (int i in _createWindow(selected, lineCount, emojis.length)) {
      final gitmoji = emojis[i];

      if (i == selected) {
        out.write(marker);
      } else {
        out.write(emptyMarker);
      }

      out.writeln(' $gitmoji'.padRight(columns - marker.length));
    }

    out.write('Search: $search');

    final byte = stdin.readByteSync();

    if (byte == 10) {
      out.writeln('\n${emojis[selected]}'.padRight(columns));
      break;
    }

    for (int i = 0; i < min(emojis.length, lineCount); i++) {
      out.write('\r\x1b[K\x1b[1A'); // Clear lines.
    }

    if (byte == 27) {
      if (stdin.readByteSync() != 91) continue;

      final newByte = stdin.readByteSync();

      if (newByte == 66 && selected < emojis.length - 1) selected++;

      if (newByte == 65 && selected > 0) selected--;

      continue;
    }

    if (byte == 127) {
      final s = search.toString();
      if (s.isNotEmpty) {
        search.clear();
        search.write(s.substring(0, s.length - 1));
      }
      continue;
    }

    /// 127 backspace

    search.writeCharCode(byte);
  }

  out.writeln('Exit!'.padRight(columns));

  io.exit(0);
}

List<int> _createWindow(int selected, int lineCount, int max) {
  if (lineCount >= max) return List.generate(max, (i) => i);

  if (max - selected < lineCount) {
    return List.generate(lineCount, (i) => max - lineCount + i);
  }

  return List.generate(lineCount, (i) => selected + i);
}
