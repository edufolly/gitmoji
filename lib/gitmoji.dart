class Gitmoji {
  final String emoji;
  final String entity;
  final String code;
  final String description;
  final String name;
  final String? semver;
  final String key;

  Gitmoji({
    required this.emoji,
    required this.entity,
    required this.code,
    required this.description,
    required this.name,
    required this.semver,
  }) : key = '$name $description'.toLowerCase();

  factory Gitmoji.fromJson(dynamic map) {
    if (map is Map<dynamic, dynamic>) {
      return Gitmoji(
        emoji: map['emoji'].toString(),
        entity: map['entity'].toString(),
        code: map['code'].toString(),
        description: map['description'].toString().trim(),
        name: map['name'].toString(),
        semver: map['semver']?.toString(),
      );
    } else {
      throw Exception();
    }
  }

  @override
  String toString() => '$emoji  $description';
}
