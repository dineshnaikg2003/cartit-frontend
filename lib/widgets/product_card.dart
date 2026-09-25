import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_colors.dart';
import '../core/routes/app_routes.dart';
import '../core/utils/formatters.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = context.watch<WishlistProvider>();
    final cartProvider = context.watch<CartProvider>();

    final isWishlisted = wishlistProvider.isProductWishlisted(product.id);
    final cartQuantity = cartProvider.getItemQuantity(product.id);

    final hasDiscount = product.discountPrice != null &&
        product.discountPrice! > 0 &&
        product.discountPrice! < product.price;

    final discountPercent = hasDiscount
        ? (((product.price - product.effectivePrice) / product.price) * 100).round()
        : 0;

    final isOutOfStock = product.stock <= 0;
    final isLowStock = !isOutOfStock && product.stock < 5;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : Colors.grey.shade200;
    final titleColor = isDark ? AppColors.darkTitle : const Color(0xFF1F2937);
    final subtitleColor = isDark ? AppColors.darkSubtitle : Colors.grey.shade600;
    final bottomBoxBg = isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFFF8FAFC);

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. PRODUCT IMAGE & BADGES BLOCK
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.productDetail,
                  arguments: product.id,
                );
              },
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: isDark ? AppColors.darkBackground.withValues(alpha: 0.5) : const Color(0xFFF9FAFB),
                    child: product.primaryImageUrl.isNotEmpty
                        ? Image.network(
                            product.primaryImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 36,
                                color: subtitleColor,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 40,
                              color: subtitleColor,
                            ),
                          ),
                  ),

                  // Discount Tag Badge (Admin Style Red Tag)
                  if (hasDiscount)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '$discountPercent% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                  // Low Stock / Featured Tag Badge
                  if (isLowStock && !hasDiscount)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB45309),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'LIMITED STOCK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),

                  // Wishlist Floating Button (Top Right)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Material(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      elevation: 2,
                      shadowColor: Colors.black38,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () async {
                          await wishlistProvider.toggleWishlist(product);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6.5),
                          child: Icon(
                            isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 16,
                            color: isWishlisted ? AppColors.error : titleColor,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Out of Stock Overlay
                  if (isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.75),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. PRODUCT DETAILS & ACTION BLOCK
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Title
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.productDetail,
                      arguments: product.id,
                    );
                  },
                  child: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 2),

                // Category / Unit subtitle
                Text(
                  product.formattedUnit.isNotEmpty
                      ? product.formattedUnit
                      : (product.unitQuantity != null && product.unit != null
                          ? '${product.unitQuantity} ${product.unit}'
                          : (product.category?.name ?? 'Grocery')),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // 3. ADMIN-STYLE EMBEDDED PRICING & ACTION CONTAINER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: bottomBoxBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkCardBorder : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Price Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                Formatters.currency(product.effectivePrice),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  Formatters.currency(product.price),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: subtitleColor,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Cart Button / Stepper
                      SizedBox(
                        width: double.infinity,
                        height: 34,
                        child: isOutOfStock
                            ? OutlinedButton(
                                onPressed: null,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: isDark ? AppColors.darkCardBorder : Colors.grey.shade300),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  'Out of Stock',
                                  style: TextStyle(fontSize: 11, color: subtitleColor),
                                ),
                              )
                            : cartQuantity > 0
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            if (cartQuantity == 1) {
                                              cartProvider.removeFromCart(product.id);
                                            } else {
                                              cartProvider.updateQuantity(product.id, cartQuantity - 1);
                                            }
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                            child: Icon(Icons.remove_rounded, color: Colors.white, size: 15),
                                          ),
                                        ),
                                        Text(
                                          '$cartQuantity',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            cartProvider.updateQuantity(product.id, cartQuantity + 1);
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                            child: Icon(Icons.add_rounded, color: Colors.white, size: 15),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : OutlinedButton(
                                    onPressed: () async {
                                      await cartProvider.addToCart(
                                        product.id,
                                        product: product,
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_rounded, size: 15),
                                        SizedBox(width: 3),
                                        Text(
                                          'ADD',
                                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
                                        ),
                                      ],
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

