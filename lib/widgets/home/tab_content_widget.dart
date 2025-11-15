import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../product_card.dart';
import '../product_card_compact.dart';
import '../../screens/product_detail_screen.dart';
import '../common/empty_state_widget.dart';
import '../common/gradient_button.dart';
import '../../screens/add_product_screen.dart';

/// Widget que muestra el contenido de una pestaña con lista de productos
class TabContentWidget extends StatefulWidget {
  final String filter;

  const TabContentWidget({
    super.key,
    required this.filter,
  });

  @override
  State<TabContentWidget> createState() => _TabContentWidgetState();
}

class _TabContentWidgetState extends State<TabContentWidget> with RouteAware {
  // Cache for favorite status to avoid repeated async calls
  final Map<String, bool> _favoriteCache = {};
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Clear cache when dependencies change (e.g., returning from another screen)
    _favoriteCache.clear();
  }

  Future<bool> _checkIfFavorite(ProductProvider provider, String productId) async {
    // Check cache first
    if (_favoriteCache.containsKey(productId)) {
      return _favoriteCache[productId]!;
    }
    
    // Check from provider
    final isFavorite = await provider.isProductInFavorites(productId);
    _favoriteCache[productId] = isFavorite;
    return isFavorite;
  }

  Future<void> _toggleFavorite(ProductProvider provider, Product product) async {
    final isFavorite = _favoriteCache[product.id] ?? false;
    
    if (isFavorite) {
      // Remove from favorites
      final success = await provider.removeProductFromFavorites(product.id);
      if (success && mounted) {
        setState(() {
          _favoriteCache[product.id] = false;
        });
      }
    } else {
      // Add to favorites
      final success = await provider.addProductToFavorites(product.id);
      if (success && mounted) {
        setState(() {
          _favoriteCache[product.id] = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.products.isEmpty) {
          return const Center(
            child: CupertinoActivityIndicator(radius: 15),
          );
        }

        final products = _getFilteredProducts(provider);

        if (products.isEmpty) {
          return _buildEmptyState(context);
        }

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = products[index];
                    final useCompactCard = widget.filter == 'discounts' || widget.filter == 'alerts';
                    final isExploreTab = widget.filter == 'explore';
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: useCompactCard
                          ? ProductCardCompact(
                              product: product,
                              showAlertBadge: widget.filter == 'alerts',
                              onTap: () {
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) => ProductDetailScreen(
                                      product: product,
                                      isFromExplore: false,
                                      canDelete: false, // No se puede eliminar desde Ofertas/Alertas
                                    ),
                                  ),
                                );
                              },
                            )
                          : isExploreTab
                              ? FutureBuilder<bool>(
                                  future: _checkIfFavorite(provider, product.id),
                                  builder: (context, snapshot) {
                                    final isFavorite = snapshot.data ?? false;
                                    return ProductCard(
                                      product: product,
                                      showFavoriteButton: true,
                                      isFavorite: isFavorite,
                                      onFavoriteToggle: () => _toggleFavorite(provider, product),
                                      onTap: () async {
                                        // Navigate to detail and clear cache when returning
                                        await Navigator.of(context).push(
                                          CupertinoPageRoute(
                                            builder: (context) => ProductDetailScreen(
                                              product: product,
                                              isFromExplore: true,
                                              canDelete: false,
                                            ),
                                          ),
                                        );
                                        // Clear cache for this product when returning
                                        if (mounted) {
                                          setState(() {
                                            _favoriteCache.remove(product.id);
                                          });
                                        }
                                      },
                                    );
                                  },
                                )
                              : ProductCard(
                                  product: product,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      CupertinoPageRoute(
                                        builder: (context) => ProductDetailScreen(
                                          product: product,
                                          isFromExplore: false,
                                          canDelete: widget.filter == 'favorites', // Solo se puede eliminar desde Favoritos
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    );
                  },
                  childCount: products.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Product> _getFilteredProducts(ProductProvider provider) {
    switch (widget.filter) {
      case 'explore':
        return provider.allSharedProducts;
      case 'favorites':
        return provider.products;
      case 'discounts':
        return provider.productsWithDiscounts;
      case 'alerts':
        return provider.productsWithAlerts;
      default:
        return provider.products;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final config = _getEmptyStateConfig();

    return EmptyStateWidget(
      icon: config['icon'] as IconData,
      title: config['title'] as String,
      subtitle: config['subtitle'] as String,
      action: widget.filter == 'favorites'
          ? GradientButton(
              text: 'Agregar Producto',
              icon: CupertinoIcons.add_circled,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  CupertinoPageRoute(
                    builder: (context) => const AddProductScreen(),
                    fullscreenDialog: true,
                  ),
                );
              },
            )
          : null,
    );
  }

  Map<String, dynamic> _getEmptyStateConfig() {
    switch (widget.filter) {
      case 'explore':
        return {
          'icon': CupertinoIcons.search,
          'title': 'No hay productos disponibles',
          'subtitle': 'Explora productos agregados por otros usuarios',
        };
      case 'favorites':
        return {
          'icon': CupertinoIcons.star_fill,
          'title': 'No tienes favoritos',
          'subtitle': 'Agrega productos a tus favoritos',
        };
      case 'discounts':
        return {
          'icon': CupertinoIcons.tag_fill,
          'title': 'No hay ofertas disponibles',
          'subtitle': 'Los productos aparecerán aquí',
        };
      case 'alerts':
        return {
          'icon': CupertinoIcons.bell_fill,
          'title': 'No hay alertas activas',
          'subtitle': 'Los productos aparecerán aquí',
        };
      default:
        return {
          'icon': CupertinoIcons.cube_box_fill,
          'title': 'No hay productos',
          'subtitle': 'Los productos aparecerán aquí',
        };
    }
  }
}
