import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../models/brand_model.dart';
import '../models/category_model.dart';

class ProductFilterWidget extends StatelessWidget {
  final List<CategoryModel> categories;
  final List<BrandModel> brands;

  final int? selectedCategoryId;
  final int? selectedBrandId;

  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<int?> onBrandChanged;

  final VoidCallback onClear;

  const ProductFilterWidget({
    super.key,
    required this.categories,
    required this.brands,
    required this.selectedCategoryId,
    required this.selectedBrandId,
    required this.onCategoryChanged,
    required this.onBrandChanged,
    required this.onClear,
  });

  bool get hasFilters =>
      selectedCategoryId != null ||
      selectedBrandId != null;

  String _getCategoryName() {
    if (selectedCategoryId == null) {
      return '';
    }

    for (final category in categories) {
      if (category.id == selectedCategoryId) {
        return category.name;
      }
    }

    return '';
  }

  String _getBrandName() {
    if (selectedBrandId == null) {
      return '';
    }

    for (final brand in brands) {
      if (brand.id == selectedBrandId) {
        return brand.name;
      }
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnBg = hasFilters
        ? AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 1.0)
        : (isDark ? AppColors.darkSurface : Colors.white);
    final borderColor = hasFilters
        ? AppColors.primary
        : (isDark ? AppColors.darkCardBorder : AppColors.border);

    return OutlinedButton.icon(
      onPressed: () {
        _showFilterSheet(context);
      },
      icon: const Icon(
        Icons.tune_rounded,
        size: 18,
      ),
      label: const Text(
        'Filters',
        style: TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor:
            hasFilters
                ? AppColors.primary
                : (isDark ? AppColors.darkTitle : AppColors.title),
        backgroundColor: btnBg,
        side: BorderSide(
          color: borderColor,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 9,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(11),
        ),
      ),
    );
  }

  void _showFilterSheet(
    BuildContext context,
  ) {
    int? temporaryCategoryId =
        selectedCategoryId;

    int? temporaryBrandId =
        selectedBrandId;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            setModalState,
          ) {
            return Container(
              constraints:
                  BoxConstraints(
                maxHeight:
                    MediaQuery.of(context)
                            .size
                            .height *
                        0.82,
              ),
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20,
              ),
              decoration:
                  BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    // ------------------------------------------------
                    // HANDLE
                    // ------------------------------------------------
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration:
                            BoxDecoration(
                          color:
                              AppColors.border,
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ------------------------------------------------
                    // HEADER
                    // ------------------------------------------------
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isDark ? AppColors.darkTitle : AppColors.title,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              temporaryCategoryId = null;
                              temporaryBrandId = null;
                            });
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ------------------------------------------------
                    // FILTER CONTENT
                    // ------------------------------------------------
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // CATEGORY
                            _buildFilterTitle(
                              'Category',
                              Icons.category_outlined,
                              isDark: isDark,
                            ),

                            const SizedBox(
                              height: 10,
                            ),

                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: Text(
                                    'All',
                                    style: TextStyle(
                                      color: temporaryCategoryId == null
                                          ? AppColors.primary
                                          : (isDark ? AppColors.darkTitle : AppColors.title),
                                      fontWeight: temporaryCategoryId == null ? FontWeight.w800 : FontWeight.w500,
                                    ),
                                  ),
                                  selected: temporaryCategoryId == null,
                                  onSelected: (_) {
                                    setModalState(() {
                                      temporaryCategoryId = null;
                                    });
                                  },
                                  backgroundColor: isDark ? AppColors.darkBackground : Colors.grey[100],
                                  selectedColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 1.0),
                                  checkmarkColor: AppColors.primary,
                                  side: BorderSide(
                                    color: temporaryCategoryId == null
                                        ? AppColors.primary
                                        : (isDark ? AppColors.darkCardBorder : AppColors.border),
                                  ),
                                ),
                                ...categories.map(
                                  (category) {
                                    final selected = temporaryCategoryId == category.id;

                                    return ChoiceChip(
                                      label: Text(
                                        category.name,
                                        style: TextStyle(
                                          color: selected
                                              ? AppColors.primary
                                              : (isDark ? AppColors.darkTitle : AppColors.title),
                                          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                                        ),
                                      ),
                                      selected: selected,
                                      onSelected: (_) {
                                        setModalState(() {
                                          temporaryCategoryId = category.id;
                                        });
                                      },
                                      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey[100],
                                      selectedColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 1.0),
                                      checkmarkColor: AppColors.primary,
                                      side: BorderSide(
                                        color: selected
                                            ? AppColors.primary
                                            : (isDark ? AppColors.darkCardBorder : AppColors.border),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 26,
                            ),

                            // BRAND
                            _buildFilterTitle(
                              'Brand',
                              Icons.storefront_outlined,
                              isDark: isDark,
                            ),

                            const SizedBox(
                              height: 10,
                            ),

                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: Text(
                                    'All',
                                    style: TextStyle(
                                      color: temporaryBrandId == null
                                          ? AppColors.primary
                                          : (isDark ? AppColors.darkTitle : AppColors.title),
                                      fontWeight: temporaryBrandId == null ? FontWeight.w800 : FontWeight.w500,
                                    ),
                                  ),
                                  selected: temporaryBrandId == null,
                                  onSelected: (_) {
                                    setModalState(() {
                                      temporaryBrandId = null;
                                    });
                                  },
                                  backgroundColor: isDark ? AppColors.darkBackground : Colors.grey[100],
                                  selectedColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 1.0),
                                  checkmarkColor: AppColors.primary,
                                  side: BorderSide(
                                    color: temporaryBrandId == null
                                        ? AppColors.primary
                                        : (isDark ? AppColors.darkCardBorder : AppColors.border),
                                  ),
                                ),
                                ...brands.map(
                                  (brand) {
                                    final selected = temporaryBrandId == brand.id;

                                    return ChoiceChip(
                                      label: Text(
                                        brand.name,
                                        style: TextStyle(
                                          color: selected
                                              ? AppColors.primary
                                              : (isDark ? AppColors.darkTitle : AppColors.title),
                                          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                                        ),
                                      ),
                                      selected: selected,
                                      onSelected: (_) {
                                        setModalState(() {
                                          temporaryBrandId = brand.id;
                                        });
                                      },
                                      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey[100],
                                      selectedColor: AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 1.0),
                                      checkmarkColor: AppColors.primary,
                                      side: BorderSide(
                                        color: selected
                                            ? AppColors.primary
                                            : (isDark ? AppColors.darkCardBorder : AppColors.border),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ------------------------------------------------
                    // APPLY
                    // ------------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          onCategoryChanged(
                            temporaryCategoryId,
                          );

                          onBrandChanged(
                            temporaryBrandId,
                          );

                          Navigator.pop(
                            sheetContext,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterTitle(
    String title,
    IconData icon, {
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(
          width: 7,
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTitle : AppColors.title,
          ),
        ),
      ],
    );
  }

  // These getters are intentionally kept here
  // so the widget can later display selected
  // filter summaries without changing its API.
  String get selectedCategoryName =>
      _getCategoryName();

  String get selectedBrandName =>
      _getBrandName();

  // Keep this callback available for
  // the parent screen's "Clear all" action.
  void clearFilters() {
    onClear();
  }
}