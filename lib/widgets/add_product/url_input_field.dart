import 'package:flutter/cupertino.dart';
import '../../config/app_colors.dart';

/// Campo de entrada para URL del producto
class UrlInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final IconData prefixIcon;

  const UrlInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.placeholder,
    required this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          placeholderStyle: TextStyle(
            color: AppColors.resolveTextTertiary(context),
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.resolveCardBackground(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.resolveCardBorder(context),
              width: 1,
            ),
          ),
          prefix: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Icon(
              prefixIcon,
              color: AppColors.resolveTextTertiary(context),
              size: 20,
            ),
          ),
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
        ),
      ],
    );
  }
}
