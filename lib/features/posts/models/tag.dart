class Tag {
  final String id;
  final String name;
  final int color; // ARGB color value

  const Tag({
    required this.id,
    required this.name,
    required this.color,
  });

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        id: json['id'] as String,
        name: json['name'] as String,
        color: (json['color'] as num?)?.toInt() ?? 0xFF3F51B5,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
      };
}
