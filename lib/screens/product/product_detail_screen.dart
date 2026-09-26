import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../cart/cart_screen.dart';
import '../../widgets/product_image_viewer.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedImageIndex = 0;
  final PageController _pageController = PageController();

  ProductModel? _product;
  bool _initialised = false;

  void _openImageViewer(List<ProductImageModel> gallery, int initialIndex) {
    final urls = gallery.map((img) => img.imageUrl).where((url) => url.isNotEmpty).toList();
    if (urls.isEmpty && _product?.primaryImageUrl != null && _product!.primaryImageUrl.isNotEmpty) {
      urls.add(_product!.primaryImageUrl);
    }
    if (urls.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductImageViewer(
          imageUrls: urls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ProductModel) {
      _product = args;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFullProduct(args.id);
      });
    } else if (args is int) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFullProduct(args);
      });
    }
  }

  Future<void> _loadFullProduct(int productId) async {
    final provider = context.read<ProductProvider>();
    final fullProduct = await provider.fetchProductById(productId);
    if (!mounted || fullProduct == null) return;

    setState(() {
      _product = fullProduct;
      _selectedImageIndex = 0;
      _quantity = 1;
    });
  }

  List<ProductImageModel> _getGalleryImages(ProductModel product) {
    if (product.images.isNotEmpty) return product.images;
    if (product.primaryImageUrl.isNotEmpty) {
      return [ProductImageModel(id: 0, imageUrl: product.primaryImageUrl, primary: true)];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppColors.darkSurface : Colors.white;
    final scaffoldBg = isDark ? AppColors.darkBackground : const Color(0xFFF7F8FA);

    final productProvider = context.watch<ProductProvider>();
    final cartProvider = context.watch<CartProvider>();
    final wishlistProvider = context.watch<WishlistProvider>();

    if (product == null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: cardBgColor,
          elevation: 0.5,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? AppColors.darkTitle : AppColors.title,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Product Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTitle : const Color(0xFF1F2937),
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (productProvider.isDetailLoading) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 1.0),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Fetching product details...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                    ),
                  ),
                ] else ...[
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_off_rounded,
                      size: 40,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    productProvider.errorMessage ?? ProductProvider.defaultErrorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () {
                      final args = ModalRoute.of(context)?.settings.arguments;
                      if (args is int) {
                        _loadFullProduct(args);
                      } else if (args is ProductModel) {
                        _loadFullProduct(args.id);
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: const Text(
                      'Retry',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final gallery = _getGalleryImages(product);
    final isWishlisted = wishlistProvider.isProductWishlisted(product.id);

    final hasDiscount = product.discountPrice != null &&
        product.discountPrice! > 0 &&
        product.discountPrice! < product.price;

    final discountPercent = hasDiscount
        ? (((product.price - product.effectivePrice) / product.price) * 100).round()
        : 0;

    final savingsAmount = hasDiscount ? (product.price - product.effectivePrice) : 0.0;
    final isOutOfStock = product.stock <= 0;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: cardBgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.darkTitle : const Color(0xFF1F2937),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Product Details",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTitle : const Color(0xFF1F2937),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? AppColors.darkCardBorder : Colors.grey.shade200,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: isDark ? AppColors.darkTitle : const Color(0xFF1F2937),
              size: 22,
            ),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.productList);
            },
          ),
          IconButton(
            icon: Icon(
              isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isWishlisted ? AppColors.error : (isDark ? AppColors.darkTitle : const Color(0xFF1F2937)),
              size: 22,
            ),
            onPressed: () async {
              await wishlistProvider.toggleWishlist(product);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                final refreshed = await context.read<ProductProvider>().fetchProductById(product.id);
                if (!mounted || refreshed == null) return;
                setState(() {
                  _product = refreshed;
                  _selectedImageIndex = 0;
                });
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. PRODUCT HEADER CARD (Image Gallery + Name + Badges)
                    _buildHeaderCard(product, gallery, hasDiscount, discountPercent, isWishlisted, wishlistProvider, isDark),

                    const SizedBox(height: 14),

                    // 2. PRODUCT INFO CARD (Category, Brand, Unit, Unit Quantity)
                    _buildProductInfoCard(product, isDark),

                    const SizedBox(height: 14),

                    // 3. PRODUCT PRICING CARD (Price, Discount, Effective Price, Savings)
                    _buildProductPricingCard(product, hasDiscount, discountPercent, savingsAmount, isDark),

                    if (product.description != null && product.description!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      // 5. PRODUCT DESCRIPTION CARD
                      _buildProductDescriptionCard(product.description!, isDark),
                    ],

                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),

          // STICKY BOTTOM ACTION BAR (Add to Cart / Stepper)
          _buildBottomBar(product, cartProvider, productProvider, isOutOfStock, isDark),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. PRODUCT HEADER CARD (ADMIN STYLE)
  // ---------------------------------------------------------------------------
  Widget _buildHeaderCard(
    ProductModel product,
    List<ProductImageModel> gallery,
    bool hasDiscount,
    int discountPercent,
    bool isWishlisted,
    WishlistProvider wishlistProvider,
    bool isDark,
  ) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : Colors.grey.shade200;
    final titleColor = isDark ? AppColors.darkTitle : const Color(0xFF1F2937);
    final subtitleColor = isDark ? AppColors.darkSubtitle : Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Image Gallery Card
        Container(
          width: double.infinity,
          height: 330,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: gallery.isEmpty ? 1 : gallery.length,
                  onPageChanged: (index) => setState(() => _selectedImageIndex = index),
                  itemBuilder: (context, index) {
                    if (gallery.isEmpty) {
                      return Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: subtitleColor,
                        ),
                      );
                    }
                    return GestureDetector(
                      onTap: () => _openImageViewer(gallery, index),
                      child: Image.network(
                        gallery[index].imageUrl,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: subtitleColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Image Counter Badge (Top Right - Admin Style)
              if (gallery.length > 1)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${_selectedImageIndex + 1}/${gallery.length}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Discount Tag Pill (Top Left)
              if (hasDiscount)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$discountPercent% OFF",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Animated Page Indicator Dots (Admin Style)
        if (gallery.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(gallery.length, (index) {
              final selected = index == _selectedImageIndex;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: selected ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),

        // Thumbnail Strip (Admin Style)
        if (gallery.length > 1) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(gallery.length, (index) {
                final isSelected = _selectedImageIndex == index;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 64,
                    height: 64,
                    margin: const EdgeInsets.only(right: 8),
                    padding: EdgeInsets.all(isSelected ? 2 : 1),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        gallery[index].imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade100,
                          child: const Icon(
                            Icons.image_outlined,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Product Name & Quick Tags
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fast 6 min delivery badge + stock badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF33200A) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFD97706)),
                        const SizedBox(width: 4),
                        Text(
                          "6 mins delivery",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.stock > 0
                          ? (isDark ? const Color(0xFF0F261B) : const Color(0xFFDCFCE7))
                          : (isDark ? const Color(0xFF3B1212) : const Color(0xFFFEE2E2)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.stock > 0
                          ? (product.stock < 5 ? "Only ${product.stock} left!" : "In Stock")
                          : "Out of Stock",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: product.stock > 0
                            ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                            : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                product.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. PRODUCT INFO CARD (ADMIN STYLE 2-COLUMN GRID)
  // ---------------------------------------------------------------------------
  Widget _buildProductInfoCard(ProductModel product, bool isDark) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : Colors.grey.shade200;
    final titleColor = isDark ? AppColors.darkTitle : const Color(0xFF1F2937);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                "Product Information",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 14),

          _infoRow(
            label1: "Category",
            value1: product.category?.name ?? "General",
            label2: "Brand",
            value2: product.brand?.name ?? "Standard",
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          _infoRow(
            label1: "Unit",
            value1: product.unit ?? "Pack",
            label2: "Unit Quantity",
            value2: product.formattedUnit.isNotEmpty
                ? product.formattedUnit
                : (product.unitQuantity != null ? "${product.unitQuantity} ${product.unit ?? ''}" : "1"),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required String label1,
    required String value1,
    required String label2,
    required String value2,
    required bool isDark,
  }) {
    return Row(
      children: [
        Expanded(child: _infoCell(label1, value1, isDark)),
        const SizedBox(width: 12),
        Expanded(child: _infoCell(label2, value2, isDark)),
      ],
    );
  }

  Widget _infoCell(String label, String value, bool isDark) {
    final titleColor = isDark ? AppColors.darkTitle : const Color(0xFF1F2937);
    final subtitleColor = isDark ? AppColors.darkSubtitle : Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: subtitleColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. PRODUCT PRICING CARD (ADMIN PRICING BREAKDOWN)
  // ---------------------------------------------------------------------------
  Widget _buildProductPricingCard(
    ProductModel product,
    bool hasDiscount,
    int discountPercent,
    double savingsAmount,
    bool isDark,
  ) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : Colors.grey.shade200;
    final titleColor = isDark ? AppColors.darkTitle : const Color(0xFF1F2937);
    final subtitleColor = isDark ? AppColors.darkSubtitle : Colors.grey.shade600;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                "Pricing & Discount",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _pricingCell("Effective Price", Formatters.currency(product.effectivePrice), AppColors.primary, isDark),
              ),
              if (hasDiscount) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _pricingCell("Original MRP", Formatters.currency(product.price), subtitleColor, isDark, isCrossedOut: true),
                ),
              ],
            ],
          ),

          if (hasDiscount) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F261B) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF1F382B) : const Color(0xFFA7F3D0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    "You save ${Formatters.currency(savingsAmount)} ($discountPercent% off)",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
          Text(
            "MRP (inclusive of all taxes)",
            style: TextStyle(
              fontSize: 11,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pricingCell(String label, String value, Color valueColor, bool isDark, {bool isCrossedOut = false}) {
    final subtitleColor = isDark ? AppColors.darkSubtitle : Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: subtitleColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: valueColor,
            decoration: isCrossedOut ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }



  // ---------------------------------------------------------------------------
  // 5. PRODUCT DESCRIPTION CARD (ADMIN DESCRIPTION BREAKDOWN)
  // ---------------------------------------------------------------------------
  Widget _buildProductDescriptionCard(String description, bool isDark) {
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : Colors.grey.shade200;
    final titleColor = isDark ? AppColors.darkTitle : const Color(0xFF1F2937);
    final subtitleColor = isDark ? AppColors.darkSubtitle : Colors.grey.shade600;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                "Description",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 14),

          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STICKY BOTTOM ACTION BAR (Add to Cart / Stepper)
  // ---------------------------------------------------------------------------
  Widget _buildBottomBar(
    ProductModel product,
    CartProvider cartProvider,
    ProductProvider productProvider,
    bool isOutOfStock,
    bool isDark,
  ) {
    final cartQty = cartProvider.getItemQuantity(product.id);
    final totalCartItems = cartProvider.itemCount;

    final barBgColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : Colors.grey.shade200;
    final titleColor = isDark ? AppColors.darkTitle : const Color(0xFF1F2937);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: barBgColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: cartQty == 0
            ? SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isOutOfStock || productProvider.isDetailLoading || cartProvider.isLoading
                      ? null
                      : () async {
                          await cartProvider.addToCart(
                            product.id,
                            quantity: 1,
                            product: product,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark ? AppColors.darkHeaderBg : Colors.grey.shade300,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isOutOfStock ? 'Out of Stock' : 'Add to Cart',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Row(
                children: [
                  // View Cart Button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CartScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderColor, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  color: titleColor,
                                  size: 20,
                                ),
                                if (totalCartItems > 0)
                                  Positioned(
                                    top: -5,
                                    right: -7,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$totalCartItems',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'View Cart',
                              style: TextStyle(
                                color: titleColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Quantity Stepper
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            InkWell(
                              onTap: () async {
                                if (cartQty > 1) {
                                  await cartProvider.updateQuantity(product.id, cartQty - 1);
                                } else if (cartQty == 1) {
                                  await cartProvider.removeFromCart(product.id);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(Icons.remove_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                            Text(
                              '$cartQty',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                final maxQty = product.maxPurchaseQuantity ?? 99;
                                if (cartQty < maxQty && cartQty < product.stock) {
                                  await cartProvider.updateQuantity(product.id, cartQty + 1);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(Icons.add_rounded, color: Colors.white, size: 18),
                              ),
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
}