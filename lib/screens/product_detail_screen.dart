import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../models/favorite_collection.dart';
import '../providers/product_provider.dart';
import '../config/app_colors.dart';
import '../widgets/interactive_price_chart.dart';
import '../widgets/common/custom_navigation_bar.dart';
import '../widgets/common/gradient_button.dart';
import '../widgets/product_detail/product_image_section.dart';
import '../widgets/product_detail/price_section.dart';
import '../widgets/product_detail/target_price_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final bool isFromExplore;
  final bool canDelete;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.isFromExplore = false,
    this.canDelete = true,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _targetPriceController = TextEditingController();
  bool? _isInFavorites;
  bool _isLoadingFavoriteStatus = true;

  @override
  void initState() {
    super.initState();
    if (widget.product.targetPrice != null) {
      _targetPriceController.text = widget.product.targetPrice.toString();
    }
    // Check if product is in favorites when coming from explore
    if (widget.isFromExplore) {
      _checkFavoriteStatus();
    } else {
      _isInFavorites = true; // Already in favorites if not from explore
      _isLoadingFavoriteStatus = false;
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final provider = context.read<ProductProvider>();
    final isFavorite = await provider.isProductInFavorites(widget.product.id);
    if (mounted) {
      setState(() {
        _isInFavorites = isFavorite;
        _isLoadingFavoriteStatus = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final provider = context.read<ProductProvider>();
    
    if (_isInFavorites == true) {
      // Remove from favorites
      final success = await provider.removeProductFromFavorites(widget.product.id);
      if (success && mounted) {
        setState(() {
          _isInFavorites = false;
        });
      }
    } else {
      // Add to favorites
      final success = await provider.addProductToFavorites(widget.product.id);
      if (success && mounted) {
        setState(() {
          _isInFavorites = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _targetPriceController.dispose();
    super.dispose();
  }

  Future<void> _openInAmazon() async {
    final uri = Uri.parse(widget.product.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDeleteConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Eliminar Producto'),
        content: const Text('¿Estás seguro de que deseas eliminar este producto?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              // Cerrar el diálogo primero
              Navigator.of(dialogContext).pop();
              
              // Guardar referencia al provider antes de operaciones async
              final provider = context.read<ProductProvider>();
              
              // Eliminar el producto
              await provider.deleteProduct(widget.product.id);
              
              // Verificar que el widget sigue montado antes de navegar
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionCard(BuildContext context, ProductProvider provider, Product currentProduct) {
    // Find the collection for this product
    FavoriteCollection? collection;
    if (currentProduct.collectionId != null && provider.collections.isNotEmpty) {
      try {
        collection = provider.collections.firstWhere(
          (c) => c.id == currentProduct.collectionId,
        );
      } catch (e) {
        // Collection not found, leave as null
        collection = null;
      }
    }
    
    final collectionName = collection?.name ?? 'Sin asignar';
    final collectionIcon = collection?.icon != null 
        ? _getCollectionIcon(collection!.icon)
        : CupertinoIcons.folder;
    final collectionColor = collection?.color != null
        ? _parseCollectionColor(collection!.color)
        : CupertinoColors.systemGrey;

    return GestureDetector(
      onTap: () => _showCollectionSelector(context, provider),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.resolveCardBackground(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.resolveSeparator(context),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (collection != null ? collectionColor : CupertinoColors.systemGrey)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                collectionIcon,
                color: collection != null ? collectionColor : CupertinoColors.systemGrey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Colección',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.resolveTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    collectionName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.resolveTextPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.resolveTextSecondary(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showCollectionSelector(BuildContext context, ProductProvider provider) {
    if (provider.collections.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('No hay colecciones'),
          content: const Text(
            'Crea una colección primero para poder asignar productos.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Asignar a Colección'),
        message: const Text('Selecciona una colección para este producto'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await provider.removeProductFromCollection(widget.product.id);
            },
            child: const Text('Sin colección'),
          ),
          ...provider.collections.map((collection) {
            return CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                await provider.addProductToCollection(
                  widget.product.id,
                  collection.id,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getCollectionIcon(collection.icon),
                    color: _parseCollectionColor(collection.color),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(collection.name),
                ],
              ),
            );
          }),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  IconData _getCollectionIcon(String? icon) {
    switch (icon) {
      case 'heart':
        return CupertinoIcons.heart_fill;
      case 'star':
        return CupertinoIcons.star_fill;
      case 'tag':
        return CupertinoIcons.tag_fill;
      case 'folder':
        return CupertinoIcons.folder_fill;
      default:
        return CupertinoIcons.heart_fill;
    }
  }

  Color _parseCollectionColor(String? hexColor) {
    if (hexColor == null) return AppColors.primaryBlue;
    final hex = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  void _showTargetPriceDialog() async {
    // If product is not in favorites, add it first
    if (_isInFavorites != true) {
      await _toggleFavorite();
      // Wait a bit for the UI to update
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    if (!mounted) return;
    
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 380,
        padding: const EdgeInsets.only(top: 6),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        CupertinoIcons.bell_fill,
                        color: AppColors.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Precio Objetivo',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Te notificaremos cuando alcance este precio',
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Current Price Info
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.tag_fill,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Precio Actual',
                          style: TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${widget.product.currentPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Input Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu Precio Objetivo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _targetPriceController,
                      placeholder: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Text(
                          '\$',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: CupertinoColors.systemGrey5.resolveFrom(context),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () async {
                          final price = double.tryParse(_targetPriceController.text);
                          if (price != null) {
                            // Cerrar el modal primero
                            Navigator.of(context).pop();
                            
                            // Luego actualizar precio objetivo
                            if (mounted) {
                              await this.context.read<ProductProvider>().updateTargetPrice(
                                widget.product.id,
                                price,
                              );
                            }
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.check_mark,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Guardar',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        // Obtener el producto actualizado del provider
        final updatedProduct = productProvider.products
            .firstWhere(
              (p) => p.id == widget.product.id,
              orElse: () => widget.product,
            );
        
        // Determine which trailing button to show
        Widget? trailingButton;
        if (widget.isFromExplore) {
          // Show favorite button when from explore
          if (!_isLoadingFavoriteStatus) {
            trailingButton = CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _toggleFavorite,
              child: Icon(
                _isInFavorites == true ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                color: _isInFavorites == true ? AppColors.alertRed : CupertinoColors.activeBlue,
                size: 26,
              ),
            );
          }
        } else if (widget.canDelete) {
          // Show delete button when can delete
          trailingButton = CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showDeleteConfirmation,
            child: const Icon(
              CupertinoIcons.trash,
              color: AppColors.alertRed,
              size: 22,
            ),
          );
        }
        
        return CupertinoPageScaffold(
          navigationBar: CustomNavigationBar(
            context: context,
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.of(context).pop(),
              child: const Icon(
                CupertinoIcons.back,
                size: 28,
              ),
            ),
            trailing: trailingButton,
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // Product Image
                ProductImageSection(imageUrl: updatedProduct.imageUrl),
                const SizedBox(height: 20),
                // Product Title
                Text(
                  updatedProduct.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: AppColors.resolveTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),
                // Price Section
                PriceSection(
                  currentPrice: updatedProduct.currentPrice,
                  originalPrice: updatedProduct.originalPrice,
                  hasDiscount: updatedProduct.hasDiscount,
                  discountPercentage: updatedProduct.discountPercentage,
                ),
                const SizedBox(height: 16),
                // Action Button
                GradientButton(
                  text: 'Ver en Amazon',
                  icon: CupertinoIcons.cart_fill,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  onPressed: _openInAmazon,
                ),
                const SizedBox(height: 20),
                // Target Price Section
                TargetPriceCard(
                  targetPrice: updatedProduct.targetPrice,
                  onTap: _showTargetPriceDialog,
                ),
                const SizedBox(height: 16),
                // Collection Assignment - Show if in favorites (either from favorites tab or added from explore)
                if (_isInFavorites == true)
                  _buildCollectionCard(context, productProvider, updatedProduct),
                if (_isInFavorites == true)
                  const SizedBox(height: 24),
                // Price History Chart
                if (updatedProduct.priceHistory.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.chart_bar_fill,
                          size: 20,
                          color: AppColors.resolveTextSecondary(context),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Historial de Precios',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  InteractivePriceChart(
                    priceHistory: updatedProduct.priceHistory,
                    targetPrice: updatedProduct.targetPrice,
                    currentPrice: updatedProduct.currentPrice,
                    originalPrice: updatedProduct.originalPrice,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
