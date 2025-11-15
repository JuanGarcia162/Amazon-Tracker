import 'package:flutter/cupertino.dart';
import '../../config/app_colors.dart';

/// Barra de navegación personalizada reutilizable
class CustomNavigationBar extends StatelessWidget implements ObstructingPreferredSizeWidget {
  final Widget? middle;
  final Widget? leading;
  final Widget? trailing;
  final BuildContext context;

  const CustomNavigationBar({
    super.key,
    required this.context,
    this.middle,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoNavigationBar(
      backgroundColor: AppColors.resolveBarBackground(context),
      border: Border(
        bottom: BorderSide(
          color: AppColors.resolveSeparator(context),
          width: 0.5,
        ),
      ),
      middle: middle,
      leading: leading,
      trailing: trailing,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(44.0);

  @override
  bool shouldFullyObstruct(BuildContext context) {
    return true;
  }
}
