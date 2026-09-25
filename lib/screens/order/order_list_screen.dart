import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../providers/order_provider.dart';

import '../../widgets/modern_loaders.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchMyOrders();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.error;
      case 'OUT_FOR_DELIVERY':
      case 'SHIPPED':
        return AppColors.info;
      case 'PACKED':
      case 'CONFIRMED':
        return AppColors.secondary;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final orders = orderProvider.orders;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.border.withValues(alpha: 0.7);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cardBgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: AppColors.cardShadow,
        titleSpacing: 16,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.darkTitle : AppColors.title,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Orders',
              style: TextStyle(
                color: isDark ? AppColors.darkTitle : AppColors.title,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Purchase history & live updates',
              style: TextStyle(
                color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: orderProvider.isLoading
          ? ModernLoaders.listCardSkeleton(context)
          : orders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => orderProvider.fetchMyOrders(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                    itemCount: orders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final statusColor = _getStatusColor(order.status);
                      final isCompletedOrCancelled = order.status.toUpperCase() == 'DELIVERED' ||
                          order.status.toUpperCase() == 'CANCELLED' ||
                          order.status.toUpperCase() == 'CANCELED' ||
                          order.status.toUpperCase() == 'REFUNDED';

                      return Container(
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cardShadow.withValues(alpha: isDark ? 0.2 : 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.orderDetail, arguments: order);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.receipt_rounded, size: 18, color: AppColors.primary),
                                          const SizedBox(width: 6),
                                          Text(
                                            order.orderNumber,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 15,
                                              color: isDark ? AppColors.darkTitle : AppColors.title,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          order.status.replaceAll('_', ' '),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: statusColor,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'} in this order',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppColors.darkTitle : AppColors.title,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (order.createdAt != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Ordered on: ${Formatters.formatDate(order.createdAt)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Divider(height: 1, color: isDark ? AppColors.darkCardBorder : AppColors.border.withValues(alpha: 0.6)),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'TOTAL AMOUNT',
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.subtitle, letterSpacing: 0.5),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            Formatters.currency(order.finalAmount > 0 ? order.finalAmount : order.totalAmount),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!isCompletedOrCancelled)
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.pushNamed(context, AppRoutes.orderTracker, arguments: order);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          icon: const Icon(Icons.two_wheeler_rounded, size: 16),
                                          label: const Text(
                                            'Track Live',
                                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                                          ),
                                        )
                                      else
                                        const Row(
                                          children: [
                                            Text(
                                              'View Details',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.title),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.title),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Orders Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When you place orders, they will show up here for live tracking.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.subtitle),
            ),
          ],
        ),
      ),
    );
  }
}
