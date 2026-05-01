import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Erro: Nenhuma versão fornecida.');
    exit(1);
  }

  final String version = args.first;
  final File file = File('bin/gitmoji.dart');

  if (!file.existsSync()) {
    print('Erro: Arquivo não encontrado em ${file.path}');
    exit(1);
  }

  String content = file.readAsStringSync();

  final RegExp regex = RegExp(r"final String version = 'dev';");
  content = content.replaceAll(regex, "final String version = '$version';");

  file.writeAsStringSync(content);
  print('Versão atualizada com sucesso para $version em bin/gitmoji.dart!');
}