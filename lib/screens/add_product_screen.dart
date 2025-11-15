import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../config/app_colors.dart';
import '../widgets/common/custom_navigation_bar.dart';
import '../widgets/add_product/info_card.dart';
import '../widgets/add_product/url_input_field.dart';
import '../widgets/add_product/price_input_field.dart';
import '../widgets/add_product/loading_overlay.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _urlController = TextEditingController();
  final _targetPriceController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _urlController.dispose();
    _targetPriceController.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    if (_urlController.text.trim().isEmpty) {
      _showAlert('Error', 'Por favor ingresa una URL de Amazon');
      return;
    }

    if (!_isValidAmazonUrl(_urlController.text.trim())) {
      _showAlert('URL Inválida', 
          'Por favor ingresa una URL válida de Amazon.com\n\nEjemplos:\n• https://www.amazon.com/dp/B08N5WRWNW\n• https://a.co/d/73v020J');
      return;
    }

    // Ocultar el teclado
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final targetPrice = _targetPriceController.text.trim().isNotEmpty
        ? double.tryParse(_targetPriceController.text.trim())
        : null;

    final success = await context.read<ProductProvider>().addProduct(
          _urlController.text.trim(),
          targetPrice: targetPrice,
        );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      _showSuccessAlert();
    } else {
      final error = context.read<ProductProvider>().error;
      _showAlert('Error', error ?? 'No se pudo agregar el producto');
    }
  }

  bool _isValidAmazonUrl(String url) {
    return url.contains('amazon.com') || 
           url.contains('a.co') || 
           url.contains('amzn.to');
  }

  void _showAlert(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
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

  void _showSuccessAlert() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('¡Éxito!'),
        content: const Text('Producto agregado correctamente'),
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
      navigationBar: CustomNavigationBar(
        context: context,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: _isLoading ? AppColors.resolveTextTertiary(context) : null,
            ),
          ),
        ),
        middle: const Text(
          'Agregar Producto',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : _addProduct,
          child: Text(
            'Agregar',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _isLoading ? AppColors.resolveTextTertiary(context) : null,
            ),
          ),
        ),
      ),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 20),
                  // Info Card
                  const InfoCard(
                    icon: CupertinoIcons.info_circle_fill,
                    title: 'Productos de Amazon.com',
                    subtitle: 'Soporta URLs completas y cortas (a.co)',
                  ),
                  const SizedBox(height: 32),
                  // URL Input
                  UrlInputField(
                    controller: _urlController,
                    label: 'URL DEL PRODUCTO',
                    placeholder: 'https://www.amazon.com/dp/...',
                    prefixIcon: CupertinoIcons.link,
                  ),
                  const SizedBox(height: 24),
                  // Target Price Input
                  PriceInputField(
                    controller: _targetPriceController,
                    label: 'PRECIO OBJETIVO (OPCIONAL)',
                    placeholder: '0.00',
                    helpText: 'Recibirás una alerta cuando el precio alcance este valor',
                  ),
                  const SizedBox(height: 32),
                  // Examples Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.resolveImageBackground(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.resolveCardBorder(context),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.lightbulb,
                              size: 18,
                              color: AppColors.resolveTextSecondary(context),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Ejemplos de URLs válidas',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildExampleUrl('https://www.amazon.com/dp/B08N5WRWNW'),
                        const SizedBox(height: 8),
                        _buildExampleUrl('https://a.co/d/73v020J'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Loading Overlay
          if (_isLoading)
            const LoadingOverlay(
              title: 'Agregando producto...',
              subtitle: 'Obteniendo información de Amazon',
            ),
        ],
      ),
    );
  }

  Widget _buildExampleUrl(String url) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.resolveCardBackground(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.resolveCardBorder(context),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.checkmark_circle_fill,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              url,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Courier',
                color: AppColors.resolveTextTertiary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
