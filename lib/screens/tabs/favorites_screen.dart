import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/favorite_collection.dart';
import '../../models/product.dart';
import '../../config/app_colors.dart';
import '../../widgets/product_card.dart';
import '../../widgets/common/search_bar_widget.dart';
import '../add_product_screen.dart';
import '../product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String? _selectedCollectionId; // null = todos, 'uncategorized' = sin colección
  final TextEditingController _collectionNameController = TextEditingController();
  final TextEditingController _collectionDescController = TextEditingController();
  List<Product> _filteredProducts = [];
  bool _isLoadingFiltered = false;

  @override
  void dispose() {
    _collectionNameController.dispose();
    _collectionDescController.dispose();
    super.dispose();
  }

  Future<void> _loadFilteredProducts(ProductProvider provider) async {
    setState(() => _isLoadingFiltered = true);
    
    List<Product> products;
    if (_selectedCollectionId == null) {
      products = provider.products; // Todos
    } else if (_selectedCollectionId == 'uncategorized') {
      products = await provider.getProductsWithoutCollection();
    } else {
      products = await provider.getProductsByCollection(_selectedCollectionId!);
    }
    
    setState(() {
      _filteredProducts = products;
      _isLoadingFiltered = false;
    });
  }

  void _onCollectionSelected(String? collectionId, ProductProvider provider) {
    setState(() => _selectedCollectionId = collectionId);
    _loadFilteredProducts(provider);
  }

  void _showCreateCollectionDialog() {
    _collectionNameController.clear();
    _collectionDescController.clear();
    
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 420,
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
                        CupertinoIcons.folder_fill_badge_plus,
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
                            'Nueva Colección',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Organiza tus favoritos en grupos',
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
              
              // Input Fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nombre de la Colección',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _collectionNameController,
                      placeholder: 'Ej: Trabajo, Personal, Deseos...',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Descripción (Opcional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _collectionDescController,
                      placeholder: 'Agrega una descripción...',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      maxLines: 2,
                      decoration: BoxDecoration(
                        color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                        borderRadius: BorderRadius.circular(12),
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
                          if (_collectionNameController.text.trim().isEmpty) return;
                          
                          // Cerrar el modal primero
                          Navigator.of(context).pop();
                          
                          // Luego crear la colección
                          if (mounted) {
                            final provider = context.read<ProductProvider>();
                            await provider.createCollection(
                              name: _collectionNameController.text.trim(),
                              description: _collectionDescController.text.trim().isEmpty 
                                  ? null 
                                  : _collectionDescController.text.trim(),
                            );
                          }
                        },
                        child: const Text(
                          'Crear Colección',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
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

  void _showCollectionOptions(FavoriteCollection collection) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(collection.name),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showEditCollectionDialog(collection);
            },
            child: const Text('Editar'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(collection);
            },
            child: const Text('Eliminar'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  void _showEditCollectionDialog(FavoriteCollection collection) {
    _collectionNameController.text = collection.name;
    _collectionDescController.text = collection.description ?? '';
    
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 420,
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
                        CupertinoIcons.pencil,
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
                            'Editar Colección',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Actualiza el nombre y descripción',
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
              
              // Input Fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nombre de la Colección',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _collectionNameController,
                      placeholder: 'Nombre de la colección',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Descripción (Opcional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _collectionDescController,
                      placeholder: 'Descripción',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      maxLines: 2,
                      decoration: BoxDecoration(
                        color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                        borderRadius: BorderRadius.circular(12),
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
                          if (_collectionNameController.text.trim().isEmpty) return;
                          
                          // Cerrar el modal primero
                          Navigator.of(context).pop();
                          
                          // Luego actualizar la colección
                          if (mounted) {
                            final provider = context.read<ProductProvider>();
                            await provider.updateCollection(
                              collection.id,
                              name: _collectionNameController.text.trim(),
                              description: _collectionDescController.text.trim().isEmpty 
                                  ? null 
                                  : _collectionDescController.text.trim(),
                            );
                          }
                        },
                        child: const Text(
                          'Guardar Cambios',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
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

  void _showDeleteConfirmation(FavoriteCollection collection) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Eliminar Colección'),
        content: Text('¿Eliminar "${collection.name}"? Los productos no se eliminarán.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<ProductProvider>();
              await provider.deleteCollection(collection.id);
              if (_selectedCollectionId == collection.id) {
                setState(() => _selectedCollectionId = null);
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Mis Favoritos'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).push(
              CupertinoPageRoute(
                builder: (context) => const AddProductScreen(),
              ),
            );
          },
          child: const Icon(
            CupertinoIcons.add_circled,
            size: 24,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
      child: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          // Load filtered products when provider changes
          if (_selectedCollectionId == null && _filteredProducts.isEmpty && provider.products.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadFilteredProducts(provider);
            });
          }
          
          final displayProducts = _selectedCollectionId == null && !_isLoadingFiltered
              ? provider.products
              : _filteredProducts;
          
          return Column(
            children: [
              // Barra de búsqueda
              const SearchBarWidget(placeholder: 'Buscar en favoritos...'),
              
              // Colecciones como chips horizontales - Siempre visible
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Chip "Todos"
                    _buildCollectionChip(
                      label: 'Todos',
                      icon: CupertinoIcons.square_grid_2x2,
                      isSelected: _selectedCollectionId == null,
                      onTap: () => _onCollectionSelected(null, provider),
                    ),
                    const SizedBox(width: 8),
                    // Chip "Sin categoría"
                    _buildCollectionChip(
                      label: 'Sin categoría',
                      icon: CupertinoIcons.tray,
                      isSelected: _selectedCollectionId == 'uncategorized',
                      onTap: () => _onCollectionSelected('uncategorized', provider),
                    ),
                    // Chips de colecciones (solo si existen)
                    if (provider.collections.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      ...provider.collections.map((collection) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildCollectionChip(
                            label: collection.name,
                            icon: CupertinoIcons.folder_fill,
                            isSelected: _selectedCollectionId == collection.id,
                            onTap: () => _onCollectionSelected(collection.id, provider),
                            onLongPress: () => _showCollectionOptions(collection),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(width: 8),
                    // Botón para crear nueva colección
                    _buildCollectionChip(
                      label: 'Nueva',
                      icon: CupertinoIcons.add,
                      isSelected: false,
                      onTap: _showCreateCollectionDialog,
                      isAddButton: true,
                    ),
                  ],
                ),
              ),
              
              // Lista de productos
              Expanded(
                child: provider.isLoading || _isLoadingFiltered
                    ? const Center(child: CupertinoActivityIndicator())
                    : displayProducts.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: displayProducts.length,
                            itemBuilder: (context, index) {
                              final product = displayProducts[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ProductCard(
                                  product: product,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) => ProductDetailScreen(product: product),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCollectionChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    bool isAddButton = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue
              : isAddButton
                  ? AppColors.primaryBlue.withOpacity(0.1)
                  : CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(16),
          border: isAddButton
              ? Border.all(color: AppColors.primaryBlue, width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? CupertinoColors.white
                  : isAddButton
                      ? AppColors.primaryBlue
                      : CupertinoColors.label.resolveFrom(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? CupertinoColors.white
                    : isAddButton
                        ? AppColors.primaryBlue
                        : CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedCollectionId == null
                ? CupertinoIcons.heart
                : CupertinoIcons.folder,
            size: 80,
            color: CupertinoColors.systemGrey.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedCollectionId == null
                ? 'No tienes favoritos'
                : 'No hay productos en esta colección',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCollectionId == null
                ? 'Agrega productos para empezar a seguir precios'
                : 'Asigna productos desde el detalle del producto',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
