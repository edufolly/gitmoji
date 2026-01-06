import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ansi.dart';

class GithubClient {
  final bool debug;

  GithubClient(this.debug);

  Future<void> fetch(
    String version, {
    String newVersionMessage = 'New version available:',
    String url =
        'https://api.github.com/repos/edufolly/gitmoji/releases/latest',
    int timeout = 2,
  }) async {
    if (version == 'dev') return;

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(Duration(seconds: timeout));

      if (response.statusCode != 200) {
        if (debug) {
          print('Status code: ${response.statusCode}');
          print('Body: ${response.body}');
        }
        return;
      }

      final body = jsonDecode(response.body);

      final name = body['name']?.toString() ?? 'ERROR';

      if (version != name) {
        print(
          '\n$newVersionMessage ${Ansi.green}${Ansi.bold}$name${Ansi.reset}\n',
        );
      }
    } on Exception catch (e, s) {
      if (debug) {
        print(e);
        print(s);
      }
    }
  }
}
