import 'product_model.dart';
import 'address_model.dart';

class OrderItemModel {
  final int id;
  final ProductModel? product;
  final String productName;
  final int quantity;
  final double price;
  final double totalPrice;

  OrderItemModel({
    required this.id,
    this.product,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? json['orderItemId'] ?? 0,
      product: json['product'] != null
          ? ProductModel.fromJson(Map<String, dynamic>.from(json['product']))
          : null,
      productName: json['productName'] ?? json['product']?['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['unitPrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OrderModel {
  final int id;
  final String orderNumber;
  final String status;
  final String? paymentMethod;
  final String? paymentStatus;
  final double totalAmount;
  final double discountAmount;
  final double deliveryCharge;
  final double finalAmount;
  final AddressModel? shippingAddress;
  final List<OrderItemModel> items;
  final String? createdAt;
  final int? rating;
  final String? reviewComment;
  final String? ratedAt;
  final String? deliveryBoyName;
  final String? deliveryBoyPhone;
  final double? currentDeliveryLat;
  final double? currentDeliveryLng;
  final double? currentDeliveryHeading;
  final double? currentDeliverySpeed;
  final double? currentDeliveryAccuracy;
  final String? currentDeliveryUpdatedAt;
  final String? storeName;
  final String? storeAddress;
  final double? storeLat;
  final double? storeLng;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    this.paymentMethod,
    this.paymentStatus,
    required this.totalAmount,
    this.discountAmount = 0.0,
    this.deliveryCharge = 0.0,
    required this.finalAmount,
    this.shippingAddress,
    required this.items,
    this.createdAt,
    this.rating,
    this.reviewComment,
    this.ratedAt,
    this.deliveryBoyName,
    this.deliveryBoyPhone,
    this.currentDeliveryLat,
    this.currentDeliveryLng,
    this.currentDeliveryHeading,
    this.currentDeliverySpeed,
    this.currentDeliveryAccuracy,
    this.currentDeliveryUpdatedAt,
    this.storeName,
    this.storeAddress,
    this.storeLat,
    this.storeLng,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    List<OrderItemModel> itemList = rawItems
        .map((e) => OrderItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    AddressModel? address;
    if (json['shippingAddress'] != null) {
      address = AddressModel.fromJson(Map<String, dynamic>.from(json['shippingAddress']));
    } else if (json['deliveryAddressLine1'] != null) {
      address = AddressModel(
        id: 0,
        fullName: json['deliveryName'] ?? '',
        phone: json['deliveryPhone'] ?? '',
        street: json['deliveryAddressLine1'] ?? '',
        city: json['deliveryCity'] ?? '',
        state: json['deliveryState'] ?? '',
        zipCode: json['deliveryPostalCode'] ?? '',
        isDefault: true,
        latitude: (json['deliveryLatitude'] as num?)?.toDouble() ?? (json['shippingAddress']?['latitude'] as num?)?.toDouble(),
        longitude: (json['deliveryLongitude'] as num?)?.toDouble() ?? (json['shippingAddress']?['longitude'] as num?)?.toDouble(),
      );
    }

    final subtotal = (json['subTotal'] as num?)?.toDouble() ??
        (json['totalAmount'] as num?)?.toDouble() ??
        0.0;
    final discount = (json['discount'] as num?)?.toDouble() ??
        (json['discountAmount'] as num?)?.toDouble() ??
        0.0;
    final deliveryFee = (json['deliveryCharge'] as num?)?.toDouble() ??
        (json['deliveryFee'] as num?)?.toDouble() ??
        0.0;
    final grandTotal = (json['totalAmount'] as num?)?.toDouble() ??
        (json['finalAmount'] as num?)?.toDouble() ??
        (subtotal - discount + deliveryFee);

    return OrderModel(
      id: json['id'] ?? 0,
      orderNumber: json['orderNumber'] ?? '#${json['id']}',
      status: json['orderStatus']?.toString() ?? json['status']?.toString() ?? 'PENDING',
      paymentMethod: json['paymentMethod']?.toString(),
      paymentStatus: json['paymentStatus']?.toString(),
      totalAmount: subtotal,
      discountAmount: discount,
      deliveryCharge: deliveryFee,
      finalAmount: grandTotal,
      shippingAddress: address,
      items: itemList,
      createdAt: json['placedAt']?.toString() ?? json['createdAt']?.toString() ?? json['orderDate']?.toString(),
      rating: (json['rating'] as num?)?.toInt(),
      reviewComment: json['reviewComment']?.toString(),
      ratedAt: json['ratedAt']?.toString(),
      deliveryBoyName: json['deliveryBoyName']?.toString(),
      deliveryBoyPhone: json['deliveryBoyPhone']?.toString(),
      currentDeliveryLat: (json['currentDeliveryLatitude'] as num?)?.toDouble(),
      currentDeliveryLng: (json['currentDeliveryLongitude'] as num?)?.toDouble(),
      currentDeliveryHeading: (json['currentDeliveryHeading'] as num?)?.toDouble(),
      currentDeliverySpeed: (json['currentDeliverySpeed'] as num?)?.toDouble(),
      currentDeliveryAccuracy: (json['currentDeliveryAccuracy'] as num?)?.toDouble(),
      currentDeliveryUpdatedAt: json['currentDeliveryUpdatedAt']?.toString(),
      storeName: json['storeName']?.toString(),
      storeAddress: json['storeAddress']?.toString(),
      storeLat: (json['storeLatitude'] as num?)?.toDouble(),
      storeLng: (json['storeLongitude'] as num?)?.toDouble(),
    );
  }
}
