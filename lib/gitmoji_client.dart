import 'dart:convert';
import 'dart:io' as io;

import 'package:http/http.dart' as http;

import 'gitmoji.dart';

class GitmojiClient {
  Future<List<Gitmoji>> fetch(
    bool debug, {
    String url =
        'https://raw.githubusercontent.com/carloscuesta/gitmoji/refs/heads'
        '/master/packages/gitmojis/src/gitmojis.json',
  }) async {
    final cacheFile = io.File('${io.Directory.systemTemp.path}/gitmoji.cache');
    final cacheExpire = DateTime.now().subtract(Duration(days: 1));

    String jsonString = '';

    if (cacheFile.existsSync() &&
        cacheFile.lastModifiedSync().isAfter(cacheExpire)) {
      if (debug) print('Cache hit!');
      jsonString = cacheFile.readAsStringSync();
    } else {
      if (debug) print('Getting definition...');
      jsonString = await _fetchFromWeb(debug, url);

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
      return Gitmoji(
        emoji: map['emoji'].toString(),
        entity: map['entity'].toString(),
        code: map['code'].toString(),
        description: map['description'].toString().trim(),
        name: map['name'].toString(),
        semver: map['semver']?.toString(),
      );
    }).toList();
  }

  Future<String> _fetchFromWeb(bool debug, String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode < 200 || response.statusCode > 299) {
        throw Exception('Invalid status code: ${response.statusCode}');
      }

      return response.body;
    } on Exception catch (e, s) {
      if (debug) {
        print(e);
        print(s);
      }

      return '';
    }
  }
}
