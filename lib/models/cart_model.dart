import 'product_model.dart';

class CartItemModel {
  final int id;
  final ProductModel product;
  final int quantity;
  final double price;
  final double totalPrice;

  CartItemModel({
    required this.id,
    required this.product,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final prodJson = json['product'] != null
        ? Map<String, dynamic>.from(json['product'])
        : <String, dynamic>{};

    final unitPrice = (json['unitPrice'] as num?)?.toDouble() ??
        (json['price'] as num?)?.toDouble() ??
        (prodJson['sellingPrice'] as num?)?.toDouble() ??
        (prodJson['mrp'] as num?)?.toDouble() ??
        0.0;

    final qty = json['quantity'] ?? 1;
    final total = (json['totalPrice'] as num?)?.toDouble() ?? (unitPrice * qty);

    return CartItemModel(
      id: json['cartItemId'] ?? json['id'] ?? 0,
      product: ProductModel.fromJson(prodJson),
      quantity: qty,
      price: unitPrice,
      totalPrice: total,
    );
  }
}

class CartModel {
  final int id;
  final List<CartItemModel> items;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String? appliedCouponCode;
  final int? claimedOfferId;

  CartModel({
    required this.id,
    required this.items,
    required this.totalAmount,
    this.discountAmount = 0.0,
    required this.finalAmount,
    this.appliedCouponCode,
    this.claimedOfferId,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    List<CartItemModel> itemList = rawItems
        .map((e) => CartItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    double calculatedSubtotal = itemList.fold(
      0.0,
      (sum, item) => sum + (item.totalPrice > 0 ? item.totalPrice : (item.price * item.quantity)),
    );

    double parsedSubtotal = (json['subTotal'] as num?)?.toDouble() ??
        (json['totalAmount'] as num?)?.toDouble() ??
        calculatedSubtotal;

    double parsedDiscount = (json['discountAmount'] as num?)?.toDouble() ??
        (json['discount'] as num?)?.toDouble() ??
        0.0;

    double parsedFinal = (json['finalAmount'] as num?)?.toDouble() ??
        (parsedSubtotal - parsedDiscount);

    return CartModel(
      id: json['cartId'] ?? json['id'] ?? 0,
      items: itemList,
      totalAmount: parsedSubtotal > 0 ? parsedSubtotal : calculatedSubtotal,
      discountAmount: parsedDiscount,
      finalAmount: parsedFinal > 0 ? parsedFinal : (parsedSubtotal - parsedDiscount),
      appliedCouponCode: json['appliedCouponCode'],
      claimedOfferId: (json['claimedOfferId'] as num?)?.toInt(),
    );
  }
}
