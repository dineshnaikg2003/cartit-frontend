import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../providers/product_provider.dart';

class ProductSortWidget extends StatelessWidget {
  final ProductSort selectedSort;
  final ValueChanged<ProductSort> onSortChanged;

  const ProductSortWidget({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  String _getSortLabel(ProductSort sort) {
    switch (sort) {
      case ProductSort.recommended:
        return 'Recommended';

      case ProductSort.priceLowToHigh:
        return 'Price: Low to High';

      case ProductSort.priceHighToLow:
        return 'Price: High to Low';

      case ProductSort.nameAToZ:
        return 'Name: A → Z';

      case ProductSort.nameZToA:
        return 'Name: Z → A';

      case ProductSort.newest:
        return 'Newest';
    }
  }

  Future<void> _showSortSheet(
    BuildContext context,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selected =
        await showModalBottomSheet<ProductSort>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------
                // HANDLE
                // -------------------------------------------------
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // -------------------------------------------------
                // HEADER
                // -------------------------------------------------
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sort By',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.darkTitle : AppColors.title,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // -------------------------------------------------
                // OPTIONS
                // -------------------------------------------------
                ...ProductSort.values.map(
                  (sort) {
                    final isSelected = sort == selectedSort;

                    return InkWell(
                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                          sort,
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(
                          bottom: 8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight.withValues(alpha: isDark ? 0.25 : 1.0)
                              : (isDark ? AppColors.darkBackground : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkCardBorder : AppColors.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              size: 20,
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkSubtitle : AppColors.subtitle),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child: Text(
                                _getSortLabel(
                                  sort,
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? AppColors.darkTitle : AppColors.title),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      onSortChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDefault =
        selectedSort ==
            ProductSort.recommended;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnBg = isDefault
        ? (isDark ? AppColors.darkSurface : Colors.white)
        : AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 1.0);
    final borderColor = isDefault
        ? (isDark ? AppColors.darkCardBorder : AppColors.border)
        : AppColors.primary;
    final textColor = isDefault
        ? (isDark ? AppColors.darkTitle : AppColors.title)
        : AppColors.primary;

    return OutlinedButton.icon(
      onPressed: () {
        _showSortSheet(context);
      },
      icon: const Icon(
        Icons.swap_vert_rounded,
        size: 18,
      ),
      label: const Text(
        'Sort By',
        style: TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
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
}