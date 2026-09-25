import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_colors.dart';
import '../models/offer_model.dart';
import '../providers/cart_provider.dart';
import '../providers/offer_provider.dart';
import '../screens/cart/cart_screen.dart';

class GlobalCartBar extends StatelessWidget {
  const GlobalCartBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final offerProvider = context.watch<OfferProvider>();

    final cart = cartProvider.cart;
    final totalItems = cartProvider.itemCount;

    final hasItems = cart != null && cart.items.isNotEmpty && totalItems > 0;
    final firstItem = hasItems ? cart.items.first : null;
    final subtotal = cart?.totalAmount ?? 0.0;
    final activeOffers = offerProvider.offers;

    OfferModel? currentOffer;
    OfferModel? nextOffer;

    for (int i = 0; i < activeOffers.length; i++) {
      final offer = activeOffers[i];
      if (subtotal >= offer.minimumPurchaseAmount) {
        currentOffer = offer;
      } else {
        nextOffer = offer;
        break;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 1. SEPARATE UNLOCK EXTRA OFFER PILL WITH TOP OFFERS BADGE (Dark Pill)
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  GestureDetector(
                    onTap: () {
                      _showOffersBottomSheet(context, activeOffers, subtotal);
                    },
                    child: Material(
                      elevation: 8,
                      shadowColor: Colors.black38,
                      borderRadius: BorderRadius.circular(16),
                      color: isDark ? const Color(0xFF14241D) : const Color(0xFF202A36),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_shipping_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nextOffer != null
                                        ? 'Unlock ${nextOffer.name}'
                                        : (currentOffer != null ? '${currentOffer.name} Applied!' : 'Unlock free delivery'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    nextOffer != null
                                        ? 'Shop for ₹${(nextOffer.minimumPurchaseAmount - subtotal).toInt()}'
                                        : 'Shop for ₹199',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // "Offers ^" Badge attached at top center of pill
                  Positioned(
                    top: -9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE8E8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE53935), width: 0.8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Offers',
                            style: TextStyle(
                              color: Color(0xFFD32F2F),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: Color(0xFFD32F2F),
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // 2. SEPARATE VIBRANT CART BUTTON (Primary Emerald Pill)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
              child: Material(
                elevation: 8,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                color: AppColors.primary,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (firstItem != null && firstItem.product.primaryImageUrl.isNotEmpty)
                        Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              firstItem.product.primaryImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.shopping_bag_outlined,
                                size: 16,
                                color: Color(0xFFE91E63),
                              ),
                            ),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cart',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '$totalItems ${totalItems == 1 ? 'item' : 'items'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOffersBottomSheet(BuildContext context, List<OfferModel> offers, double subtotal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Offers for you',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (offers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No active offers available right now',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: offers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final offer = offers[index];
                      final isUnlocked = subtotal >= offer.minimumPurchaseAmount;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: isUnlocked
                              ? Border.all(color: AppColors.primary, width: 2)
                              : Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isUnlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                              color: isUnlocked ? AppColors.primary : Colors.white54,
                              size: 20,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    offer.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Shop for ₹${offer.minimumPurchaseAmount.toInt()} more',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isUnlocked
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isUnlocked ? 'Unlocked' : 'Locked',
                                style: TextStyle(
                                  color: isUnlocked ? AppColors.primary : Colors.white54,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
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
      },
    );
  }
}
