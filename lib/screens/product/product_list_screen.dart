import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_colors.dart';
import '../../providers/brand_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../cart/cart_screen.dart';
import '../../widgets/product_filter_widget.dart';
import '../../widgets/product_sort_widget.dart';
import '../../widgets/product_card.dart';
import '../../widgets/modern_loaders.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = context.read<ProductProvider>();
      _searchController.text = productProvider.searchQuery;

      context.read<CategoryProvider>().fetchCategories();
      context.read<BrandProvider>().fetchBrands();

      if (productProvider.products.isEmpty) {
        productProvider.fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch(String value) {
    context.read<ProductProvider>().setSearchQuery(value.trim());
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ProductProvider>().setSearchQuery('');
  }

  void _clearAllFilters() {
    _searchController.clear();
    context.read<ProductProvider>().clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final brandProvider = context.watch<BrandProvider>();
    final cartProvider = context.watch<CartProvider>();

    final hasCategoryFilter = productProvider.selectedCategoryId != null;
    final hasBrandFilter = productProvider.selectedBrandId != null;
    final hasSearch = productProvider.searchQuery.isNotEmpty;
    final hasAnyFilter = hasCategoryFilter || hasBrandFilter || hasSearch;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppColors.darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cardBgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: AppColors.cardShadow,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'CartIT',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'STORE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Explore fresh items & daily offers',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.shopping_bag_outlined,
                  color: isDark ? AppColors.darkTitle : AppColors.title,
                  size: 24,
                ),
              ),
              if (cartProvider.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: Column(
        children: [
          // Dynamic Header Container (Search Bar)
          Container(
            decoration: BoxDecoration(
              color: cardBgColor,
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _submitSearch,
              onChanged: (_) {
                setState(() {});
              },
              style: TextStyle(
                color: isDark ? AppColors.darkTitle : AppColors.title,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search products, brands & categories...',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: _clearSearch,
                        icon: Icon(
                          Icons.cancel_rounded,
                          color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                          size: 18,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkCardBorder : AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // Filters & Sort Bar
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                ProductFilterWidget(
                  categories: categoryProvider.categories,
                  brands: brandProvider.brands,
                  selectedCategoryId: productProvider.selectedCategoryId,
                  selectedBrandId: productProvider.selectedBrandId,
                  onCategoryChanged: (categoryId) {
                    if (categoryId == null) {
                      productProvider.clearCategoryFilter();
                    } else {
                      productProvider.filterByCategory(categoryId);
                    }
                  },
                  onBrandChanged: (brandId) {
                    if (brandId == null) {
                      productProvider.clearBrandFilter();
                    } else {
                      productProvider.filterByBrand(brandId);
                    }
                  },
                  onClear: _clearAllFilters,
                ),
                const SizedBox(width: 8),
                ProductSortWidget(
                  selectedSort: productProvider.selectedSort,
                  onSortChanged: productProvider.applySort,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.border),
                  ),
                  child: Text(
                    productProvider.isLoading
                        ? '...'
                        : '${productProvider.products.length} Products',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active Filters Banner
          if (hasAnyFilter)
            Container(
              width: double.infinity,
              color: isDark ? AppColors.darkBackground : AppColors.background,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (hasSearch)
                      Chip(
                        label: Text('“${productProvider.searchQuery}”'),
                        onDeleted: _clearSearch,
                        deleteIcon: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                        ),
                        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                        side: BorderSide(
                          color: isDark ? AppColors.darkCardBorder : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                        ),
                      ),
                    if (hasSearch && (hasCategoryFilter || hasBrandFilter))
                      const SizedBox(width: 6),
                    if (hasCategoryFilter)
                      _buildCategoryChip(categoryProvider, productProvider, isDark: isDark),
                    if (hasCategoryFilter && hasBrandFilter)
                      const SizedBox(width: 6),
                    if (hasBrandFilter)
                      _buildBrandChip(brandProvider, productProvider, isDark: isDark),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: _clearAllFilters,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Clear all',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Grid View
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await productProvider.fetchProducts();
              },
              child: productProvider.isLoading && productProvider.products.isEmpty
                  ? ModernLoaders.productGridSkeleton(context, count: 6)
                  : productProvider.hasError
                      ? _buildErrorState(
                          message: productProvider.errorMessage ?? ProductProvider.defaultErrorMessage,
                          onRetry: () => productProvider.fetchProducts(),
                        )
                      : productProvider.products.isEmpty
                          ? _buildEmptyState()
                          : GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.63,
                              ),
                              itemCount: productProvider.products.length,
                              itemBuilder: (context, index) {
                                final product = productProvider.products[index];
                                return ProductCard(product: product);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    CategoryProvider categoryProvider,
    ProductProvider productProvider, {
    required bool isDark,
  }) {
    String name = 'Category';
    for (final category in categoryProvider.categories) {
      if (category.id == productProvider.selectedCategoryId) {
        name = category.name;
        break;
      }
    }
    return Chip(
      label: Text(name),
      onDeleted: productProvider.clearCategoryFilter,
      deleteIcon: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
      backgroundColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 1.0),
      side: BorderSide(color: AppColors.primary.withValues(alpha: isDark ? 0.6 : 0.3)),
      labelStyle: const TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildBrandChip(
    BrandProvider brandProvider,
    ProductProvider productProvider, {
    required bool isDark,
  }) {
    String name = 'Brand';
    for (final brand in brandProvider.brands) {
      if (brand.id == productProvider.selectedBrandId) {
        name = brand.name;
        break;
      }
    }
    return Chip(
      label: Text(name),
      onDeleted: productProvider.clearBrandFilter,
      deleteIcon: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
      backgroundColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 1.0),
      side: BorderSide(color: AppColors.primary.withValues(alpha: isDark ? 0.6 : 0.3)),
      labelStyle: const TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildErrorState({
    required String message,
    required VoidCallback onRetry,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(30),
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
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
              message,
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
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
              width: 86,
              height: 86,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Try another search or change your filters.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.subtitle),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _clearAllFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Clear All Filters',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

