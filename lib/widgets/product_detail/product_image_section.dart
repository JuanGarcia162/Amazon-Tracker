import 'package:flutter/cupertino.dart';
import '../../config/app_colors.dart';

/// Sección de imagen del producto
class ProductImageSection extends StatelessWidget {
  final String imageUrl;

  const ProductImageSection({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.resolveImageBackground(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.resolveCardBorder(context),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
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
        ),
      ),
    );
  }
}
