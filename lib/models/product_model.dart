import 'category_model.dart';
import 'brand_model.dart';
import '../core/network/api_constants.dart';

class ProductImageModel {
  final int id;
  final String imageUrl;
  final bool primary;

  ProductImageModel({
    required this.id,
    required this.imageUrl,
    this.primary = false,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: json['id'] ?? 0,
      imageUrl: json['imageUrl'] ?? json['url'] ?? '',
      primary: json['primary'] ?? json['isPrimary'] ?? false,
    );
  }
}

class ProductModel {
  final int id;
  final String name;
  final String? description;

  // Backend:
  // mrp        -> original price
  // sellingPrice -> actual selling price
  final double price;
  final double? discountPrice;

  final int stock;
  final bool featured;
  final bool active;

  final CategoryModel? category;
  final BrandModel? brand;

  final List<ProductImageModel> images;

  // Backend directly provides this value.
  final String _apiPrimaryImageUrl;

  final String? unit;
  final double? unitQuantity;
  final int? maxPurchaseQuantity;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.discountPrice,
    required this.stock,
    this.featured = false,
    this.active = true,
    this.category,
    this.brand,
    this.images = const [],
    this._apiPrimaryImageUrl = '',
    this.unit,
    this.maxPurchaseQuantity,
    this.unitQuantity,
  });

  String get primaryImageUrl {
    // Backend sends primaryImageUrl directly. Resolving relative or localhost URLs.
    if (_apiPrimaryImageUrl.isNotEmpty) {
      return ApiConstants.resolveImageUrl(_apiPrimaryImageUrl);
    }

    if (images.isNotEmpty) {
      final primaryImg = images.firstWhere(
        (img) => img.primary,
        orElse: () => images.first,
      );
      return ApiConstants.resolveImageUrl(primaryImg.imageUrl);
    }

    return '';
  }

  String get formattedUnit {
    if (unitQuantity != null && unitQuantity! > 0 && unit != null && unit!.toString().trim().isNotEmpty) {
      final qtyStr = unitQuantity! % 1 == 0
          ? unitQuantity!.toInt().toString()
          : unitQuantity!.toString();
      final uName = _cleanUnitName(unit!.toString());
      return '$qtyStr $uName';
    }
    if (unit != null && unit!.toString().trim().isNotEmpty) {
      return _cleanUnitName(unit!.toString());
    }
    return '';
  }

  static String _cleanUnitName(String u) {
    final lower = u.trim().toLowerCase();
    if (lower == 'kg' || lower == 'kilogram') return 'kg';
    if (lower == 'g' || lower == 'gram') return 'g';
    if (lower == 'l' || lower == 'liter' || lower == 'litre') return 'L';
    if (lower == 'ml' || lower == 'milliliter') return 'ml';
    if (lower == 'piece' || lower == 'pcs') return 'piece';
    if (lower == 'packet' || lower == 'pack') return 'pack';
    if (lower == 'dozen') return 'dozen';
    return u;
  }

  double get effectivePrice {
    if (discountPrice != null &&
        discountPrice! > 0 &&
        discountPrice! < price) {
      return discountPrice!;
    }

    return price;
  }

  double get sellingPrice => effectivePrice;
  double get mrp => price;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] as List? ?? [];

    final imageList = rawImages
        .map(
          (e) => ProductImageModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();

    final mrp = (json['mrp'] as num?)?.toDouble() ??
        (json['price'] as num?)?.toDouble() ??
        0.0;

    final sellingPrice = (json['sellingPrice'] as num?)?.toDouble() ??
        (json['discountPrice'] as num?)?.toDouble();

    return ProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],

      // price = MRP
      // discountPrice = selling price
      price: mrp,
      discountPrice: sellingPrice,

      stock: (json['stock'] as num?)?.toInt() ??
          (json['quantity'] as num?)?.toInt() ??
          (json['stockQuantity'] as num?)?.toInt() ??
          99,
      featured: json['featured'] ?? false,
      active: json['active'] ?? true,

      category: json['category'] != null
          ? CategoryModel.fromJson(
              Map<String, dynamic>.from(json['category']),
            )
          : null,

      brand: json['brand'] != null
          ? BrandModel.fromJson(
              Map<String, dynamic>.from(json['brand']),
            )
          : null,

      images: imageList,

      apiPrimaryImageUrl: json['primaryImageUrl'] ?? json['thumbnail'] ?? '',

      unit: json['unit']?.toString(), //kg,g
      maxPurchaseQuantity: json['maxPurchaseQuantity'],
      unitQuantity: json['unitQuantity']?.toDouble(), //1.5
    );
  }
}