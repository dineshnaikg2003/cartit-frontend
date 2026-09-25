import 'package:intl/intl.dart';
import '../core/network/api_constants.dart';

class OfferModel {
  final int id;
  final String name;
  final String? description;
  final double minimumPurchaseAmount;
  final int? rewardProductId;
  final String? rewardProductName;
  final String? rewardProductImageUrl;
  final int rewardQuantity;
  final DateTime startDate;
  final DateTime expiryDate;
  final bool active;
  final double rewardPrice;
  final String? unit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OfferModel({
    required this.id,
    required this.name,
    this.description,
    required this.minimumPurchaseAmount,
    this.rewardProductId,
    this.rewardProductName,
    this.rewardProductImageUrl,
    required this.rewardQuantity,
    required this.startDate,
    required this.expiryDate,
    required this.active,
    required this.rewardPrice,
    this.unit,
    this.createdAt,
    this.updatedAt,
  });

  String get displayQuantityUnit {
    final u = unit ?? 'PACK';
    return '$rewardQuantity $u';
  }

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    return DateTime.tryParse(val.toString()) ?? DateTime.now();
  }

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      minimumPurchaseAmount:
          (json['minimumPurchaseAmount'] as num?)?.toDouble() ?? 0.0,
      rewardProductId: (json['rewardProductId'] as num?)?.toInt(),
      rewardProductName: json['rewardProductName'],
      rewardProductImageUrl: json['rewardProductImageUrl'] ?? json['primaryImageUrl'],
      rewardQuantity: json['rewardQuantity'] ?? 1,
      startDate: _parseDate(json['startDate']),
      expiryDate: _parseDate(json['expiryDate']),
      active: json['active'] ?? false,
      rewardPrice: (json['rewardPrice'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? json['rewardUnit'],
      createdAt: json['createdAt'] != null ? _parseDate(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? _parseDate(json['updatedAt']) : null,
    );
  }

  String get rewardProductImageUrlFormatted {
    if (rewardProductImageUrl != null && rewardProductImageUrl!.isNotEmpty) {
      return ApiConstants.resolveImageUrl(rewardProductImageUrl!);
    }
    return '';
  }

  String get minimumPurchaseText {
    return 'Buy for ₹${minimumPurchaseAmount.toStringAsFixed(0)}';
  }

  String get rewardText {
    if (rewardProductName == null || rewardProductName!.isEmpty) {
      return 'Special reward';
    }

    return 'Get $rewardQuantity ${rewardProductName!} '
        'at ₹${rewardPrice.toStringAsFixed(0)}';
  }

  bool get isCurrentlyValid {
    final now = DateTime.now();
    return active && !now.isBefore(startDate) && !now.isAfter(expiryDate);
  }

  String get expiryText {
    return DateFormat('dd MMM yyyy').format(expiryDate);
  }
}
