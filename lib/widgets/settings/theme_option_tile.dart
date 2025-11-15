import 'package:flutter/cupertino.dart';
import '../../config/app_colors.dart';

/// Tile de opción de tema
class ThemeOptionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const ThemeOptionTile({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.resolveSeparator(context),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue.withOpacity(0.1)
                    : AppColors.resolveImageBackground(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.resolveTextSecondary(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      color: AppColors.resolveTextPrimary(context),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.resolveTextSecondary(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                CupertinoIcons.check_mark,
                size: 20,
                color: AppColors.primaryBlue,
              ),
          ],
        ),
      ),
    );
  }
}
