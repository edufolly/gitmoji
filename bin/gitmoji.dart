import 'package:gitmoji/gitmoji.dart';
import 'package:gitmoji/gitmoji_client.dart';
import 'package:gitmoji/main.dart';

void main(List<String> arguments) async {
  List<Gitmoji> gitmojiList = await GitmojiClient().fetch(false);

  if (gitmojiList.isNotEmpty) Main().run(gitmojiList);
}
