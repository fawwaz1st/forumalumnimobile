class Category {
  final String id;
  final String name;
  final int color; // ARGB color value

  const Category({
    required this.id,
    required this.name,
    required this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        color: (json['color'] as num?)?.toInt() ?? 0xFF607D8B,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
      };
}
