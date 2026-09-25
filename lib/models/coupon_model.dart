import 'package:intl/intl.dart';

class CouponModel {
  final int id;
  final String code;
  final String? description;
  final String discountType; // PERCENTAGE or FLAT
  final double discountValue;
  final double minimumOrderAmount;
  final double? maxDiscountAmount;
  final DateTime startDate;
  final DateTime expiryDate;
  final bool active;

  const CouponModel({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    required this.minimumOrderAmount,
    this.maxDiscountAmount,
    required this.startDate,
    required this.expiryDate,
    required this.active,
  });

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return DateTime.tryParse(val.toString()) ?? DateTime.now();
  }

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      description: json['description'],
      discountType: json['discountType'] ?? 'FLAT',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
      minimumOrderAmount: (json['minimumOrderAmount'] as num?)?.toDouble() ?? 0.0,
      maxDiscountAmount: (json['maxDiscountAmount'] as num?)?.toDouble(),
      startDate: _parseDate(json['startDate']),
      expiryDate: _parseDate(json['expiryDate']),
      active: json['active'] ?? false,
    );
  }

  String get discountText {
    if (discountType == 'PERCENTAGE') {
      return '${discountValue.toStringAsFixed(0)}% OFF';
    }
    return '₹${discountValue.toStringAsFixed(0)} OFF';
  }

  String get title {
    if (discountType == 'PERCENTAGE') {
      return 'Get ${discountValue.toStringAsFixed(0)}% OFF on orders above ₹${minimumOrderAmount.toStringAsFixed(0)}';
    }
    return 'Flat ₹${discountValue.toStringAsFixed(0)} off on orders above ₹${minimumOrderAmount.toStringAsFixed(0)}';
  }

  String get expiryText {
    return DateFormat('dd MMM yyyy').format(expiryDate);
  }
}
