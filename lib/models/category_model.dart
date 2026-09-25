class CategoryModel {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool active;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.active = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'] ?? json['image'],
      active: json['active'] ?? true,
    );
  }
}
