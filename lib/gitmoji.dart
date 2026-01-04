class GitMoji {
  final String emoji;
  final String entity;
  final String code;
  final String description;
  final String name;
  final String? semver;
  final String key;

  GitMoji({
    required this.emoji,
    required this.entity,
    required this.code,
    required this.description,
    required this.name,
    required this.semver,
  }) : key = '$name $description'.toLowerCase();

  @override
  String toString() => '$emoji  $description';
}
