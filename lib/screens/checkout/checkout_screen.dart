import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../app/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../models/address_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/coupon_provider.dart';
import '../../providers/offer_provider.dart';
import '../../providers/order_provider.dart';
import 'address_form_dialog.dart';

/// Zepto/Blinkit High-Conversion Modern Checkout Screen.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  AddressModel? _selectedAddress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final addressProvider = context.read<AddressProvider>();
      final orderProvider = context.read<OrderProvider>();
      final couponProvider = context.read<CouponProvider>();
      final offerProvider = context.read<OfferProvider>();

      await addressProvider.fetchAddresses();
      await orderProvider.fetchMyOrders();
      await couponProvider.fetchActiveCoupons();
      await offerProvider.fetchActiveOffers();

      if (mounted) {
        setState(() {
          _selectedAddress = addressProvider.defaultAddress ??
              (addressProvider.addresses.isNotEmpty ? addressProvider.addresses.first : null);
        });
      }
    });
  }

  double _calculateDistanceToStore(double? customerLat, double? customerLng) {
    if (customerLat == null || customerLng == null) return 0.0;
    double storeLat = 12.9352;
    double storeLng = 77.6245;
    double distanceMeters = Geolocator.distanceBetween(storeLat, storeLng, customerLat, customerLng);
    return distanceMeters / 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6);
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.border;

    final addressProvider = context.watch<AddressProvider>();
    final cartProvider = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final cart = cartProvider.cart;

    final activeAddress = _selectedAddress ??
        addressProvider.defaultAddress ??
        (addressProvider.addresses.isNotEmpty ? addressProvider.addresses.first : null);

    final activeOrders = orderProvider.orders
        .where((o) => o.status != 'DELIVERED' && o.status != 'CANCELLED')
        .toList();
    final bool hasActiveOrder = activeOrders.isNotEmpty;
    final activeOrder = hasActiveOrder ? activeOrders.first : null;

    final double addressDistanceKm = _calculateDistanceToStore(
      activeAddress?.latitude,
      activeAddress?.longitude,
    );
    const double maxStoreRadiusKm = 5.0; // 5 km Dark Store Delivery Radius
    final bool isOutOfRadius = activeAddress != null &&
        activeAddress.latitude != null &&
        activeAddress.longitude != null &&
        addressDistanceKm > maxStoreRadiusKm;

    final calculatedSubtotal = cartProvider.getCalculatedSubtotal();
    final deliveryCharge = calculatedSubtotal >= 99.0 ? 0.0 : 40.0;
    final discountAmount = cart != null ? cart.discountAmount : 0.0;
    final grandTotal = (calculatedSubtotal + deliveryCharge) - discountAmount;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: AppColors.cardShadow,
        titleSpacing: 16,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkCardBorder : Colors.grey.shade300,
              ),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              color: isDark ? AppColors.darkTitle : AppColors.title,
              size: 24,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Checkout',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTitle : AppColors.title,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 6),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Savings Notification Header Bar
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.stars_rounded, color: Color(0xFF2E7D32), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Yay! You are getting instant savings & priority delivery on this order',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (hasActiveOrder && activeOrder != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Active Order In Progress (#${activeOrder.orderNumber})',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete or cancel your existing order before placing a new order.',
                      style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.orderDetail, arguments: activeOrder.id);
                      },
                      icon: const Icon(Icons.receipt_long_rounded, size: 14),
                      label: const Text('Track Order Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber.shade900,
                        side: BorderSide(color: Colors.amber.shade900),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 1. Delivery Address Card
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
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Delivery Address',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.darkTitle : AppColors.title,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () async {
                          final added = await showDialog<bool>(
                            context: context,
                            builder: (_) => const AddressFormDialog(),
                          );
                          if (added == true && mounted) {
                            await addressProvider.fetchAddresses();
                            setState(() {
                              _selectedAddress = addressProvider.defaultAddress ??
                                  (addressProvider.addresses.isNotEmpty ? addressProvider.addresses.first : null);
                            });
                          }
                        },
                        child: const Text(
                          '+ Add New',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  addressProvider.addresses.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(14),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            'No address saved yet. Tap + Add New to add delivery location.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Address Dropdown Selector
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkBackground : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<AddressModel>(
                                  value: activeAddress,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                                  dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                                  items: addressProvider.addresses.map((addr) {
                                    return DropdownMenuItem<AddressModel>(
                                      value: addr,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.home_outlined, size: 18, color: AppColors.primary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${addr.fullName} (${addr.street}, ${addr.city})',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppColors.darkTitle : AppColors.title,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (addr.isDefault) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'DEFAULT',
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newAddress) async {
                                    if (newAddress != null) {
                                      setState(() => _selectedAddress = newAddress);
                                      if (!newAddress.isDefault) {
                                        await addressProvider.setDefaultAddress(newAddress.id);
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),

                            // Selected Address Detailed Card Preview
                            if (activeAddress != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 1.0),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          activeAddress.fullName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            color: isDark ? AppColors.darkTitle : AppColors.title,
                                          ),
                                        ),
                                        Text(
                                          '+91 ${activeAddress.phone}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.darkTitle : AppColors.title,
                                          ),
                                        ),
                                      ],
                                    ),
                                     const SizedBox(height: 4),
                                     Text(
                                       '${activeAddress.street}, ${activeAddress.city} - ${activeAddress.zipCode}',
                                       style: TextStyle(
                                         fontSize: 12,
                                         color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                                         height: 1.3,
                                       ),
                                     ),
                                     if (activeAddress.latitude != null && activeAddress.longitude != null) ...[
                                       const SizedBox(height: 8),
                                       Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                         decoration: BoxDecoration(
                                           color: isOutOfRadius
                                               ? Colors.red.shade50
                                               : const Color(0xFFF0FDF4),
                                           borderRadius: BorderRadius.circular(8),
                                           border: Border.all(
                                             color: isOutOfRadius
                                                 ? Colors.red.shade300
                                                 : const Color(0xFFBBF7D0),
                                           ),
                                         ),
                                         child: Row(
                                           children: [
                                             Icon(
                                               isOutOfRadius
                                                   ? Icons.highlight_off_rounded
                                                   : Icons.check_circle_rounded,
                                               color: isOutOfRadius
                                                   ? Colors.red.shade700
                                                   : const Color(0xFF15803D),
                                               size: 16,
                                             ),
                                             const SizedBox(width: 6),
                                             Expanded(
                                               child: Text(
                                                 isOutOfRadius
                                                     ? 'Delivery Unavailable: Address is ${addressDistanceKm.toStringAsFixed(1)} km away. We only deliver within ${maxStoreRadiusKm.toStringAsFixed(1)} km from our Dark Store.'
                                                     : 'In Service Area: Address is ${addressDistanceKm.toStringAsFixed(1)} km away (${maxStoreRadiusKm.toStringAsFixed(1)} km Store Radius limit).',
                                                 style: TextStyle(
                                                   fontSize: 11,
                                                   fontWeight: FontWeight.bold,
                                                   color: isOutOfRadius
                                                       ? Colors.red.shade900
                                                       : const Color(0xFF166534),
                                                 ),
                                               ),
                                             ),
                                           ],
                                         ),
                                       ),
                                     ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. Coupons & Offers Highlight Card (Direct Real Backend Data)
            Consumer<CouponProvider>(
              builder: (context, couponProvider, child) {
                final coupons = couponProvider.coupons;
                final bool hasCoupons = coupons.isNotEmpty;
                final firstCoupon = hasCoupons ? coupons.first : null;

                final double minReq = firstCoupon?.minimumOrderAmount ?? 0.0;
                final double remaining = minReq - calculatedSubtotal;
                final bool isUnlocked = remaining <= 0;

                return Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.percent_rounded, color: Color(0xFF2E7D32), size: 20),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            hasCoupons
                                ? '${firstCoupon!.discountText} with ${firstCoupon.code}'
                                : 'Coupons & Offers Available',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTitle : AppColors.title,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          hasCoupons
                              ? (isUnlocked ? 'Unlocked' : 'Locked')
                              : '${coupons.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: hasCoupons
                                ? (isUnlocked ? const Color(0xFF2E7D32) : Colors.grey.shade500)
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        if (hasCoupons) ...[
                          Text(
                            isUnlocked
                                ? 'Eligible for instant discount!'
                                : 'Shop for ₹${remaining.toStringAsFixed(0)} more to apply',
                            style: TextStyle(
                              fontSize: 11,
                              color: isUnlocked ? const Color(0xFF2E7D32) : const Color(0xFFD97706),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Tap to explore active store promo offers',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => Navigator.pushNamed(context, AppRoutes.coupons),
                          child: const Text(
                            'View all coupons >',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // 3. Delivery Speed Banner Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 1.0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.timer_outlined, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivering in 10 mins',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.darkTitle : AppColors.title,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${cart?.items.length ?? 0} item(s) in cart • Priority dispatch',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Delivery is set for immediate express 10-min dispatch'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_month_outlined, size: 14),
                    label: const Text('Schedule'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppColors.darkTitle : AppColors.title,
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 4. Order Items List Card
            if (cart != null && cart.items.isNotEmpty) ...[
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
                      'Cart Items (${cart.items.length})',
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
                      itemCount: cart.items.length,
                      separatorBuilder: (context, index) => Divider(height: 20, color: borderColor),
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        final isRewardProduct = cartProvider.claimedOfferId != null &&
                            cartProvider.offerRewardPrices.containsKey(item.product.id);
                        final rewardPrice = isRewardProduct
                            ? (cartProvider.offerRewardPrices[item.product.id] ?? 0.0)
                            : item.price;
                        final displayUnitPrice = isRewardProduct ? rewardPrice : item.price;
                        final displayItemTotal = displayUnitPrice * item.quantity;

                        return Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkBackground : AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: item.product.primaryImageUrl.isNotEmpty
                                  ? Image.network(
                                      item.product.primaryImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.shopping_bag, size: 22, color: AppColors.primary),
                                    )
                                  : const Icon(Icons.shopping_bag, size: 22, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: isDark ? AppColors.darkTitle : AppColors.title,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.product.formattedUnit} • Qty: ${item.quantity}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              displayItemTotal == 0 ? 'FREE' : Formatters.currency(displayItemTotal),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: isRewardProduct ? Colors.amber.shade900 : AppColors.primary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],


            // 6. Bill Details Summary Card
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
                    'Bill Details',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBillRow('Item Total', Formatters.currency(calculatedSubtotal), isDark),
                  if (discountAmount > 0) ...[
                    const SizedBox(height: 8),
                    _buildBillRow('Coupon Discount', '-${Formatters.currency(discountAmount)}', isDark, textColor: AppColors.success),
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
                              deliveryCharge == 0 ? 'FREE' : 'Min ₹499',
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
                        'Grand Total',
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
          ],
        ),
      ),

      // Fixed Bottom Place Order Action Bar (Zepto Style)
      bottomSheet: Container(
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
                  'VIEW DETAILED BILL',
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
                onPressed: (orderProvider.isLoading || hasActiveOrder || activeAddress == null || isOutOfRadius)
                    ? (isOutOfRadius
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Delivery Unavailable: Address is ${addressDistanceKm.toStringAsFixed(1)} km away. Deliveries are only fulfilled inside our ${maxStoreRadiusKm.toStringAsFixed(1)} km store radius.',
                                ),
                                backgroundColor: Colors.red.shade800,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        : null)
                    : () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.payment,
                          arguments: activeAddress,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOutOfRadius
                      ? Colors.red.shade700
                      : (hasActiveOrder ? Colors.grey.shade400 : AppColors.primary),
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
                        hasActiveOrder
                            ? 'Order In Progress'
                            : (isOutOfRadius ? 'Out of Delivery Radius' : 'Proceed to Pay'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
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
}
