
import 'package:cartit/models/offer_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_colors.dart';
import '../core/routes/app_routes.dart';
import '../core/utils/formatters.dart';
import '../providers/offer_provider.dart';

class OffersSection extends StatelessWidget {
  const OffersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final offerProvider = context.watch<OfferProvider>();

    if (offerProvider.isLoading && offerProvider.offers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (offerProvider.offers.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------------------------------------------------
        // SECTION HEADER
        // ---------------------------------------------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Offers",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTitle : AppColors.title,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.productList,
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ---------------------------------------------------------
        // OFFER CARDS
        // ---------------------------------------------------------
        SizedBox(
          height: 215,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            itemCount: offerProvider.offers.length,
            itemBuilder: (context, index) {
              final offer = offerProvider.offers[index];

              return _buildOfferCard(
                context,
                offer,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOfferCard(
    BuildContext context,
    OfferModel offer,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.border;

    final minimumPurchase =
        Formatters.currency(
      offer.minimumPurchaseAmount,
    );

    final rewardPrice =
        Formatters.currency(
      offer.rewardPrice,
    );

    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------
          // TOP ROW
          // -------------------------------------------------------
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 1.0),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  offer.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTitle : AppColors.title,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // -------------------------------------------------------
          // DESCRIPTION
          // -------------------------------------------------------
          if (offer.description != null &&
              offer.description!.trim().isNotEmpty)
            Text(
              offer.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                height: 1.3,
              ),
            ),

          const SizedBox(height: 10),

          // -------------------------------------------------------
          // PURCHASE CONDITION
          // -------------------------------------------------------
          Text(
            'Minimum purchase $minimumPurchase',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTitle : AppColors.title,
            ),
          ),

          const SizedBox(height: 6),

          // -------------------------------------------------------
          // REWARD
          // -------------------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Get ${offer.rewardQuantity} '
                    '${offer.rewardProductName ?? 'reward product'} '
                    'at $rewardPrice',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTitle : AppColors.title,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // -------------------------------------------------------
          // FOOTER
          // -------------------------------------------------------
          Row(
            children: [
              Expanded(
                child: Text(
                  'Valid until ${offer.expiryText}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.subtitle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.productList,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'Shop Now',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
