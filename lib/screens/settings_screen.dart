import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../config/app_colors.dart';
import '../widgets/common/custom_navigation_bar.dart';
import '../widgets/settings/settings_section_header.dart';
import '../widgets/settings/settings_group.dart';
import '../widgets/settings/theme_option_tile.dart';
import '../widgets/settings/settings_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final userEmail = authProvider.user?.email ?? 'Usuario';

    return CupertinoPageScaffold(
      navigationBar: CustomNavigationBar(
        context: context,
        middle: const Text(
          'Ajustes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            // Sección de perfil
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.person_fill,
                      size: 35,
                      color: CupertinoColors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perfil',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.resolveTextSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.resolveTextPrimary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Sección de apariencia
            const SettingsSectionHeader(title: 'APARIENCIA'),
            SettingsGroup(
              children: [
                ThemeOptionTile(
                  title: 'Modo Claro',
                  icon: CupertinoIcons.sun_max_fill,
                  isSelected: themeProvider.themeMode == ThemeMode.light,
                  onTap: () => themeProvider.setLightMode(),
                ),
                ThemeOptionTile(
                  title: 'Modo Oscuro',
                  icon: CupertinoIcons.moon_fill,
                  isSelected: themeProvider.themeMode == ThemeMode.dark,
                  onTap: () => themeProvider.setDarkMode(),
                ),
                ThemeOptionTile(
                  title: 'Automático',
                  icon: CupertinoIcons.device_phone_portrait,
                  subtitle: 'Según el sistema',
                  isSelected: themeProvider.themeMode == ThemeMode.system,
                  onTap: () => themeProvider.setSystemMode(),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Sección de cuenta
            const SettingsSectionHeader(title: 'CUENTA'),
            SettingsGroup(
              children: [
                SettingsTile(
                  title: 'Cerrar Sesión',
                  icon: CupertinoIcons.square_arrow_right,
                  iconColor: CupertinoColors.systemRed,
                  textColor: CupertinoColors.systemRed,
                  onTap: () => _showLogoutDialog(context, authProvider),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Información de la app
            Center(
              child: Column(
                children: [
                  Text(
                    'Amazon Tracker',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versión 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }


  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text(
            '¿Estás seguro de que quieres cerrar sesión?',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await authProvider.signOut();
              },
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
}
