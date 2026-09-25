import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../models/address_model.dart';
import '../../models/cart_model.dart';
import '../../models/offer_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/coupon_provider.dart';
import '../../providers/offer_provider.dart';
import '../../providers/order_provider.dart';
import '../checkout/address_form_dialog.dart';
import '../../widgets/modern_loaders.dart';

/// Zepto Unified Cart & Express Checkout Screen.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  AddressModel? _selectedAddress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final addressProvider = context.read<AddressProvider>();
      final orderProvider = context.read<OrderProvider>();
      final couponProvider = context.read<CouponProvider>();
      final offerProvider = context.read<OfferProvider>();
      final cartProvider = context.read<CartProvider>();

      await Future.wait([
        addressProvider.fetchAddresses(),
        orderProvider.fetchMyOrders(),
        couponProvider.fetchActiveCoupons(),
        offerProvider.fetchActiveOffers(),
        cartProvider.fetchCart(),
      ]);

      if (mounted) {
        setState(() {
          _selectedAddress = addressProvider.defaultAddress ??
              (addressProvider.addresses.isNotEmpty ? addressProvider.addresses.first : null);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6);
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.border;

    final cartProvider = context.watch<CartProvider>();
    final offerProvider = context.watch<OfferProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final orderProvider = context.watch<OrderProvider>();

    final cart = cartProvider.cart;
    final offers = offerProvider.offers;

    if (cart != null && cart.items.isNotEmpty && offers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        cartProvider.checkAndApplyOffers(offers);
      });
    }

    final activeAddress = _selectedAddress ??
        addressProvider.defaultAddress ??
        (addressProvider.addresses.isNotEmpty ? addressProvider.addresses.first : null);

    final activeOrders = orderProvider.orders
        .where((o) => o.status != 'DELIVERED' && o.status != 'CANCELLED')
        .toList();
    final bool hasActiveOrder = activeOrders.isNotEmpty;

    final calculatedSubtotal = cartProvider.getCalculatedSubtotal();
    final nonRewardSubtotal = cartProvider.getNonRewardSubtotal();
    final deliveryCharge = cart != null && cart.items.isNotEmpty
        ? (calculatedSubtotal >= 99.0 ? 0.0 : 40.0)
        : 0.0;

    final grandTotal = cart != null
        ? (cart.discountAmount > 0
            ? (calculatedSubtotal + deliveryCharge - cart.discountAmount)
            : calculatedSubtotal + deliveryCharge)
        : 0.0;

    final qualifyingOffers = offers.where((o) =>
        o.isCurrentlyValid &&
        o.rewardProductId != null &&
        o.rewardProductId! > 0 &&
        nonRewardSubtotal >= o.minimumPurchaseAmount).toList();

    OfferModel? upcomingOffer;
    if (offers.isNotEmpty && cart != null && cart.items.isNotEmpty) {
      final unreachedOffers = offers
          .where((o) => o.isCurrentlyValid && o.minimumPurchaseAmount > nonRewardSubtotal)
          .toList();
      if (unreachedOffers.isNotEmpty) {
        unreachedOffers.sort((a, b) => a.minimumPurchaseAmount.compareTo(b.minimumPurchaseAmount));
        upcomingOffer = unreachedOffers.first;
      }
    }

    final List<_CartDisplayItem> displayItems = [];
    if (cart != null && cart.items.isNotEmpty) {
      int? claimedRewardProdId;
      double claimedRewardPrice = 0.0;
      int claimedRewardQty = 1;
      String? claimedRewardUnit;
      final effectiveClaimedOfferId = cart.claimedOfferId ?? cartProvider.claimedOfferId;
      if (effectiveClaimedOfferId != null) {
        for (final offer in offers) {
          if (offer.id == effectiveClaimedOfferId && offer.rewardProductId != null) {
            claimedRewardProdId = offer.rewardProductId;
            claimedRewardPrice = offer.rewardPrice;
            claimedRewardQty = offer.rewardQuantity;
            claimedRewardUnit = offer.unit;
            break;
          }
        }
      }

      for (final item in cart.items) {
        if (claimedRewardProdId != null && item.product.id == claimedRewardProdId) {
          final rQty = item.quantity < claimedRewardQty ? item.quantity : claimedRewardQty;
          final regQty = item.quantity - rQty;

          if (regQty > 0) {
            displayItems.add(_CartDisplayItem(
              rawItem: item,
              isRewardCard: false,
              displayQuantity: regQty,
              displayUnitPrice: item.product.sellingPrice > 0 ? item.product.sellingPrice : item.product.mrp,
            ));
          }

          displayItems.add(_CartDisplayItem(
            rawItem: item,
            isRewardCard: true,
            displayQuantity: rQty,
            displayUnitPrice: claimedRewardPrice,
            rewardUnit: claimedRewardUnit,
          ));
        } else {
          displayItems.add(_CartDisplayItem(
            rawItem: item,
            isRewardCard: false,
            displayQuantity: item.quantity,
            displayUnitPrice: item.product.sellingPrice > 0 ? item.product.sellingPrice : item.product.mrp,
          ));
        }
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: AppColors.cardShadow,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Cart & Checkout',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTitle : AppColors.title,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 1.0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '10 MINS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            if (activeAddress != null)
              Text(
                'Delivering to ${activeAddress.city}, ${activeAddress.street}',
                style: TextStyle(
                  color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? AppColors.darkTitle : AppColors.title,
            ),
            tooltip: 'Refresh Cart',
            onPressed: () async {
              await Future.wait([
                context.read<CartProvider>().fetchCart(),
                context.read<OfferProvider>().fetchActiveOffers(),
                context.read<CouponProvider>().fetchActiveCoupons(),
                context.read<AddressProvider>().fetchAddresses(),
              ]);
            },
          ),
        ],
      ),
      body: cartProvider.isLoading && cart == null
          ? ModernLoaders.listCardSkeleton(context, count: 3)
          : cart == null || cart.items.isEmpty
              ? _buildEmptyState(context)
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Coupons & Offers Minimal Card (Zepto Style)
                      Consumer<CouponProvider>(
                        builder: (context, couponProvider, child) {
                          final appliedCode = cart.appliedCouponCode;
                          final bool hasAppliedCoupon = appliedCode != null && appliedCode.isNotEmpty;

                          return Container(
                            decoration: BoxDecoration(
                              color: hasAppliedCoupon
                                  ? const Color(0xFFE8F5E9)
                                  : cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: hasAppliedCoupon ? const Color(0xFFA5D6A7) : borderColor,
                              ),
                            ),
                            child: InkWell(
                              onTap: () => Navigator.pushNamed(context, AppRoutes.coupons),
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        hasAppliedCoupon ? Icons.check_circle_rounded : Icons.percent_rounded,
                                        color: const Color(0xFF2E7D32),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            hasAppliedCoupon
                                                ? 'Coupon "$appliedCode" Applied'
                                                : 'Coupons & Offers',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: hasAppliedCoupon ? const Color(0xFF1B5E20) : (isDark ? AppColors.darkTitle : AppColors.title),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            hasAppliedCoupon
                                                ? 'Saved ${Formatters.currency(cart.discountAmount)} on this order'
                                                : 'Save more with store coupons',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: hasAppliedCoupon ? FontWeight.w700 : FontWeight.w500,
                                              color: hasAppliedCoupon ? const Color(0xFF2E7D32) : (isDark ? AppColors.darkSubtitle : AppColors.subtitle),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (hasAppliedCoupon)
                                      InkWell(
                                        onTap: () async {
                                          await cartProvider.removeCoupon();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Coupon removed'),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          child: Text(
                                            'REMOVE',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.redAccent,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Row(
                                        children: [
                                          Text(
                                            'View All',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 14),

                      // 2. Delivery Address Dropdown Selection Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delivering to Address',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => const AddressFormDialog(),
                                    ).then((_) {
                                      addressProvider.fetchAddresses();
                                    });
                                  },
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Add New'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            addressProvider.addresses.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(14),
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkBackground : const Color(0xFFFAFAFA),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: const Text(
                                      'No saved address. Tap + Add New to add your delivery location.',
                                      style: TextStyle(fontSize: 12, color: AppColors.subtitle),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkBackground : const Color(0xFFFAFAFA),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<AddressModel>(
                                        value: activeAddress != null &&
                                                addressProvider.addresses.any((a) => a.id == activeAddress.id)
                                            ? addressProvider.addresses.firstWhere((a) => a.id == activeAddress.id)
                                            : addressProvider.addresses.first,
                                        isExpanded: true,
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                                        dropdownColor: cardBg,
                                        items: addressProvider.addresses.map((AddressModel address) {
                                          return DropdownMenuItem<AddressModel>(
                                            value: address,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  address.isDefault ? Icons.home_rounded : Icons.location_city_rounded,
                                                  size: 18,
                                                  color: AppColors.primary,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    '${address.fullName} • ${address.street}, ${address.city}',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: isDark ? AppColors.darkTitle : AppColors.title,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (AddressModel? newAddr) {
                                          if (newAddr != null) {
                                            setState(() => _selectedAddress = newAddr);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 3. Cart Items List Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cart Items (${displayItems.length})',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.darkTitle : AppColors.title,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: displayItems.length,
                              separatorBuilder: (context, index) => Divider(height: 20, color: borderColor),
                              itemBuilder: (context, index) {
                                final displayItem = displayItems[index];
                                return _buildCartItemCard(context, displayItem, cartProvider);
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 4. Free Delivery Tracker Banner
                      _buildFreeDeliveryProgress(calculatedSubtotal),

                      if (upcomingOffer != null) ...[
                        const SizedBox(height: 10),
                        _buildUpcomingOfferBanner(upcomingOffer, nonRewardSubtotal),
                      ],

                      if (qualifyingOffers.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildRewardSelectionSection(context, qualifyingOffers, cartProvider, offers),
                      ],

                      const SizedBox(height: 14),

                      // 5. Bill Summary Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bill Summary',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: isDark ? AppColors.darkTitle : AppColors.title,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildBillRow('Item Total', Formatters.currency(calculatedSubtotal), isDark),
                            if (cart.discountAmount > 0 || (cart.appliedCouponCode != null && cart.appliedCouponCode!.isNotEmpty)) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Coupon Discount',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                                        ),
                                      ),
                                      if (cart.appliedCouponCode != null && cart.appliedCouponCode!.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            cart.appliedCouponCode!,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.success,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '-${Formatters.currency(cart.discountAmount)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Delivery Charge',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: deliveryCharge == 0 ? AppColors.success.withValues(alpha: 0.15) : Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        deliveryCharge == 0 ? 'FREE' : 'Min ₹99',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: deliveryCharge == 0 ? AppColors.success : Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  deliveryCharge == 0 ? 'FREE' : Formatters.currency(deliveryCharge),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: deliveryCharge == 0 ? AppColors.success : (isDark ? AppColors.darkTitle : AppColors.title),
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 24, color: borderColor),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'To Pay',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? AppColors.darkTitle : AppColors.title,
                                  ),
                                ),
                                Text(
                                  Formatters.currency(grandTotal),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 6. Zepto Style Cancellation Policy & Guarantee Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Cancellation Policy & Assurance',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.darkTitle : AppColors.title,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Orders cannot be cancelled once packed or dispatched. 100% refund for damaged or missing items upon delivery.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100), // Spacing for bottom sheet
                    ],
                  ),
                ),

      // Fixed Bottom Action Bar: Proceed to Pay
      bottomSheet: (cart != null && cart.items.isNotEmpty)
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: cardBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Formatters.currency(grandTotal),
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                        ),
                      ),
                      const Text(
                        'GRAND TOTAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (orderProvider.isLoading || hasActiveOrder || activeAddress == null)
                          ? null
                          : () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.payment,
                                arguments: activeAddress,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasActiveOrder ? Colors.grey.shade400 : AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: orderProvider.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              hasActiveOrder ? 'Order In Progress' : 'Proceed to Pay',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                            ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildFreeDeliveryProgress(double currentSubtotal) {
    const double freeDeliveryThreshold = 99.0;
    final double progress = (currentSubtotal / freeDeliveryThreshold).clamp(0.0, 1.0);
    final double remaining = freeDeliveryThreshold - currentSubtotal;
    final isFree = remaining <= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFree
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.primaryLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFree
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isFree ? Icons.local_shipping_rounded : Icons.local_shipping_outlined,
                color: isFree ? AppColors.success : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFree
                      ? '🎉 You unlocked FREE Delivery!'
                      : 'Add ${Formatters.currency(remaining)} more for FREE Delivery',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isFree ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(
                isFree ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingOfferBanner(OfferModel offer, double currentSubtotal) {
    final double remaining = offer.minimumPurchaseAmount - currentSubtotal;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2215) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.amber.shade800.withValues(alpha: 0.5) : Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber.shade400.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.card_giftcard_rounded, color: Colors.amber.shade900, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unlock Free Gift!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                  ),
                ),
                Text(
                  'Add ${Formatters.currency(remaining)} more to get ${offer.rewardProductName ?? 'a special gift'} for ${offer.rewardPrice == 0 ? 'FREE' : Formatters.currency(offer.rewardPrice)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardSelectionSection(
    BuildContext context,
    List<OfferModel> qualifyingOffers,
    CartProvider cartProvider,
    List<OfferModel> allOffers,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppColors.darkSurface : Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.amber.shade700, size: 18),
              const SizedBox(width: 6),
              Text(
                'Unlocked Free Rewards',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isDark ? AppColors.darkTitle : AppColors.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: List.generate(
              qualifyingOffers.length,
              (index) {
                final offer = qualifyingOffers[index];
                final rewardId = offer.rewardProductId ?? 0;
                final isSelected = cartProvider.claimedOfferId == offer.id;
                final nonRewardSubtotal = cartProvider.getNonRewardSubtotal();
                final isDisabled = nonRewardSubtotal < offer.minimumPurchaseAmount;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF2A2215) : const Color(0xFFFFFBEB))
                        : (isDark ? AppColors.darkBackground : const Color(0xFFFAFAFA)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.amber.shade600
                          : (isDark ? AppColors.darkCardBorder : Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: offer.rewardProductImageUrlFormatted.isNotEmpty
                            ? Image.network(
                                offer.rewardProductImageUrlFormatted,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Icon(Icons.card_giftcard, size: 18, color: Colors.amber.shade700),
                              )
                            : Icon(Icons.card_giftcard, size: 18, color: Colors.amber.shade700),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 2,
                              children: [
                                Text(
                                  offer.rewardProductName ?? 'Store Gift',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: isDisabled
                                        ? Colors.grey.shade500
                                        : (isDark ? AppColors.darkTitle : AppColors.title),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    offer.displayQuantityUnit,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              offer.rewardPrice == 0
                                  ? 'FREE REWARD'
                                  : 'Reward: ${Formatters.currency(offer.rewardPrice)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDisabled
                                    ? Colors.grey.shade500
                                    : (offer.rewardPrice == 0
                                        ? AppColors.success
                                        : (isDark ? Colors.amberAccent : Colors.amber.shade900)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 30,
                        child: isSelected
                            ? InkWell(
                                onTap: () async {
                                  final offerProvider = context.read<OfferProvider>();
                                  await cartProvider.unclaimOffer(rewardId);
                                  if (context.mounted) {
                                    await cartProvider.fetchCart();
                                    await offerProvider.fetchActiveOffers();
                                    setState(() {});
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_rounded, color: Colors.white, size: 12),
                                      SizedBox(width: 2),
                                      Text(
                                        'CLAIMED',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: isDisabled
                                    ? null
                                    : () async {
                                        final offerProvider = context.read<OfferProvider>();
                                        await cartProvider.claimOffer(offer, allOffers);
                                        if (context.mounted) {
                                          await cartProvider.fetchCart();
                                          await offerProvider.fetchActiveOffers();
                                          setState(() {});
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'CLAIM',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    _CartDisplayItem displayItem,
    CartProvider cartProvider,
  ) {
    final item = displayItem.rawItem;
    final isRewardProduct = displayItem.isRewardCard;
    final displayQty = displayItem.displayQuantity;
    final displayPrice = displayItem.displayUnitPrice;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRewardProduct
            ? (isDark ? const Color(0xFF38290D) : Colors.amber.shade50.withValues(alpha: 0.6))
            : (isDark ? AppColors.darkSurface : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRewardProduct
              ? Colors.amber.shade400
              : (isDark ? AppColors.darkCardBorder : AppColors.border),
          width: isRewardProduct ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.product.primaryImageUrl.isNotEmpty
                ? Image.network(
                    item.product.primaryImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.shopping_bag,
                      size: 26,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.shopping_bag,
                    size: 26,
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRewardProduct) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade800,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'STORE REWARD ITEM',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? AppColors.darkTitle : AppColors.title,
                  ),
                ),
                Text(
                  displayItem.displayUnit,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      displayPrice == 0 ? 'FREE' : Formatters.currency(displayPrice),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isRewardProduct
                            ? (isDark ? Colors.amberAccent : Colors.amber.shade900)
                            : AppColors.primary,
                      ),
                    ),
                    if (isRewardProduct && item.product.mrp > displayPrice) ...[
                      const SizedBox(width: 6),
                      Text(
                        'MRP ${Formatters.currency(item.product.mrp)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          isRewardProduct
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF38290D) : Colors.amber.shade100.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Qty: $displayQty',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () async {
                          final offerProvider = context.read<OfferProvider>();
                          await cartProvider.unclaimOffer(item.product.id);
                          if (context.mounted) {
                            await cartProvider.fetchCart();
                            await offerProvider.fetchActiveOffers();
                            setState(() {});
                          }
                        },
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.remove_rounded, size: 16, color: AppColors.primary),
                        onPressed: () {
                          if (displayQty > 1) {
                            cartProvider.updateQuantity(item.product.id, item.quantity - 1);
                          } else {
                            if (item.quantity > 1) {
                              cartProvider.updateQuantity(item.product.id, item.quantity - 1);
                            } else {
                              cartProvider.removeFromCart(item.product.id);
                            }
                          }
                        },
                      ),
                      Text(
                        '$displayQty',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                        onPressed: () {
                          cartProvider.updateQuantity(item.product.id, item.quantity + 1);
                        },
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, bool isDark, {Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: textColor ?? (isDark ? AppColors.darkTitle : AppColors.title),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined, size: 72, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Your Cart is Empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTitle : AppColors.title,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore products and add them to your cart to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartDisplayItem {
  final CartItemModel rawItem;
  final bool isRewardCard;
  final int displayQuantity;
  final double displayUnitPrice;
  final String? rewardUnit;

  _CartDisplayItem({
    required this.rawItem,
    required this.isRewardCard,
    required this.displayQuantity,
    required this.displayUnitPrice,
    this.rewardUnit,
  });

  String get displayUnit {
    if (isRewardCard && rewardUnit != null && rewardUnit!.isNotEmpty) {
      return '$displayQuantity $rewardUnit';
    }
    return rawItem.product.formattedUnit;
  }
}
