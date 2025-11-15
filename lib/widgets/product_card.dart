import 'package:flutter/cupertino.dart';
import '../models/product.dart';
import '../config/app_colors.dart';
import '../utils/format_utils.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool showFavoriteButton;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.showFavoriteButton = false,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.hasDiscount;
    final discountPercentage = product.discountPercentage;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.resolveCardBackground(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.resolveCardBorder(context),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image - Top section
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.resolveImageBackground(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      product.imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: 180,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            CupertinoIcons.photo,
                            size: 60,
                            color: AppColors.resolveTextTertiary(context),
                          ),
                        );
                      },
                    ),
                    // Favorite Button (for explore tab)
                    if (showFavoriteButton)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: GestureDetector(
                          onTap: onFavoriteToggle,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: CupertinoColors.white.withOpacity(0.95),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                              size: 20,
                              color: isFavorite ? AppColors.alertRed : CupertinoColors.systemGrey,
                            ),
                          ),
                        ),
                      ),
                    // Discount Badge
                    if (hasDiscount)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.discountGradient,
                            borderRadius: BorderRadius.circular(8),
                            
                          ),
                          child: Text(
                            '-${FormatUtils.formatPercentage(discountPercentage)}',
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    // Target Price Alert Badge
                    if (product.targetPrice != null && product.currentPrice <= product.targetPrice!)
                      Positioned(
                        top: hasDiscount ? 50 : 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.alertRed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                CupertinoIcons.bell_fill,
                                size: 12,
                                color: CupertinoColors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Meta',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Product Info Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: AppColors.resolveTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Price Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        FormatUtils.formatPrice(product.currentPrice),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                          height: 1.0,
                        ),
                      ),
                      if (hasDiscount && product.originalPrice != null) ...[
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            FormatUtils.formatPrice(product.originalPrice!),
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.resolveTextTertiary(context),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Price Range or Last Updated
                  if (hasDiscount) ...[
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.chart_bar,
                          size: 14,
                          color: AppColors.resolveTextSecondary(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Rango actual: ${FormatUtils.formatPrice(_getMinPrice())} - ${FormatUtils.formatPrice(_getMaxPrice())}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.resolveTextSecondary(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ] else if (product.priceHistory.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.chart_bar,
                          size: 14,
                          color: AppColors.resolveTextSecondary(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Rango histórico: ${FormatUtils.formatPrice(_getHistoricalMinPrice())} - ${FormatUtils.formatPrice(_getHistoricalMaxPrice())}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.resolveTextSecondary(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.clock,
                          size: 14,
                          color: AppColors.resolveTextSecondary(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Actualizado ${FormatUtils.formatRelativeDate(product.lastUpdated)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.resolveTextSecondary(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMinPrice() {
    // Crear lista con todos los precios disponibles (incluye precio original)
    final allPrices = <double>[
      product.currentPrice,
      if (product.originalPrice != null) product.originalPrice!,
      ...product.priceHistory.map((h) => h.price),
    ];
    
    if (allPrices.isEmpty) return product.currentPrice;
    return allPrices.reduce((a, b) => a < b ? a : b);
  }

  double _getMaxPrice() {
    // Crear lista con todos los precios disponibles (incluye precio original)
    final allPrices = <double>[
      product.currentPrice,
      if (product.originalPrice != null) product.originalPrice!,
      ...product.priceHistory.map((h) => h.price),
    ];
    
    if (allPrices.isEmpty) return product.currentPrice;
    return allPrices.reduce((a, b) => a > b ? a : b);
  }

  double _getHistoricalMinPrice() {
    // Solo considera precio actual e historial (NO precio original)
    final historicalPrices = <double>[
      product.currentPrice,
      ...product.priceHistory.map((h) => h.price),
    ];
    
    if (historicalPrices.isEmpty) return product.currentPrice;
    return historicalPrices.reduce((a, b) => a < b ? a : b);
  }

  double _getHistoricalMaxPrice() {
    // Solo considera precio actual e historial (NO precio original)
    final historicalPrices = <double>[
      product.currentPrice,
      ...product.priceHistory.map((h) => h.price),
    ];
    
    if (historicalPrices.isEmpty) return product.currentPrice;
    return historicalPrices.reduce((a, b) => a > b ? a : b);
  }

}
