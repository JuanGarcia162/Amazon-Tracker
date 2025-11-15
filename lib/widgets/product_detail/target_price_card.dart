import 'package:flutter/cupertino.dart';
import '../../config/app_colors.dart';
import '../../utils/format_utils.dart';

/// Card de precio objetivo
class TargetPriceCard extends StatelessWidget {
  final double? targetPrice;
  final VoidCallback onTap;

  const TargetPriceCard({
    super.key,
    this.targetPrice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.alertBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                CupertinoIcons.bell_fill,
                color: AppColors.alertRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Precio Objetivo',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.resolveTextSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    targetPrice != null
                        ? FormatUtils.formatPrice(targetPrice!)
                        : 'Toca para establecer',
                    style: TextStyle(
                      fontSize: 16,
                      color: targetPrice != null
                          ? AppColors.alertRed
                          : AppColors.resolveTextTertiary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: AppColors.resolveTextTertiary(context),
            ),
          ],
        ),
      ),
    );
  }
}
