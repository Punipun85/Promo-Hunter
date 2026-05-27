class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
  });

  final int id;
  final String name;
  final String icon;

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: (map['id'] as num).toInt(),
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String? ?? 'category',
    );
  }
}
