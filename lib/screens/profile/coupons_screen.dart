import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/cart_provider.dart';
import '../../providers/coupon_provider.dart';
import '../../providers/offer_provider.dart';
import '../../widgets/modern_loaders.dart';

/// Zepto/Blinkit Premium E-Commerce "Coupon & Offers" Screen.
class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeController = TextEditingController();
  String _selectedPaymentCategory = 'All';

  // Sample Payment Offers matching reference layout
  final List<Map<String, dynamic>> _paymentOffers = [
    {
      'id': 'p1',
      'code': 'AMZPAY50',
      'title': 'Get Upto ₹50 Cashback on using Amazon Pay',
      'minAmount': 499.0,
      'category': 'Wallet',
      'icon': Icons.account_balance_wallet_rounded,
      'iconBg': const Color(0xFF232F3E),
      'iconColor': const Color(0xFFFF9900),
      'terms': '• Valid when paid via Amazon Pay balance or UPI\n• Cashback credited within 24 hrs',
    },
    {
      'id': 'p2',
      'code': 'UPIAMZ',
      'title': 'Get upto ₹25 Cashback with Amazon Pay UPI',
      'minAmount': 299.0,
      'category': 'UPI',
      'icon': Icons.account_balance_rounded,
      'iconBg': const Color(0xFF008296),
      'iconColor': Colors.white,
      'terms': '• Valid on first Amazon Pay UPI transaction of the month',
    },
    {
      'id': 'p3',
      'code': 'ZEPHSBC',
      'title': 'Flat ₹100 off with HSBC Bank Credit Cards',
      'minAmount': 999.0,
      'category': 'Card',
      'icon': Icons.credit_card_rounded,
      'iconBg': const Color(0xFFDB0011),
      'iconColor': Colors.white,
      'terms': '• Valid on HSBC Credit Cards only\n• Minimum transaction ₹999',
    },
    {
      'id': 'p4',
      'code': 'ZEPRBLCC',
      'title': 'Flat ₹100 off with RBL Bank Credit cards',
      'minAmount': 999.0,
      'category': 'Card',
      'icon': Icons.credit_card_rounded,
      'iconBg': const Color(0xFF003B70),
      'iconColor': Colors.white,
      'terms': '• Valid on RBL Bank Credit Cards once a month',
    },
    {
      'id': 'p5',
      'code': 'PAYLATER20',
      'title': 'Get ₹50 Cashback via LazyPay PayLater',
      'minAmount': 399.0,
      'category': 'PayLater',
      'icon': Icons.schedule_send_rounded,
      'iconBg': const Color(0xFFE53935),
      'iconColor': Colors.white,
      'terms': '• Applicable on LazyPay PayLater checkouts',
    },
  ];

  final Map<String, bool> _expandedTerms = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfferProvider>().fetchActiveOffers();
      context.read<CouponProvider>().fetchActiveCoupons();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _showHaveACodeDialog(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Have a promo code?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkCardBorder : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'ENTER CODE HERE',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final code = _codeController.text.trim();
                        if (code.isNotEmpty) {
                          Navigator.pop(ctx);
                          _applyCouponCode(code, 50.0);
                        }
                      },
                      child: const Text(
                        'APPLY',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _applyCouponCode(String code, double discount) async {
    final cartProvider = context.read<CartProvider>();
    final couponProvider = context.read<CouponProvider>();
    final subtotal = cartProvider.getCalculatedSubtotal();

    final validation = await couponProvider.validateCoupon(code, subtotal);

    if (!mounted) return;

    if (validation['valid'] == true) {
      final savedAmt = (validation['discount'] as num?)?.toDouble() ?? discount;
      final success = await cartProvider.applyCoupon(code, discountAmount: savedAmt);
      if (!mounted) return;

      if (success) {
        final savedAmt = (validation['discount'] as num?)?.toDouble() ?? 0.0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    savedAmt > 0
                        ? 'Coupon "$code" applied successfully! Saved ${Formatters.currency(savedAmt)}'
                        : 'Coupon "$code" applied successfully!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Auto-redirect back to Cart Screen
        Navigator.pop(context);
        return;
      }
    }

    final msg = validation['message'] ?? 'Failed to apply coupon "$code". Please check minimum order amount.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6);
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
        title: Text(
          'Coupon & Offers',
          style: TextStyle(
            color: isDark ? AppColors.darkTitle : AppColors.title,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: OutlinedButton(
              onPressed: () => _showHaveACodeDialog(context, isDark),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.darkTitle : AppColors.title,
                side: BorderSide(
                  color: isDark ? AppColors.darkCardBorder : Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Have a code?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Segmented Tab Switcher
          Container(
            color: cardBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : const Color(0xFFEAECEF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: isDark ? AppColors.darkTitle : AppColors.title,
                    unselectedLabelColor:
                        isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Coupons'),
                      Tab(text: 'Payment Offers'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Note: You can now apply coupons and payment offers together.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkSubtitle : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCouponsTab(isDark, cardBg),
                _buildPaymentOffersTab(isDark, cardBg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Coupons Tab View - Render Exclusively Live Backend Admin Coupons
  Widget _buildCouponsTab(bool isDark, Color cardBg) {
    final cartProvider = context.watch<CartProvider>();
    final currentSubtotal = cartProvider.getCalculatedSubtotal();
    final couponProvider = context.watch<CouponProvider>();

    if (couponProvider.isLoading) {
      return ModernLoaders.listCardSkeleton(context, count: 4);
    }

    final backendCoupons = couponProvider.coupons;

    if (backendCoupons.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => couponProvider.fetchActiveCoupons(),
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 1.0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.confirmation_number_outlined,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Active Coupons Available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Check back later or enter a promo code above.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => couponProvider.fetchActiveCoupons(),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'STORE COUPONS (${backendCoupons.length})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: isDark ? AppColors.darkSubtitle : Colors.grey.shade600,
              ),
            ),
          ),
          ...backendCoupons.map((coupon) {
            final double remaining = coupon.minimumOrderAmount - currentSubtotal;
            final bool isUnlocked = remaining <= 0;

            final Map<String, dynamic> couponMap = {
              'id': coupon.id.toString(),
              'code': coupon.code,
              'title': coupon.title,
              'minAmount': coupon.minimumOrderAmount,
              'discount': coupon.discountValue,
              'description': coupon.description ?? 'Valid on store grocery orders above ₹${coupon.minimumOrderAmount.toStringAsFixed(0)}',
              'terms': '• Minimum cart value ₹${coupon.minimumOrderAmount.toStringAsFixed(0)}\n• Expiry Date: ${coupon.expiryText}',
            };

            return _buildCouponCard(
              context: context,
              coupon: couponMap,
              isUnlocked: isUnlocked,
              remainingAmount: remaining > 0 ? remaining : 0,
              isDark: isDark,
              cardBg: cardBg,
            );
          }),
        ],
      ),
    );
  }

  /// Payment Offers & Backend Store Offers Tab
  Widget _buildPaymentOffersTab(bool isDark, Color cardBg) {
    final cartProvider = context.watch<CartProvider>();
    final currentSubtotal = cartProvider.getCalculatedSubtotal();
    final offerProvider = context.watch<OfferProvider>();

    final categories = ['All', 'Store Offers', 'UPI', 'Card', 'Wallet', 'PayLater'];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Category Filter Pills Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedPaymentCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 14),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cat == 'Store Offers') const Icon(Icons.card_giftcard_rounded, size: 14),
                      if (cat == 'UPI') const Icon(Icons.flash_on_rounded, size: 14),
                      if (cat == 'Card') const Icon(Icons.credit_card_rounded, size: 14),
                      if (cat == 'Wallet') const Icon(Icons.account_balance_wallet_rounded, size: 14),
                      if (cat == 'PayLater') const Icon(Icons.schedule_rounded, size: 14),
                      if (cat != 'All') const SizedBox(width: 4),
                      Text(cat),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedPaymentCategory = cat);
                  },
                  selectedColor: isDark ? AppColors.darkSurface : Colors.white,
                  backgroundColor: isDark ? AppColors.darkSurface.withValues(alpha: 0.5) : Colors.white,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? (isDark ? AppColors.darkTitle : AppColors.title)
                        : (isDark ? AppColors.darkSubtitle : Colors.grey.shade600),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? (isDark ? AppColors.darkTitle : Colors.black)
                          : (isDark ? AppColors.darkCardBorder : Colors.grey.shade300),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  elevation: isSelected ? 1 : 0,
                ),
              );
            }).toList(),
          ),
        ),

        // 1. Backend Active Store Offers Section
        if (_selectedPaymentCategory == 'All' || _selectedPaymentCategory == 'Store Offers') ...[
          if (offerProvider.isLoading)
            ModernLoaders.listCardSkeleton(context, count: 2)
          else if (offerProvider.offers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'LIVE STORE OFFERS (${offerProvider.offers.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  color: isDark ? AppColors.darkSubtitle : Colors.grey.shade600,
                ),
              ),
            ),
            ...offerProvider.offers.map((offer) {
              final double remaining = offer.minimumPurchaseAmount - currentSubtotal;
              final bool isUnlocked = remaining <= 0;

              return _buildBackendOfferCard(
                context: context,
                offer: offer,
                isUnlocked: isUnlocked,
                remainingAmount: remaining > 0 ? remaining : 0,
                isDark: isDark,
                cardBg: cardBg,
              );
            }),
            const SizedBox(height: 10),
          ],
        ],

        // 2. Bank & Wallet Offers Section (Not Yet Applicable)
        if (_selectedPaymentCategory != 'Store Offers') ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: Text(
              'BANK & WALLET OFFERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: isDark ? AppColors.darkSubtitle : Colors.grey.shade600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(top: 4, bottom: 20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkCardBorder : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.amber.withValues(alpha: 0.15) : const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.amber.withValues(alpha: 0.3) : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Icon(
                    Icons.local_offer_outlined,
                    size: 28,
                    color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Payment Offers Not Yet Applicable',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTitle : AppColors.title,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bank & wallet payment offers are not yet applicable. Please check store coupons for available order discounts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Coupon Card Widget matching reference layout
  Widget _buildCouponCard({
    required BuildContext context,
    required Map<String, dynamic> coupon,
    required bool isUnlocked,
    required double remainingAmount,
    required bool isDark,
    required Color cardBg,
  }) {
    final String id = coupon['id'];
    final bool isExpanded = _expandedTerms[id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Green Percent Icon Container
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.percent_rounded,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Unlock Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon['title'],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isUnlocked)
                        const Text(
                          'Unlocked! Eligible on current cart amount',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        )
                      else
                        Text(
                          'Shop for ₹${remainingAmount.toStringAsFixed(0)} more to unlock',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD97706), // Warm Amber color
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Action Button: Apply vs Locked
                if (isUnlocked)
                  ElevatedButton(
                    onPressed: () {
                      _applyCouponCode(coupon['code'], coupon['discount']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  )
                else
                  OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? AppColors.darkCardBorder : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Locked',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkSubtitle : Colors.grey.shade500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Dashed Perforated Separator Line
          CustomPaint(
            size: const Size(double.infinity, 1),
            painter: _DashedLinePainter(
              color: isDark ? AppColors.darkCardBorder : Colors.grey.shade200,
            ),
          ),

          // Code Box & Know More Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? AppColors.darkCardBorder : Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Text(
                    coupon['code'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkSubtitle : Colors.grey.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandedTerms[id] = !isExpanded;
                    });
                  },
                  child: Row(
                    children: [
                      Text(
                        'Know more',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkSubtitle : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: isDark ? AppColors.darkSubtitle : Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Collapsible Terms Details
          if (isExpanded) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : const Color(0xFFFAFAFA),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coupon['description'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    coupon['terms'],
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Payment Offer Card Widget matching reference layout
  Widget _buildPaymentOfferCard({
    required BuildContext context,
    required Map<String, dynamic> offer,
    required bool isUnlocked,
    required double remainingAmount,
    required bool isDark,
    required Color cardBg,
  }) {
    final String id = offer['id'];
    final bool isExpanded = _expandedTerms[id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Minimal Ticket Code Tag Icon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    offer['code'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Unlock Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer['title'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isUnlocked)
                        const Text(
                          'Unlocked • Save on this order',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32),
                          ),
                        )
                      else
                        Text(
                          'Add ${Formatters.currency(remainingAmount)} more',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD97706),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Action Button
                Builder(
                  builder: (context) {
                    final cartProvider = context.watch<CartProvider>();
                    final isApplied = cartProvider.cart?.appliedCouponCode == offer['code'];

                    if (isApplied) {
                      return TextButton.icon(
                        onPressed: () async {
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
                        icon: const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                        label: const Text(
                          'APPLIED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppColors.success,
                          ),
                        ),
                      );
                    }

                    if (isUnlocked) {
                      return ElevatedButton(
                        onPressed: () {
                          _applyCouponCode(offer['code'], 50.0);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'APPLY',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      );
                    }

                    return Text(
                      'LOCKED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkSubtitle : Colors.grey.shade400,
                        letterSpacing: 0.5,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Dashed Separator Line
          CustomPaint(
            size: const Size(double.infinity, 1),
            painter: _DashedLinePainter(
              color: isDark ? AppColors.darkCardBorder : Colors.grey.shade200,
            ),
          ),

          // Code Box & Know More Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? AppColors.darkCardBorder : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    offer['code'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkSubtitle : Colors.grey.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandedTerms[id] = !isExpanded;
                    });
                  },
                  child: Row(
                    children: [
                      Text(
                        'Know more',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkSubtitle : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: isDark ? AppColors.darkSubtitle : Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Collapsible Terms Details
          if (isExpanded) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : const Color(0xFFFAFAFA),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Text(
                offer['terms'],
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Backend Offer Card Widget for active store offers
  Widget _buildBackendOfferCard({
    required BuildContext context,
    required dynamic offer,
    required bool isUnlocked,
    required double remainingAmount,
    required bool isDark,
    required Color cardBg,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 1.0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: offer.rewardProductImageUrlFormatted.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        offer.rewardProductImageUrlFormatted,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.card_giftcard_rounded, color: AppColors.primary, size: 24),
                      ),
                    )
                  : const Icon(Icons.card_giftcard_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.rewardText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isUnlocked)
                    const Text(
                      'Unlocked! Automatic reward on checkout',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    )
                  else
                    Text(
                      'Shop for ₹${remainingAmount.toStringAsFixed(0)} more to unlock',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD97706),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isUnlocked)
              ElevatedButton(
                onPressed: () {
                  _applyCouponCode(offer.name, offer.rewardPrice);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              )
            else
              OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? AppColors.darkCardBorder : Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Locked', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkSubtitle : Colors.grey.shade500)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dashed Separator Line Painter
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
