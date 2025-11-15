import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_colors.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
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
        middle: const Text('Iniciar Sesión'),
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
            const SizedBox(height: 40),
            // Logo or App Name
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.chart_bar_circle_fill,
                size: 50,
                color: CupertinoColors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Amazon Tracker',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.resolveTextPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rastrea precios globalmente',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.resolveTextSecondary(context),
              ),
            ),
            const SizedBox(height: 48),
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
              placeholder: 'Contraseña',
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
            const SizedBox(height: 24),
            // Login Button
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
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // Register Link
            CupertinoButton(
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text(
                '¿No tienes cuenta? Regístrate',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
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
