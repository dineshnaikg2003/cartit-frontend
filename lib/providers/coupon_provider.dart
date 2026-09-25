import 'package:flutter/material.dart';
import '../core/network/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/coupon_model.dart';

class CouponProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CouponModel> _coupons = [];
  List<CouponModel> get coupons => _coupons;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchActiveCoupons() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Fetching active backend coupons...');

      final response = await _apiService.client.get(
        ApiConstants.activeCoupons,
      );

      debugPrint('Coupon status: ${response.statusCode}');
      debugPrint('Coupon response: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List? ?? [];
        _coupons = data
            .map((json) => CouponModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();

        debugPrint('Coupons loaded from backend: ${_coupons.length}');
      } else {
        _coupons = [];
        _errorMessage = response.data['message'] ?? 'Failed to load coupons';
      }
    } catch (e) {
      _coupons = [];
      _errorMessage = 'Failed to load backend coupons';
      debugPrint('Coupon fetch exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> validateCoupon(String code, double subtotal) async {
    try {
      final response = await _apiService.client.post(
        ApiConstants.validateCoupon,
        data: {
          'code': code,
          'subtotal': subtotal,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        return {
          'valid': data['valid'] ?? true,
          'code': data['code'] ?? code,
          'message': data['message'] ?? 'Coupon is valid',
          'discount': (data['discount'] as num?)?.toDouble() ?? 0.0,
          'subtotal': (data['subtotal'] as num?)?.toDouble() ?? subtotal,
          'finalAmount': (data['finalAmount'] as num?)?.toDouble() ?? (subtotal - ((data['discount'] as num?)?.toDouble() ?? 0.0)),
        };
      } else {
        return {
          'valid': false,
          'message': response.data['message'] ?? 'Invalid coupon code',
          'discount': 0.0,
        };
      }
    } catch (e) {
      debugPrint('Coupon validation error: $e');
      return {
        'valid': false,
        'message': 'Failed to validate coupon code',
        'discount': 0.0,
      };
    }
  }
}
