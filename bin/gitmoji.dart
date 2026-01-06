import 'package:gitmoji/github_client.dart';
import 'package:gitmoji/gitmoji.dart';
import 'package:gitmoji/gitmoji_client.dart';
import 'package:gitmoji/main.dart';

void main(List<String> arguments) async {
  final String version = 'dev';
  final bool debug = false;

  await GithubClient(debug).fetch(version);

  List<Gitmoji> gitmojiList = await GitmojiClient(debug).fetch();

  if (gitmojiList.isNotEmpty) Main(debug).run(gitmojiList);
}
