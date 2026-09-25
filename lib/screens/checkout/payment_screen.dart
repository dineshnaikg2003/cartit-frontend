import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../models/address_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _paymentMethod = 'COD'; // Valid backend enum: COD, UPI, CARD, NET_BANKING, WALLET

  void _onConfirmPayment(AddressModel selectedAddress) async {
    final orderProvider = context.read<OrderProvider>();
    final activeOrders = orderProvider.orders
        .where((o) => o.status != 'DELIVERED' && o.status != 'CANCELLED')
        .toList();

    if (activeOrders.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You already have an active order (#${activeOrders.first.orderNumber}). Please wait until it is completed.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cartProvider = context.read<CartProvider>();

    final order = await orderProvider.placeOrder(
      addressId: selectedAddress.id,
      paymentMethod: _paymentMethod,
    );

    if (!mounted) return;

    if (order != null) {
      await cartProvider.clearCart();
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 54),
              ),
              const SizedBox(height: 16),
              const Text(
                'Order Placed Successfully!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.title),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Order Number: ${order.orderNumber}',
                style: const TextStyle(fontSize: 13, color: AppColors.subtitle, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Total Amount Paid: ${Formatters.currency(order.finalAmount > 0 ? order.finalAmount : order.totalAmount)}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.mainNav,
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage ?? 'Failed to place order'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.border;

    final AddressModel? selectedAddress =
        ModalRoute.of(context)?.settings.arguments as AddressModel?;

    final cartProvider = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final cart = cartProvider.cart;

    final calculatedSubtotal = cartProvider.getCalculatedSubtotal();
    final deliveryCharge = calculatedSubtotal >= 99.0 ? 0.0 : 40.0;
    final discountAmount = cart != null ? cart.discountAmount : 0.0;
    final grandTotal = (calculatedSubtotal + deliveryCharge) - discountAmount;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6),
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
            Text(
              'Select Payment Method',
              style: TextStyle(
                color: isDark ? AppColors.darkTitle : AppColors.title,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Amount to pay: ${Formatters.currency(grandTotal)}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected Delivery Address Summary Header Card
            if (selectedAddress != null) ...[
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 1.0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivering to ${selectedAddress.fullName}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: isDark ? AppColors.darkTitle : AppColors.title,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${selectedAddress.street}, ${selectedAddress.city} • +91 ${selectedAddress.phone}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Payment Offers Card (Status: Not Yet Applicable)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.local_offer_outlined,
                      color: isDark ? AppColors.darkSubtitle : Colors.grey.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Offers',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTitle : AppColors.title,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bank & Wallet offers are not yet applicable',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.amber.withValues(alpha: 0.15) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? Colors.amber.withValues(alpha: 0.3) : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Text(
                      'Not yet applicable',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Payment Methods Selector
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
                    'PAYMENT OPTIONS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: isDark ? AppColors.darkSubtitle : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentRadioTile('COD', 'Cash on Delivery', 'Pay cash upon 10-min delivery', Icons.payments_outlined, isDark),
                  Divider(height: 1, color: borderColor),
                  _buildPaymentRadioTile('UPI', 'UPI / GPay / PhonePe / Paytm', 'Instant 1-tap payment via UPI app', Icons.account_balance_outlined, isDark),
                  Divider(height: 1, color: borderColor),
                  _buildPaymentRadioTile('CARD', 'Credit / Debit Card', 'Visa, MasterCard, RuPay, Maestro', Icons.credit_card_outlined, isDark),
                  Divider(height: 1, color: borderColor),
                  _buildPaymentRadioTile('NET_BANKING', 'Net Banking', 'All major Indian Banks supported', Icons.account_balance_rounded, isDark),
                  Divider(height: 1, color: borderColor),
                  _buildPaymentRadioTile('WALLET', 'Digital Wallets', 'Amazon Pay, Paytm Wallet, Mobikwik', Icons.account_balance_wallet_outlined, isDark),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Order Price Summary Breakdown
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
                    'PRICE SUMMARY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: isDark ? AppColors.darkSubtitle : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBillRow('Item Subtotal', Formatters.currency(calculatedSubtotal), isDark),
                  if (discountAmount > 0 || (cart?.appliedCouponCode != null && cart!.appliedCouponCode!.isNotEmpty)) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Coupon Savings',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                              ),
                            ),
                            if (cart?.appliedCouponCode != null && cart!.appliedCouponCode!.isNotEmpty) ...[
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
                          '-${Formatters.currency(discountAmount)}',
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
                  _buildBillRow('Delivery Charge', deliveryCharge == 0 ? 'FREE' : Formatters.currency(deliveryCharge), isDark),
                  Divider(height: 20, color: borderColor),
                  _buildBillRow('Total Payable Amount', Formatters.currency(grandTotal), isDark, isBold: true),
                ],
              ),
            ),
          ],
        ),
      ),

      // Fixed Bottom Confirm & Pay Action Button Bar
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
                Text(
                  _paymentMethod == 'COD' ? 'CASH ON DELIVERY' : 'PAY ONLINE',
                  style: const TextStyle(
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
                onPressed: (orderProvider.isLoading || selectedAddress == null)
                    ? null
                    : () => _onConfirmPayment(selectedAddress),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
                        _paymentMethod == 'COD' ? 'Place Order' : 'Pay ${Formatters.currency(grandTotal)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRadioTile(String value, String title, String subtitle, IconData icon, bool isDark) {
    final isSelected = _paymentMethod == value;

    return InkWell(
      onTap: () => setState(() => _paymentMethod = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSubtitle : AppColors.subtitle),
              size: 20,
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 22, color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSubtitle : AppColors.subtitle)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String value, bool isDark, {Color? textColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: isDark ? AppColors.darkTitle : AppColors.title,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w800,
            color: textColor ?? (isBold ? AppColors.primary : (isDark ? AppColors.darkTitle : AppColors.title)),
          ),
        ),
      ],
    );
  }
}
