import 'package:flutter/cupertino.dart';
import '../../config/app_colors.dart';

/// Grupo de opciones de configuración
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const SettingsGroup({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.resolveCardBackground(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.resolveSeparator(context),
          width: 0.5,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}
