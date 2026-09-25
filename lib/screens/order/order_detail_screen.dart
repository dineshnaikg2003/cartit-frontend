import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)?.settings.arguments as OrderModel?;
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(order.orderNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Order Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.title)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          order.status.replaceAll('_', ' '),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (order.createdAt != null) ...[
                    const SizedBox(height: 8),
                    Text('Placed on: ${Formatters.formatDate(order.createdAt)}', style: const TextStyle(fontSize: 13, color: AppColors.subtitle)),
                  ],
                  if (order.status.toUpperCase() != 'CANCELLED' &&
                      order.status.toUpperCase() != 'CANCELED' &&
                      order.status.toUpperCase() != 'REFUNDED' &&
                      order.status.toUpperCase() != 'DELIVERED') ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.orderTracker, arguments: order);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.two_wheeler_rounded, size: 20),
                        label: const Text(
                          'Track Order Live on Map',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Order Items List
            const Text('Items in this order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.title)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                    ),
                    title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('Qty: ${item.quantity} x ${Formatters.currency(item.price)}'),
                    trailing: Text(
                      Formatters.currency(item.totalPrice),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Shipping Address Card
            if (order.shippingAddress != null) ...[
              const Text('Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.title)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.shippingAddress!.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      '${order.shippingAddress!.street}, ${order.shippingAddress!.city}, ${order.shippingAddress!.state} - ${order.shippingAddress!.zipCode}',
                      style: const TextStyle(fontSize: 13, color: AppColors.subtitle),
                    ),
                    const SizedBox(height: 4),
                    Text('Phone: ${order.shippingAddress!.phone}', style: const TextStyle(fontSize: 13, color: AppColors.subtitle)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Price Details Summary
            const Text('Payment Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.title)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Items Total', style: TextStyle(color: AppColors.subtitle)),
                      Text(Formatters.currency(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (order.discountAmount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount Applied', style: TextStyle(color: AppColors.success)),
                        Text('-${Formatters.currency(order.discountAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery Fee', style: TextStyle(color: AppColors.subtitle)),
                      Text(
                        order.deliveryCharge > 0 ? Formatters.currency(order.deliveryCharge) : 'FREE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: order.deliveryCharge > 0 ? AppColors.title : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        Formatters.currency(order.finalAmount > 0 ? order.finalAmount : order.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Cancel Order Option
            if (order.status.toUpperCase() == 'PENDING' || order.status.toUpperCase() == 'CONFIRMED')
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cancel Order?'),
                        content: const Text('Are you sure you want to cancel this order?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.error))),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      final success = await context.read<OrderProvider>().cancelOrder(order.id);
                      if (!context.mounted) return;
                      if (success) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order cancelled successfully'), backgroundColor: AppColors.info),
                        );
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel Order', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
