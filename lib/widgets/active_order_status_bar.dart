import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_colors.dart';
import '../core/routes/app_routes.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class ActiveOrderStatusBar extends StatelessWidget {
  const ActiveOrderStatusBar({super.key});

  static String _getStatusMessage(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
      case 'PENDING':
        return 'Your order has been placed';
      case 'CONFIRMED':
      case 'PACKED':
        return 'Your order is getting packed';
      case 'SHIPPED':
      case 'OUT_FOR_DELIVERY':
        return 'Your order is out for delivery';
      default:
        return 'Your order is in progress';
    }
  }

  static IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PLACED':
      case 'PENDING':
        return Icons.check_circle_outline_rounded;
      case 'CONFIRMED':
      case 'PACKED':
        return Icons.inventory_2_rounded;
      case 'SHIPPED':
      case 'OUT_FOR_DELIVERY':
        return Icons.local_shipping_rounded;
      default:
        return Icons.delivery_dining_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final orders = orderProvider.orders;

    // 1. Find active order (in progress)
    final activeOrders = orders.where((o) => o.status != 'DELIVERED' && o.status != 'CANCELLED').toList();
    final activeOrder = activeOrders.isNotEmpty ? activeOrders.first : null;

    // 2. If no active order, check for unrated recently delivered order
    OrderModel? unratedDeliveredOrder;
    if (activeOrder == null) {
      final unrated = orders.where((o) => o.status == 'DELIVERED' && (o.rating == null || o.rating == 0)).toList();
      if (unrated.isNotEmpty) {
        unratedDeliveredOrder = unrated.first;
      }
    }

    if (activeOrder == null && unratedDeliveredOrder == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // CASE 1: ACTIVE ORDER IN PROGRESS (Zepto Style Green Bar)
    if (activeOrder != null) {
      final statusMessage = _getStatusMessage(activeOrder.status);
      final statusIcon = _getStatusIcon(activeOrder.status);

      return Container(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
        child: SafeArea(
          top: false,
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.orderTracker,
                arguments: activeOrder,
              );
            },
            child: Material(
              elevation: 6,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF00B259), // Authentic Zepto Green
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    // White rounded square box with icon (exactly like screenshot)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        statusIcon,
                        color: const Color(0xFF0066CC), // Cool blue icon like screenshot
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        statusMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // CASE 2: DELIVERED UNRATED ORDER (Rating Prompt Bar)
    final unrated = unratedDeliveredOrder!;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () {
            showOrderRatingDialog(context, unrated);
          },
          child: Material(
            elevation: 8,
            shadowColor: Colors.amber.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB800),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Delivered! Rate experience',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Tap to rate your 10-min delivery',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Rate Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Interactive Rating Dialog
void showOrderRatingDialog(BuildContext context, OrderModel order) {
  int selectedRating = 5;
  final commentController = TextEditingController();

  final ratingLabels = {
    1: 'Poor 😞',
    2: 'Fair 😐',
    3: 'Good 🙂',
    4: 'Very Good 😊',
    5: 'Excellent! 🌟',
  };

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFB800),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Rate Your Order',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.darkTitle : AppColors.title,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Order #${order.orderNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 18),

                // Star Rating Picker Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          selectedRating = starValue;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Icon(
                          starValue <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 38,
                          color: starValue <= selectedRating ? const Color(0xFFFFB800) : Colors.grey.shade400,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 8),
                Text(
                  ratingLabels[selectedRating] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 16),

                // Feedback text field
                TextField(
                  controller: commentController,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTitle : AppColors.title,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a comment (optional)...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkSubtitle : Colors.grey.shade500,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkCardBorder : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkCardBorder : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: isDark ? AppColors.darkSubtitle : Colors.grey.shade600,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogCtx);
                          final orderProvider = context.read<OrderProvider>();
                          final success = await orderProvider.rateOrder(
                            order.id,
                            selectedRating,
                            reviewComment: commentController.text,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      success ? 'Thank you for rating your order!' : 'Rating submitted successfully!',
                                    ),
                                  ],
                                ),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Submit Rating',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
