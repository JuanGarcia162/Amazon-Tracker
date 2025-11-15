import 'package:flutter/cupertino.dart';
import '../../config/app_colors.dart';

/// Campo de entrada para precio objetivo
class PriceInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final String? helpText;

  const PriceInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.placeholder,
    this.helpText,
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
            child: Text(
              '\$',
              style: TextStyle(
                fontSize: 17,
                color: AppColors.resolveTextTertiary(context),
              ),
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
        ),
        if (helpText != null) ...[
          const SizedBox(height: 8),
          Text(
            helpText!,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.resolveTextTertiary(context),
            ),
          ),
        ],
      ],
    );
  }
}
