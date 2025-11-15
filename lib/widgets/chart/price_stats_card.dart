import 'package:flutter/cupertino.dart';
import '../../config/app_colors.dart';
import '../../utils/format_utils.dart';

/// Card con estadísticas de precios
class PriceStatsCard extends StatelessWidget {
  final double currentPrice;
  final double minPrice;
  final double maxPrice;
  final double avgPrice;

  const PriceStatsCard({
    super.key,
    required this.currentPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.avgPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.resolveImageBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.resolveCardBorder(context),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Actual',
            value: FormatUtils.formatPrice(currentPrice),
            color: AppColors.primaryBlue,
            icon: CupertinoIcons.money_dollar_circle_fill,
          ),
          _StatItem(
            label: 'Mínimo',
            value: FormatUtils.formatPrice(minPrice),
            color: AppColors.discountGreen,
            icon: CupertinoIcons.arrow_down_circle_fill,
          ),
          _StatItem(
            label: 'Máximo',
            value: FormatUtils.formatPrice(maxPrice),
            color: AppColors.alertRed,
            icon: CupertinoIcons.arrow_up_circle_fill,
          ),
          _StatItem(
            label: 'Promedio',
            value: FormatUtils.formatPrice(avgPrice),
            color: AppColors.primaryBlueLight,
            icon: CupertinoIcons.chart_bar_circle_fill,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.resolveTextSecondary(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
