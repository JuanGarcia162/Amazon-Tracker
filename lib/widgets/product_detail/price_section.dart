import 'package:flutter/cupertino.dart';
import '../../config/app_colors.dart';
import '../../utils/format_utils.dart';

/// Sección de precio del producto
class PriceSection extends StatelessWidget {
  final double currentPrice;
  final double? originalPrice;
  final bool hasDiscount;
  final double discountPercentage;

  const PriceSection({
    super.key,
    required this.currentPrice,
    this.originalPrice,
    required this.hasDiscount,
    required this.discountPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              FormatUtils.formatPrice(currentPrice),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            if (hasDiscount && originalPrice != null) ...[
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  FormatUtils.formatPrice(originalPrice!),
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.resolveTextTertiary(context),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (hasDiscount && originalPrice != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.discountGradient,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: AppColors.discountGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Ahorra ${FormatUtils.formatPercentage(discountPercentage)} • ${FormatUtils.formatPrice(originalPrice! - currentPrice)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
