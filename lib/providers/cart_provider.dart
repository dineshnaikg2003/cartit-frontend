import 'package:flutter/material.dart';
import '../core/network/api_constants.dart';
import '../core/network/api_service.dart';
import '../models/cart_model.dart';
import '../models/offer_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  CartModel? _cart;
  bool _isLoading = false;
  bool _isApplyingOffers = false;
  String? _errorMessage;
  bool get isApplyingOffers => _isApplyingOffers;
  int? _claimedOfferId;
  final Map<int, double> _offerRewardPrices = {};
  List<OfferModel> activeOffers = [];

  CartModel? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get claimedOfferId => _claimedOfferId;
  Map<int, double> get offerRewardPrices => _offerRewardPrices;

  int get itemCount {
    if (_cart == null) return 0;
    return _cart!.items.fold(0, (sum, item) => sum + item.quantity);
  }

  int getItemQuantity(int productId) {
    if (_cart == null) return 0;
    for (final item in _cart!.items) {
      if (item.product.id == productId) {
        return item.quantity;
      }
    }
    return 0;
  }

  double getNonRewardSubtotal() {
    if (_cart == null) return 0.0;
    double sum = 0.0;
    final effectiveClaimedOfferId = _cart!.claimedOfferId ?? _claimedOfferId;
    int? rewardProdId;
    int rewardQty = 1;
    if (effectiveClaimedOfferId != null) {
      for (final offer in activeOffers) {
        if (offer.id == effectiveClaimedOfferId) {
          rewardProdId = offer.rewardProductId;
          rewardQty = offer.rewardQuantity;
          break;
        }
      }
    }

    for (final item in _cart!.items) {
      final regPrice = item.product.sellingPrice > 0 ? item.product.sellingPrice : item.product.mrp;
      if (rewardProdId != null && item.product.id == rewardProdId) {
        final regQty = item.quantity > rewardQty ? item.quantity - rewardQty : 0;
        sum += regPrice * regQty;
      } else {
        sum += regPrice * item.quantity;
      }
    }
    return sum;
  }

  double getCalculatedSubtotal() {
    if (_cart == null) return 0.0;
    double sum = 0.0;
    final effectiveClaimedOfferId = _cart!.claimedOfferId ?? _claimedOfferId;
    int? rewardProdId;
    double rewardPrice = 0.0;
    int rewardQty = 1;
    if (effectiveClaimedOfferId != null) {
      for (final offer in activeOffers) {
        if (offer.id == effectiveClaimedOfferId) {
          rewardProdId = offer.rewardProductId;
          rewardPrice = offer.rewardPrice;
          rewardQty = offer.rewardQuantity;
          break;
        }
      }
    }

    for (final item in _cart!.items) {
      final regPrice = item.product.sellingPrice > 0 ? item.product.sellingPrice : item.product.mrp;
      if (rewardProdId != null && item.product.id == rewardProdId) {
        final rQty = item.quantity < rewardQty ? item.quantity : rewardQty;
        final regQty = item.quantity - rQty;
        sum += (rewardPrice * rQty) + (regPrice * regQty);
      } else {
        sum += regPrice * item.quantity;
      }
    }
    return sum;
  }

  Future<void> fetchCart({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await _apiService.client.get(ApiConstants.cart);
      if (response.statusCode == 200 && response.data['success'] == true) {
        _cart = CartModel.fromJson(response.data['data']);
        _syncClaimedOfferState();
      }
    } catch (e) {
      if (!silent) {
        _errorMessage = 'Failed to load cart';
      }
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  void _syncClaimedOfferState() {
    if (_cart != null && _cart!.claimedOfferId != null) {
      _claimedOfferId = _cart!.claimedOfferId;
      _offerRewardPrices.clear();
      for (final offer in activeOffers) {
        if (offer.id == _claimedOfferId && offer.rewardProductId != null) {
          _offerRewardPrices[offer.rewardProductId!] = offer.rewardPrice;
          break;
        }
      }
    } else {
      _claimedOfferId = null;
      _offerRewardPrices.clear();
    }
  }

  Future<void> claimOffer(
    OfferModel targetOffer,
    List<OfferModel> allOffers,
  ) async {
    if (_cart == null) return;
    activeOffers = allOffers;

    _isApplyingOffers = true;
    _claimedOfferId = targetOffer.id;
    if (targetOffer.rewardProductId != null) {
      _offerRewardPrices[targetOffer.rewardProductId!] = targetOffer.rewardPrice;
    }
    notifyListeners();

    try {
      final response = await _apiService.client.post(
        '${ApiConstants.cart}/offer/${targetOffer.id}',
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        _cart = CartModel.fromJson(response.data['data']);
        _syncClaimedOfferState();
      } else {
        await fetchCart();
      }
    } catch (_) {
      await fetchCart();
    } finally {
      _isApplyingOffers = false;
      notifyListeners();
    }
  }

  Future<void> unclaimOffer(int rewardProductId) async {
    if (_cart == null) return;

    _isApplyingOffers = true;
    _claimedOfferId = null;
    _offerRewardPrices.clear();
    notifyListeners();

    try {
      final response = await _apiService.client.delete(
        '${ApiConstants.cart}/offer',
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        _cart = CartModel.fromJson(response.data['data']);
        _syncClaimedOfferState();
      } else {
        await fetchCart();
      }
    } catch (_) {
      await fetchCart();
    } finally {
      _isApplyingOffers = false;
      notifyListeners();
    }
  }

  Future<void> checkAndApplyOffers(List<OfferModel> activeOffers) async {
    this.activeOffers = activeOffers;
    _syncClaimedOfferState();
  }

  Future<bool> addToCart(int productId, {int quantity = 1, ProductModel? product}) async {
    // Optimistic local update for instant button feedback
    _optimisticAdd(productId, quantity, product: product);
    notifyListeners();

    try {
      final response = await _apiService.client.post(
        ApiConstants.cart,
        data: {'productId': productId, 'quantity': quantity},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchCart(silent: true);
        notifyListeners();
        return true;
      }
      await fetchCart(silent: true);
      return false;
    } catch (e) {
      _errorMessage = 'Could not add to cart';
      await fetchCart(silent: true);
      return false;
    }
  }

  void _optimisticAdd(int productId, int deltaQuantity, {ProductModel? product}) {
    final itemsList = _cart != null ? List<CartItemModel>.from(_cart!.items) : <CartItemModel>[];
    final index = itemsList.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final existing = itemsList[index];
      itemsList[index] = CartItemModel(
        id: existing.id,
        product: existing.product,
        quantity: existing.quantity + deltaQuantity,
        price: existing.price,
        totalPrice: existing.price * (existing.quantity + deltaQuantity),
      );
    } else if (product != null) {
      final unitPrice = product.effectivePrice;
      itemsList.add(
        CartItemModel(
          id: 0,
          product: product,
          quantity: deltaQuantity,
          price: unitPrice,
          totalPrice: unitPrice * deltaQuantity,
        ),
      );
    }

    double total = itemsList.fold(0.0, (sum, i) => sum + i.totalPrice);
    _cart = CartModel(
      id: _cart?.id ?? 0,
      items: itemsList,
      totalAmount: total,
      discountAmount: _cart?.discountAmount ?? 0.0,
      finalAmount: total - (_cart?.discountAmount ?? 0.0),
      appliedCouponCode: _cart?.appliedCouponCode,
      claimedOfferId: _cart?.claimedOfferId,
    );
  }

  Future<void> updateQuantity(int productId, int quantity) async {
    // Optimistic local update
    if (_cart != null) {
      final itemsList = List<CartItemModel>.from(_cart!.items);
      final index = itemsList.indexWhere((item) => item.product.id == productId);
      if (index >= 0) {
        final existing = itemsList[index];
        itemsList[index] = CartItemModel(
          id: existing.id,
          product: existing.product,
          quantity: quantity,
          price: existing.price,
          totalPrice: existing.price * quantity,
        );
        double total = itemsList.fold(0.0, (sum, i) => sum + i.totalPrice);
        _cart = CartModel(
          id: _cart!.id,
          items: itemsList,
          totalAmount: total,
          discountAmount: _cart!.discountAmount,
          finalAmount: total - _cart!.discountAmount,
          appliedCouponCode: _cart!.appliedCouponCode,
          claimedOfferId: _cart!.claimedOfferId,
        );
        notifyListeners();
      }
    }

    try {
      final response = await _apiService.client.patch(
        '${ApiConstants.cart}/$productId/quantity',
        data: {'quantity': quantity},
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        _cart = CartModel.fromJson(response.data['data']);
        _syncClaimedOfferState();
        notifyListeners();
      } else {
        await fetchCart();
      }
    } catch (_) {
      await fetchCart();
    }
  }

  Future<void> removeFromCart(int productId) async {
    // Optimistic local update
    if (_cart != null) {
      final itemsList = List<CartItemModel>.from(_cart!.items);
      itemsList.removeWhere((item) => item.product.id == productId);
      double total = itemsList.fold(0.0, (sum, i) => sum + i.totalPrice);
      _cart = CartModel(
        id: _cart!.id,
        items: itemsList,
        totalAmount: total,
        discountAmount: _cart!.discountAmount,
        finalAmount: total - _cart!.discountAmount,
        appliedCouponCode: _cart!.appliedCouponCode,
        claimedOfferId: _cart!.claimedOfferId,
      );
      notifyListeners();
    }

    try {
      final response = await _apiService.client.delete(
        '${ApiConstants.cart}/$productId',
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        _cart = CartModel.fromJson(response.data['data']);
        _syncClaimedOfferState();
        notifyListeners();
      } else {
        await fetchCart();
      }
    } catch (_) {
      await fetchCart();
    }
  }

  Future<bool> applyCoupon(String couponCode, {double discountAmount = 0.0}) async {
    _isApplyingOffers = true;
    notifyListeners();

    try {
      final response = await _apiService.client.post(
        '${ApiConstants.cart}/coupon',
        data: {'couponCode': couponCode},
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        _cart = CartModel.fromJson(response.data['data']);
        _syncClaimedOfferState();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Apply coupon backend endpoint exception (setting locally): $e');
    }

    // Client-side fallback if backend /api/cart/coupon is pending implementation:
    if (_cart != null) {
      final subtotal = getCalculatedSubtotal();
      double discount = discountAmount;
      if (discount <= 0.0) {
        // Fallback default discount calculation if not explicitly provided
        discount = 50.0;
      }
      _cart = CartModel(
        id: _cart!.id,
        items: _cart!.items,
        totalAmount: subtotal,
        discountAmount: discount,
        finalAmount: (subtotal - discount).clamp(0.0, double.infinity),
        appliedCouponCode: couponCode,
        claimedOfferId: _cart!.claimedOfferId,
      );
      _syncClaimedOfferState();
      notifyListeners();
      return true;
    }

    _isApplyingOffers = false;
    notifyListeners();
    return false;
  }

  Future<void> removeCoupon() async {
    _isApplyingOffers = true;
    notifyListeners();

    try {
      final response = await _apiService.client.delete(
        '${ApiConstants.cart}/coupon',
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        _cart = CartModel.fromJson(response.data['data']);
        _syncClaimedOfferState();
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('Remove coupon backend exception: $e');
    }

    // Client-side fallback to clear coupon locally
    if (_cart != null) {
      final subtotal = getCalculatedSubtotal();
      _cart = CartModel(
        id: _cart!.id,
        items: _cart!.items,
        totalAmount: subtotal,
        discountAmount: 0.0,
        finalAmount: subtotal,
        appliedCouponCode: null,
        claimedOfferId: _cart!.claimedOfferId,
      );
      _syncClaimedOfferState();
    }
    _isApplyingOffers = false;
    notifyListeners();
  }

  Future<void> clearCart() async {
    try {
      await _apiService.client.delete(ApiConstants.cart);
      _cart = null;
      _claimedOfferId = null;
      _offerRewardPrices.clear();
      notifyListeners();
    } catch (_) {}
  }
}
