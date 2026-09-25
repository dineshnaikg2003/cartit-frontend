import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/address_provider.dart';
import '../../providers/brand_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/offer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/modern_loaders.dart';
import '../../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHomeData();
    });
  }

  Future<void> _loadHomeData() async {
    await Future.wait([
      context.read<CategoryProvider>().fetchCategories(),
      context.read<BrandProvider>().fetchBrands(),
      context.read<ProductProvider>().fetchFeaturedProducts(),
      context.read<ProductProvider>().fetchProducts(),
      context.read<WishlistProvider>().fetchWishlist(),
      context.read<OfferProvider>().fetchActiveOffers(),
      context.read<AddressProvider>().fetchAddresses(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final brandProvider = context.watch<BrandProvider>();
    final productProvider = context.watch<ProductProvider>();
    final addressProvider = context.watch<AddressProvider>();

    final featuredProducts = productProvider.featuredProducts;
    final defaultAddress = addressProvider.defaultAddress;
    final allProducts = productProvider.products;
    final categoriesWithProducts = categoryProvider.categories.where(
      (cat) => allProducts.any((p) => p.category?.id == cat.id),
    ).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppColors.darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadHomeData,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ---------------------------------------------------------
            // ULTRA MODERN HERO HEADER (Blinkit / Zepto Premium Theme)
            // ---------------------------------------------------------
            SliverAppBar(
              pinned: true,
              floating: false,
              expandedHeight: 165,
              backgroundColor: isDark ? AppColors.darkBackground : AppColors.primary,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? const [Color(0xFF0D2117), Color(0xFF143324)]
                          : const [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Location & Express Tag Row
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.addresses);
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      'assets/images/app_logo.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        defaultAddress != null
                                            ? defaultAddress.fullName
                                            : 'SELECT ADDRESS',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              defaultAddress != null
                                                  ? '${defaultAddress.street}, ${defaultAddress.city}'
                                                  : 'Set delivery address for instant order',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Search Bar Widget
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.productList,
                              );
                            },
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: cardBgColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Search "milk", "fresh fruits", "snacks"...',
                                      style: TextStyle(
                                        color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.mic_none_rounded,
                                    color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ---------------------------------------------------------
            // FEATURED PRODUCTS (Stitch Style Cards)
            // ---------------------------------------------------------
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                context: context,
                title: 'Featured Products',
                action: 'View All',
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.productList);
                },
              ),
            ),

            if (productProvider.isLoading && featuredProducts.isEmpty)
              SliverToBoxAdapter(
                child: ModernLoaders.productGridSkeleton(context, count: 4),
              )
            else if (featuredProducts.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Center(
                    child: Text(
                      'No featured products available',
                      style: TextStyle(
                        color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 330,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: featuredProducts.length,
                    itemBuilder: (context, index) {
                      final product = featuredProducts[index];

                      return SizedBox(
                        width: 210,
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index == featuredProducts.length - 1
                                ? 0
                                : 12,
                          ),
                          child: ProductCard(product: product),
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ---------------------------------------------------------
            // 2 CATEGORY PRODUCT SECTIONS (Dynamic Category Showcase)
            // ---------------------------------------------------------
            if (categoriesWithProducts.isNotEmpty) ...[
              for (int catIndex = 0; catIndex < (categoriesWithProducts.length > 2 ? 2 : categoriesWithProducts.length); catIndex++)
                SliverToBoxAdapter(
                  child: Builder(
                    builder: (context) {
                      final category = categoriesWithProducts[catIndex];
                      final categoryProducts = allProducts.where((p) => p.category?.id == category.id).toList();

                      if (categoryProducts.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            context: context,
                            title: category.name,
                            action: 'View All',
                            onPressed: () {
                              productProvider.filterByCategory(category.id);
                              Navigator.pushNamed(context, AppRoutes.productList);
                            },
                          ),
                          SizedBox(
                            height: 330,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: categoryProducts.length,
                              itemBuilder: (context, index) {
                                final product = categoryProducts[index];
                                return SizedBox(
                                  width: 210,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: index == categoryProducts.length - 1 ? 0 : 12,
                                    ),
                                    child: ProductCard(product: product),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                ),
            ],

            // ---------------------------------------------------------
            // POPULAR BRANDS
            // ---------------------------------------------------------
            if (brandProvider.brands.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context: context,
                  title: 'Popular Brands',
                  action: 'View All',
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.productList);
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 115,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: brandProvider.brands.length,
                    itemBuilder: (context, index) {
                      final brand = brandProvider.brands[index];

                      return GestureDetector(
                        onTap: () {
                          productProvider.filterByBrand(brand.id);
                          Navigator.pushNamed(context, AppRoutes.productList);
                        },
                        child: Container(
                          width: 95,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? AppColors.darkCardBorder : AppColors.border.withValues(alpha: 0.8),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cardShadow.withValues(
                                  alpha: isDark ? 0.2 : 0.06,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkBackground : AppColors.background,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? AppColors.darkCardBorder : AppColors.border.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child:
                                    brand.logoUrl != null &&
                                        brand.logoUrl!.isNotEmpty
                                    ? Image.network(
                                        brand.logoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.business_rounded,
                                                  color: AppColors.primary,
                                                  size: 24,
                                                ),
                                      )
                                    : const Icon(
                                        Icons.business_rounded,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                brand.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? AppColors.darkTitle : AppColors.title,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required String action,
    required VoidCallback onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.darkTitle : AppColors.title,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
