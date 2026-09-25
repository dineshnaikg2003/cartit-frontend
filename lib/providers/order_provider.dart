import 'package:flutter/material.dart';
import '../core/network/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<OrderModel> _orders = [];
  List<OrderModel> get orders => _orders;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.client.get(ApiConstants.orders);
      if (response.statusCode == 200 && response.data['success'] == true) {
        var list = response.data['data'] as List? ?? [];
        _orders = list.map((e) => OrderModel.fromJson(e)).toList();
      }
    } catch (e) {
      _errorMessage = 'Failed to load orders';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> placeOrder({
    required int addressId,
    String paymentMethod = 'COD',
    String? couponCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.client.post(
        ApiConstants.checkout,
        data: {
          'addressId': addressId,
          'paymentMethod': paymentMethod,
          if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
        },
      );

      _isLoading = false;
      if (response.statusCode == 201 || response.statusCode == 200) {
        final newOrder = OrderModel.fromJson(response.data['data']);
        _orders.insert(0, newOrder);
        notifyListeners();
        return newOrder;
      } else {
        _errorMessage = response.data['message'] ?? 'Failed to place order';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not process order. Please try again.';
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelOrder(int orderId) async {
    try {
      final response = await _apiService.client.patch('${ApiConstants.orders}/$orderId/cancel');
      if (response.statusCode == 200) {
        await fetchMyOrders();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rateOrder(int orderId, int rating, {String? reviewComment}) async {
    try {
      final response = await _apiService.client.post(
        '${ApiConstants.orders}/$orderId/rate',
        data: {
          'rating': rating,
          if (reviewComment != null && reviewComment.trim().isNotEmpty)
            'reviewComment': reviewComment.trim(),
        },
      );
      if (response.statusCode == 200) {
        await fetchMyOrders();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
