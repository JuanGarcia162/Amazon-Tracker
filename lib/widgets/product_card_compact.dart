import 'package:flutter/cupertino.dart';
import '../models/product.dart';
import '../config/app_colors.dart';
import '../utils/format_utils.dart';

class ProductCardCompact extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool showAlertBadge;

  const ProductCardCompact({
    super.key,
    required this.product,
    required this.onTap,
    this.showAlertBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.hasDiscount;
    final discountPercentage = product.discountPercentage;
    final isAtTargetPrice = product.targetPrice != null && 
                           product.currentPrice <= product.targetPrice!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.resolveCardBackground(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image - Left section (compact)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.resolveImageBackground(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      product.imageUrl,
                      fit: BoxFit.contain,
                      width: 120,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            CupertinoIcons.photo,
                            size: 40,
                            color: AppColors.resolveTextTertiary(context),
                          ),
                        );
                      },
                    ),
                    // Discount Badge (smaller)
                    if (hasDiscount)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.discountGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${FormatUtils.formatPercentage(discountPercentage)}',
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Product Info - Right section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title and Alert Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                              color: AppColors.resolveTextPrimary(context),
                            ),
                          ),
                        ),
                        if (isAtTargetPrice && showAlertBadge) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.alertRed,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              CupertinoIcons.bell_fill,
                              size: 12,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Price Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              FormatUtils.formatPrice(product.currentPrice),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                                height: 1.0,
                              ),
                            ),
                            if (hasDiscount && product.originalPrice != null) ...[
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  FormatUtils.formatPrice(product.originalPrice!),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.resolveTextTertiary(context),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Last Updated or Target Price Info
                        if (isAtTargetPrice && showAlertBadge)
                          Row(
                            children: [
                              const Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                size: 12,
                                color: AppColors.discountGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Meta: ${FormatUtils.formatPrice(product.targetPrice!)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.discountGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.clock,
                                size: 11,
                                color: AppColors.resolveTextSecondary(context),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  FormatUtils.formatRelativeDate(product.lastUpdated),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.resolveTextSecondary(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
