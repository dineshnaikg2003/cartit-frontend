class BrandModel {
  final int id;
  final String name;
  final String? logoUrl;
  final String? description;
  final bool active;

  BrandModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.description,
    this.active = true,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      logoUrl: json['logoUrl'] ?? json['logo'],
      description: json['description'],
      active: json['active'] ?? true,
    );
  }
}
