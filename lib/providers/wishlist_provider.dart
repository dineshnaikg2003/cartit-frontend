import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/product_model.dart';

class WishlistProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ProductModel> _wishlistItems = [];
  List<ProductModel> get wishlistItems => _wishlistItems;

  Set<int> _wishlistedProductIds = {};

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool isProductWishlisted(int productId) => _wishlistedProductIds.contains(productId);

  Future<void> fetchWishlist() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.client.get(ApiConstants.wishlist);
      if (response.statusCode == 200 && response.data['success'] == true) {
        var rawList = response.data['data'] as List? ?? [];
        _wishlistItems = rawList.map((item) {
          if (item is Map && item.containsKey('product') && item['product'] != null) {
            return ProductModel.fromJson(item['product']);
          }
          return ProductModel.fromJson(item);
        }).toList();
        _wishlistedProductIds = _wishlistItems.map((p) => p.id).toSet();
      }
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleWishlist(ProductModel product) async {
    final productId = product.id;
    final isWishlisted = _wishlistedProductIds.contains(productId);

    if (isWishlisted) {
      _wishlistedProductIds.remove(productId);
      _wishlistItems.removeWhere((p) => p.id == productId);
      notifyListeners();

      try {
        await _apiService.client.delete('${ApiConstants.wishlist}/$productId');
        return false;
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 404) {
          return false;
        }
        _wishlistedProductIds.add(productId);
        if (!_wishlistItems.any((p) => p.id == productId)) {
          _wishlistItems.add(product);
        }
        notifyListeners();
        return true;
      }
    } else {
      _wishlistedProductIds.add(productId);
      if (!_wishlistItems.any((p) => p.id == productId)) {
        _wishlistItems.add(product);
      }
      notifyListeners();

      try {
        await _apiService.client.post(
          ApiConstants.wishlist,
          data: {'productId': productId},
        );
        return true;
      } catch (e) {
        if (e is DioException &&
            (e.response?.statusCode == 400 || e.response?.statusCode == 409)) {
          return true;
        }
        _wishlistedProductIds.remove(productId);
        _wishlistItems.removeWhere((p) => p.id == productId);
        notifyListeners();
        return false;
      }
    }
  }
}
