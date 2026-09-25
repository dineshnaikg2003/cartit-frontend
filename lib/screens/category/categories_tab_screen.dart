import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';

import '../../widgets/modern_loaders.dart';

class CategoriesTabScreen extends StatefulWidget {
  const CategoriesTabScreen({super.key});

  @override
  State<CategoriesTabScreen> createState() => _CategoriesTabScreenState();
}

class _CategoriesTabScreenState extends State<CategoriesTabScreen> {
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final categoryProvider = context.read<CategoryProvider>();
      await categoryProvider.fetchCategories();
      if (categoryProvider.categories.isNotEmpty && mounted) {
        final firstCategoryId = categoryProvider.categories[0].id;
        context.read<ProductProvider>().fetchProducts(categoryId: firstCategoryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final productProvider = context.watch<ProductProvider>();
    final categories = categoryProvider.categories;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppColors.darkSurface : Colors.white;
    final sidebarBgColor = isDark ? const Color(0xFF061E13) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.border;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cardBgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        shadowColor: AppColors.cardShadow,
        titleSpacing: 20,
        automaticallyImplyLeading: false,
        title: Text(
          'All Categories',
          style: TextStyle(
            color: isDark ? AppColors.darkTitle : AppColors.title,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.background,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.search_rounded,
                color: isDark ? AppColors.darkTitle : AppColors.title,
                size: 20,
              ),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.productList);
              },
            ),
          ),
        ],
      ),
      body: categoryProvider.isLoading && categories.isEmpty
          ? ModernLoaders.categoryTabSkeleton(context)
          : categories.isEmpty
              ? Center(
                  child: Text(
                    'No categories available',
                    style: TextStyle(
                      color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                      fontSize: 14,
                    ),
                  ),
                )
              : Row(
                  children: [
                    // LEFT SIDEBAR: Category Tabs with Press Feedback
                    Container(
                      width: 108,
                      color: sidebarBgColor,
                      child: ListView.builder(
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = index == _selectedCategoryIndex;

                          return _AnimatedCategoryTile(
                            category: category,
                            isSelected: isSelected,
                            onTap: () {
                              if (_selectedCategoryIndex != index) {
                                setState(() {
                                  _selectedCategoryIndex = index;
                                });
                                context.read<ProductProvider>().fetchProducts(categoryId: category.id);
                              }
                            },
                          );
                        },
                      ),
                    ),

                    VerticalDivider(width: 1, color: borderColor),

                    // RIGHT CONTENT: Animated Switcher with Smooth Slide & Fade
                    Expanded(
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        padding: const EdgeInsets.all(16),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.06, 0.0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Builder(
                            key: ValueKey<int>(_selectedCategoryIndex),
                            builder: (context) {
                              if (_selectedCategoryIndex >= categories.length) {
                                return const SizedBox.shrink();
                              }
                              final currentCategory = categories[_selectedCategoryIndex];

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category Header Banner
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary.withValues(alpha: 0.1),
                                          AppColors.primary.withValues(alpha: 0.03),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                currentCategory.name,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w900,
                                                  color: AppColors.title,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                currentCategory.description ??
                                                    'Fresh essentials & top deals in ${currentCategory.name}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.subtitle,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        _AnimatedButton(
                                          onPressed: () {
                                            productProvider.filterByCategory(currentCategory.id);
                                            Navigator.pushNamed(context, AppRoutes.productList);
                                          },
                                          child: Container(
                                            height: 36,
                                            padding: const EdgeInsets.symmetric(horizontal: 14),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Text(
                                              'Explore All',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${currentCategory.name} Products',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? AppColors.darkTitle : AppColors.title,
                                        ),
                                      ),
                                      if (productProvider.products.isNotEmpty)
                                        Text(
                                          '${productProvider.products.length} Items',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  Expanded(
                                    child: productProvider.isLoading
                                        ? ModernLoaders.productGridSkeleton(context, count: 4)
                                        : productProvider.products.isEmpty
                                            ? Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      width: 64,
                                                      height: 64,
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 1.0),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.inventory_2_outlined,
                                                        size: 30,
                                                        color: AppColors.primary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      'No products in ${currentCategory.name}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w800,
                                                        color: isDark ? AppColors.darkTitle : AppColors.title,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Check back soon for fresh additions',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : GridView.builder(
                                                padding: const EdgeInsets.only(bottom: 20),
                                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 2,
                                                  childAspectRatio: 0.54,
                                                  crossAxisSpacing: 10,
                                                  mainAxisSpacing: 10,
                                                ),
                                                itemCount: productProvider.products.length,
                                                itemBuilder: (context, pIndex) {
                                                  final product = productProvider.products[pIndex];
                                                  return ProductCard(product: product);
                                                },
                                              ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

/// Category Sidebar Tile Widget with Micro Scale Click Animation
class _AnimatedCategoryTile extends StatefulWidget {
  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedCategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AnimatedCategoryTile> createState() => _AnimatedCategoryTileState();
}

class _AnimatedCategoryTileState extends State<_AnimatedCategoryTile> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileBg = widget.isSelected
        ? (isDark ? AppColors.darkSurface : Colors.white)
        : Colors.transparent;

    return InkWell(
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: widget.isSelected ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: tileBg,
            border: Border(
              left: BorderSide(
                color: widget.isSelected ? AppColors.primary : Colors.transparent,
                width: 4,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : (isDark ? AppColors.darkBackground : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.isSelected
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : (isDark ? AppColors.darkCardBorder : AppColors.border),
                    width: widget.isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: widget.category.imageUrl != null &&
                          widget.category.imageUrl!.isNotEmpty
                      ? Image.network(
                          widget.category.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.category_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        )
                      : const Icon(
                          Icons.category_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: widget.isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: widget.isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkTitle : AppColors.title),
                ),
                child: Text(
                  widget.category.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Generic Button Widget with Tactile Scale Animation on Click
class _AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _AnimatedButton({
    required this.child,
    required this.onPressed,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

