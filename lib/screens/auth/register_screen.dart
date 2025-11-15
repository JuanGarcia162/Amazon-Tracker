import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Las contraseñas no coinciden');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) {
        Navigator.of(context).pop(); // Return to login
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.resolveBarBackground(context),
        border: Border(
          bottom: BorderSide(
            color: AppColors.resolveSeparator(context),
            width: 0.5,
          ),
        ),
        middle: const Text('Crear Cuenta'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
            const SizedBox(height: 20),
            Text(
              'Regístrate',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.resolveTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea una cuenta para rastrear productos globalmente',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.resolveTextSecondary(context),
              ),
            ),
            const SizedBox(height: 40),
            // Email Field
            CupertinoTextField(
              controller: _emailController,
              placeholder: 'Correo electrónico',
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.resolveImageBackground(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.resolveCardBorder(context),
                  width: 1,
                ),
              ),
              prefix: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(
                  CupertinoIcons.mail,
                  color: AppColors.resolveTextTertiary(context),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Password Field
            CupertinoTextField(
              controller: _passwordController,
              placeholder: 'Contraseña (mín. 6 caracteres)',
              obscureText: true,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.resolveImageBackground(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.resolveCardBorder(context),
                  width: 1,
                ),
              ),
              prefix: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(
                  CupertinoIcons.lock,
                  color: AppColors.resolveTextTertiary(context),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Confirm Password Field
            CupertinoTextField(
              controller: _confirmPasswordController,
              placeholder: 'Confirmar contraseña',
              obscureText: true,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.resolveImageBackground(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.resolveCardBorder(context),
                  width: 1,
                ),
              ),
              prefix: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(
                  CupertinoIcons.lock_fill,
                  color: AppColors.resolveTextTertiary(context),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Register Button
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: BorderRadius.circular(12),
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text(
                        'Crear Cuenta',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.white,
                        ),
                      ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
