import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/favorite_collection.dart';
import '../services/database_service.dart';
import '../services/supabase_database_service.dart';
import '../services/amazon_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = []; // User favorites
  List<Product> _allSharedProducts = []; // All products in shared DB
  List<FavoriteCollection> _collections = []; // User collections
  bool _isLoading = false;
  String? _error;
  String _searchQuery = ''; // Search query

  final DatabaseService _dbService = DatabaseService.instance;
  final SupabaseDatabaseService _supabaseDbService = SupabaseDatabaseService();
  final AmazonService _amazonService = AmazonService();
  
  // Flag to use Supabase instead of local SQLite
  final bool _useSupabase = true;
  
  // Realtime subscriptions
  RealtimeChannel? _productsChannel;
  RealtimeChannel? _favoritesChannel;
  RealtimeChannel? _priceHistoryChannel;

  // User's favorite products (with tracking)
  List<Product> get products => _filterBySearch(_products);
  
  // All products in shared database (for explore tab)
  List<Product> get allSharedProducts => _filterBySearch(_allSharedProducts);
  
  // User collections
  List<FavoriteCollection> get collections => _collections;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  
  // Filter products by search query
  List<Product> _filterBySearch(List<Product> productList) {
    if (_searchQuery.isEmpty) return productList;
    
    final query = _searchQuery.toLowerCase();
    return productList.where((product) {
      return product.title.toLowerCase().contains(query);
    }).toList();
  }
  
  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  // Clear search query
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  List<Product> get trackedProducts =>
      _products.where((p) => p.isTracking).toList();

  List<Product> get productsWithDiscounts =>
      _products.where((p) => p.hasDiscount).toList();

  List<Product> get productsAtTargetPrice =>
      _products.where((p) => p.isPriceAtTarget).toList();
  
  List<Product> get productsWithAlerts =>
      _products.where((p) => p.isPriceAtTarget).toList();

  /// Load user's favorite products (with tracking)
  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use Supabase if enabled, otherwise use local SQLite
      _products = _useSupabase 
          ? await _supabaseDbService.getAllProducts()
          : await _dbService.getAllProducts();
      
      // Load price history for each product
      for (var i = 0; i < _products.length; i++) {
        final history = _useSupabase
            ? await _supabaseDbService.getPriceHistory(_products[i].id)
            : await _dbService.getPriceHistory(_products[i].id);
        _products[i] = _products[i].copyWith(priceHistory: history);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load ALL products from shared database (for explore tab)
  Future<void> loadAllSharedProducts() async {
    if (!_useSupabase) {
      // If not using Supabase, just show user's products
      _allSharedProducts = _products;
      notifyListeners();
      return;
    }

    try {
      print('📦 Loading all shared products...');
      _allSharedProducts = await _supabaseDbService.getAllSharedProducts(limit: 100);
      print('✅ Loaded ${_allSharedProducts.length} shared products');
      
      // Load price history for each product
      for (var i = 0; i < _allSharedProducts.length; i++) {
        try {
          final history = await _supabaseDbService.getPriceHistory(_allSharedProducts[i].id);
          _allSharedProducts[i] = _allSharedProducts[i].copyWith(priceHistory: history);
        } catch (e) {
          print('❌ Error loading history for product ${_allSharedProducts[i].title}: $e');
        }
      }
      
      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ Error loading shared products: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Initialize realtime subscriptions for automatic updates
  void initializeRealtimeSubscriptions() {
    if (!_useSupabase) return;

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    
    if (userId == null) {
      print('⚠️  Cannot initialize realtime: User not authenticated');
      return;
    }

    print('🔴 Initializing realtime subscriptions...');

    // Subscribe to products table (shared products)
    _productsChannel = supabase
        .channel('products-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          callback: (payload) {
            print('📦 Products table changed: ${payload.eventType}');
            _handleProductsChange(payload);
          },
        )
        .subscribe();

    // Subscribe to user_favorites table (user's favorites)
    _favoritesChannel = supabase
        .channel('favorites-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_favorites',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            print('⭐ Favorites table changed: ${payload.eventType}');
            _handleFavoritesChange(payload);
          },
        )
        .subscribe();

    // Subscribe to price_history table
    _priceHistoryChannel = supabase
        .channel('price-history-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'price_history',
          callback: (payload) {
            print('📊 Price history updated');
            _handlePriceHistoryChange(payload);
          },
        )
        .subscribe();

    print('✅ Realtime subscriptions initialized');
  }

  /// Handle changes in products table
  void _handleProductsChange(PostgresChangePayload payload) async {
    try {
      print('📦 Products table change: ${payload.eventType}');
      
      // If a product was deleted, remove it from local lists immediately
      if (payload.eventType == PostgresChangeEvent.delete) {
        final deletedId = payload.oldRecord['id'] as String?;
        if (deletedId != null) {
          print('🗑️ Product deleted: $deletedId, removing from local lists...');
          _products.removeWhere((p) => p.id == deletedId);
          _allSharedProducts.removeWhere((p) => p.id == deletedId);
          notifyListeners();
          print('✅ Product removed from local lists');
        }
      }
      
      // Reload both shared products and user favorites
      // (favorites might include products that were updated)
      await Future.wait([
        loadAllSharedProducts(),
        loadProducts(),
      ]);
      print('✅ All products reloaded after products table change');
    } catch (e) {
      print('❌ Error handling products change: $e');
    }
  }

  /// Handle changes in user_favorites table
  void _handleFavoritesChange(PostgresChangePayload payload) async {
    try {
      print('⭐ Favorites table change: ${payload.eventType}');
      
      // If a favorite was deleted, remove it from local list immediately
      if (payload.eventType == PostgresChangeEvent.delete) {
        final deletedProductId = payload.oldRecord['product_id'] as String?;
        if (deletedProductId != null) {
          print('🗑️ Favorite deleted: $deletedProductId, removing from local list...');
          _products.removeWhere((p) => p.id == deletedProductId);
          notifyListeners();
          print('✅ Favorite removed from local list');
        }
      }
      
      // Reload user's favorites when their favorites change
      await loadProducts();
      print('✅ User favorites reloaded');
    } catch (e) {
      print('❌ Error handling favorites change: $e');
    }
  }

  /// Handle changes in price_history table
  void _handlePriceHistoryChange(PostgresChangePayload payload) async {
    try {
      print('📊 Price history change detected, reloading all data...');
      // Reload both user favorites and shared products to get updated prices
      await Future.wait([
        loadProducts(),
        loadAllSharedProducts(),
      ]);
      print('✅ All products reloaded with updated price history');
    } catch (e) {
      print('❌ Error handling price history change: $e');
    }
  }

  /// Dispose realtime subscriptions
  void disposeRealtimeSubscriptions() {
    print('🔴 Disposing realtime subscriptions...');
    _productsChannel?.unsubscribe();
    _favoritesChannel?.unsubscribe();
    _priceHistoryChannel?.unsubscribe();
    _productsChannel = null;
    _favoritesChannel = null;
    _priceHistoryChannel = null;
  }

  @override
  void dispose() {
    disposeRealtimeSubscriptions();
    super.dispose();
  }

  Future<bool> addProduct(String url, {double? targetPrice}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Resolve short URLs first (follow redirects)
      String resolvedUrl = url;
      if (url.contains('a.co') || url.contains('amzn.to')) {
        print('🔗 Resolving short URL...');
        resolvedUrl = await _resolveShortUrl(url);
        print('✅ Resolved to: $resolvedUrl');
      }
      
      // Intentar scraping local primero
      Product? product;
      print('🔍 Trying local Amazon scraping...');
      product = await _amazonService.fetchProductData(resolvedUrl);
      
      // Si falla el scraping local O el precio es 0, usar Edge Function
      if (product == null || product.currentPrice == 0) {
        if (product != null && product.currentPrice == 0) {
          print('⚠️ Local scraping returned \$0, trying Edge Function...');
        } else {
          print('⚠️ Local scraping failed, trying Edge Function...');
        }
        
        product = await _addProductViaEdgeFunction(resolvedUrl, targetPrice);
        
        if (product == null || product.currentPrice == 0) {
          _error = 'No se pudo obtener los datos del producto.\n\nEl producto se agregará pero necesitarás esperar a que el cron job actualice los datos (30 minutos).';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
        // Si la Edge Function funcionó, recargar productos y retornar
        await loadProducts();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      if (targetPrice != null) {
        product = product.copyWith(targetPrice: targetPrice);
      }

      // Save to Supabase or local SQLite
      if (_useSupabase) {
        // Insert product to shared database (or get existing)
        final savedProduct = await _supabaseDbService.insertProduct(product);
        
        // Add to user favorites with target price
        await _supabaseDbService.addToFavorites(
          savedProduct.id,
          targetPrice: targetPrice,
        );
        
        // Save all price history points (min, max, current) from Amazon
        if (product.priceHistory.isNotEmpty) {
          for (var history in product.priceHistory) {
            await _supabaseDbService.insertPriceHistory(history);
          }
        } else {
          // Fallback: if no history, add current price point
          final history = PriceHistory(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            productId: savedProduct.id,
            price: product.currentPrice,
            timestamp: DateTime.now(),
          );
          await _supabaseDbService.insertPriceHistory(history);
        }
      } else {
        await _dbService.insertProduct(product);
        
        // Save all price history points (min, max, current) from Amazon
        if (product.priceHistory.isNotEmpty) {
          for (var history in product.priceHistory) {
            await _dbService.insertPriceHistory(history);
          }
        } else {
          // Fallback: if no history, add current price point
          final history = PriceHistory(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            productId: product.id,
            price: product.currentPrice,
            timestamp: DateTime.now(),
          );
          await _dbService.insertPriceHistory(history);
        }
      }

      await loadProducts();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      if (_useSupabase) {
        await _supabaseDbService.updateProduct(product);
      } else {
        await _dbService.updateProduct(product);
      }
      await loadProducts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      if (_useSupabase) {
        await _supabaseDbService.deleteProduct(id);
      } else {
        await _dbService.deleteProduct(id);
      }
      await loadProducts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> setTargetPrice(String productId, double? targetPrice) async {
    try {
      // Obtener el producto actual
      final product = _products.firstWhere((p) => p.id == productId);
      
      if (_useSupabase) {
        // Update favorite settings in Supabase
        await _supabaseDbService.updateFavorite(
          productId,
          targetPrice: targetPrice,
        );
        
        // 🆕 Verificar inmediatamente si el precio actual ya alcanzó el objetivo
        if (targetPrice != null && product.currentPrice <= targetPrice) {
          print('🎯 ¡Precio objetivo alcanzado inmediatamente! Target: \$${targetPrice}, Actual: \$${product.currentPrice}');
          
          try {
            final userId = Supabase.instance.client.auth.currentUser?.id;
            if (userId != null) {
              // Verificar si ya existe una alerta reciente (últimas 24 horas)
              final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();
              final existingAlerts = await Supabase.instance.client
                  .from('price_alerts')
                  .select()
                  .eq('user_id', userId)
                  .eq('product_id', productId)
                  .gte('created_at', twentyFourHoursAgo);
              
              if (existingAlerts.isEmpty) {
                // Crear alerta inmediatamente
                await Supabase.instance.client.from('price_alerts').insert({
                  'user_id': userId,
                  'product_id': productId,
                  'target_price': targetPrice,
                  'current_price': product.currentPrice,
                  'notified': false,
                  'created_at': DateTime.now().toIso8601String(),
                });
                print('✅ Alerta creada inmediatamente');
                
                // Llamar a send-price-alert Edge Function
                await Supabase.instance.client.functions.invoke('send-price-alert');
                print('📬 Notificación enviada inmediatamente');
              } else {
                print('ℹ️ Ya existe una alerta reciente para este producto');
              }
            }
          } catch (e) {
            print('❌ Error creando alerta inmediata: $e');
          }
        }
      } else {
        // Update product in local SQLite
        final updatedProduct = product.copyWith(targetPrice: targetPrice);
        await _dbService.updateProduct(updatedProduct);
      }
      await loadProducts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> updateTargetPrice(String productId, double? targetPrice) async {
    await setTargetPrice(productId, targetPrice);
  }

  Future<void> toggleTracking(String productId) async {
    try {
      final product = _products.firstWhere((p) => p.id == productId);
      
      if (_useSupabase) {
        // Update favorite settings in Supabase
        await _supabaseDbService.updateFavorite(
          productId,
          isTracking: !product.isTracking,
        );
      } else {
        // Update product in local SQLite
        final updatedProduct = product.copyWith(isTracking: !product.isTracking);
        await _dbService.updateProduct(updatedProduct);
      }
      await loadProducts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Actualiza los precios de todos los productos
  /// La app automáticamente:
  /// 1. Consulta el precio actual en Amazon
  /// 2. Si cambió, actualiza el precio en la base de datos
  /// 3. Agrega una entrada al historial de precios
  /// 4. El historial permite calcular: precio mínimo, máximo y tendencias
  Future<void> refreshPrices() async {
    _isLoading = true;
    notifyListeners();

    try {
      int updatedCount = 0;
      int errorCount = 0;
      
      for (var product in _products) {
        try {
          // Consultar precio actual en Amazon
          Product? updatedProduct = await _amazonService.fetchProductData(product.url);

          // Si el scraping local falla o retorna $0, skip (será actualizado por cron job)
          if (updatedProduct == null || updatedProduct.currentPrice == 0) {
            print('⚠️ Local scraping failed for ${product.title}, will be updated by cron job');
            errorCount++;
            continue;
          }

          // Verificar que la moneda sea la misma (evitar mezclar USD con otras)
          if (updatedProduct.currency != product.currency) {
            print('⚠️  Currency mismatch for ${product.title}');
            print('   Expected: ${product.currency}, Got: ${updatedProduct.currency}');
            print('   Skipping update to prevent data corruption');
            errorCount++;
            continue;
          }
          
          // Solo actualizar si el precio cambió
          if (updatedProduct.currentPrice != product.currentPrice) {
            print('💰 Precio cambió: ${product.currentPrice} → ${updatedProduct.currentPrice} ${product.currency}');
            
            // Actualizar producto con nuevo precio
            final updated = product.copyWith(
              currentPrice: updatedProduct.currentPrice,
              originalPrice: updatedProduct.originalPrice,
              lastUpdated: DateTime.now(),
            );
            
            if (_useSupabase) {
              // Actualizar precio en base de datos compartida
              await _supabaseDbService.updateProduct(updated);
              
              // Agregar entrada al historial (automático)
              final history = PriceHistory(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                productId: product.id,
                price: updatedProduct.currentPrice,
                timestamp: DateTime.now(),
              );
              await _supabaseDbService.insertPriceHistory(history);
              print('📊 Historial actualizado');
              
              // 🆕 Verificar si alcanzó el precio objetivo
              if (product.targetPrice != null && updatedProduct.currentPrice <= product.targetPrice!) {
                print('🎯 ¡Precio objetivo alcanzado! Target: \$${product.targetPrice}, Actual: \$${updatedProduct.currentPrice}');
                
                try {
                  final userId = Supabase.instance.client.auth.currentUser?.id;
                  if (userId != null) {
                    // Verificar si ya existe una alerta reciente (últimas 24 horas)
                    final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();
                    final existingAlerts = await Supabase.instance.client
                        .from('price_alerts')
                        .select()
                        .eq('user_id', userId)
                        .eq('product_id', product.id)
                        .gte('created_at', twentyFourHoursAgo);
                    
                    if (existingAlerts.isEmpty) {
                      // Crear alerta solo si no existe una en las últimas 24 horas
                      await Supabase.instance.client.from('price_alerts').insert({
                        'user_id': userId,
                        'product_id': product.id,
                        'target_price': product.targetPrice,
                        'current_price': updatedProduct.currentPrice,
                        'notified': false,
                        'created_at': DateTime.now().toIso8601String(),
                      });
                      print('✅ Alerta creada en price_alerts');
                      
                      // Llamar a send-price-alert Edge Function
                      await Supabase.instance.client.functions.invoke('send-price-alert');
                      print('📬 Notificación enviada');
                    } else {
                      print('ℹ️ Ya se envió una alerta en las últimas 24 horas para este producto');
                    }
                  }
                } catch (e) {
                  print('❌ Error creando alerta: $e');
                }
              }
            } else {
              await _dbService.updateProduct(updated);
              
              // Agregar entrada al historial (local)
              final history = PriceHistory(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                productId: product.id,
                price: updatedProduct.currentPrice,
                timestamp: DateTime.now(),
              );
              await _dbService.insertPriceHistory(history);
            }
            
            updatedCount++;
          } else {
            print('✓ Precio sin cambios: ${product.title} - \$${product.currentPrice}');
            
            // 🆕 Verificar precio objetivo incluso si no cambió
            if (_useSupabase && product.targetPrice != null && product.currentPrice <= product.targetPrice!) {
              print('🎯 ¡Precio objetivo alcanzado! Target: \$${product.targetPrice}, Actual: \$${product.currentPrice}');
              
              try {
                final userId = Supabase.instance.client.auth.currentUser?.id;
                if (userId != null) {
                  // Verificar si ya existe una alerta reciente (últimas 24 horas)
                  final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();
                  final existingAlerts = await Supabase.instance.client
                      .from('price_alerts')
                      .select()
                      .eq('user_id', userId)
                      .eq('product_id', product.id)
                      .gte('created_at', twentyFourHoursAgo);
                  
                  if (existingAlerts.isEmpty) {
                    // Crear alerta solo si no existe una en las últimas 24 horas
                    await Supabase.instance.client.from('price_alerts').insert({
                      'user_id': userId,
                      'product_id': product.id,
                      'target_price': product.targetPrice,
                      'current_price': product.currentPrice,
                      'notified': false,
                      'created_at': DateTime.now().toIso8601String(),
                    });
                    print('✅ Alerta creada en price_alerts');
                    
                    // Llamar a send-price-alert Edge Function
                    await Supabase.instance.client.functions.invoke('send-price-alert');
                    print('📬 Notificación enviada');
                  } else {
                    print('ℹ️ Ya se envió una alerta en las últimas 24 horas para este producto');
                  }
                }
              } catch (e) {
                print('❌ Error creando alerta: $e');
              }
            }
          }
        } catch (e) {
          print('❌ Error updating ${product.title}: $e');
          errorCount++;
        }
      }

      print('✅ Actualización completa: $updatedCount productos actualizados, $errorCount errores');
      
      // Recargar productos desde la base de datos para reflejar cambios
      await loadProducts();
      
      // También recargar productos compartidos si estamos en Supabase
      if (_useSupabase) {
        await loadAllSharedProducts();
      }
      
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Resolve short Amazon URLs by following redirects
  Future<String> _resolveShortUrl(String shortUrl) async {
    try {
      String currentUrl = shortUrl;
      int maxRedirects = 10; // Follow up to 10 redirects
      int redirectCount = 0;
      
      final client = http.Client();
      
      // Keep following redirects until we get a full amazon.com URL
      while ((currentUrl.contains('a.co') || currentUrl.contains('amzn.to')) && redirectCount < maxRedirects) {
        print('🔄 Following redirect #${redirectCount + 1}: $currentUrl');
        
        try {
          final request = http.Request('GET', Uri.parse(currentUrl));
          request.followRedirects = false; // We'll handle redirects manually
          request.headers.addAll({
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          });
          
          final streamedResponse = await client.send(request);
          final response = await http.Response.fromStream(streamedResponse);
          
          // Check for redirect status codes (301, 302, 303, 307, 308)
          if (response.statusCode >= 300 && response.statusCode < 400) {
            final location = response.headers['location'];
            if (location != null && location.isNotEmpty) {
              // Handle relative URLs
              if (location.startsWith('http')) {
                currentUrl = location;
              } else {
                final uri = Uri.parse(currentUrl);
                currentUrl = '${uri.scheme}://${uri.host}$location';
              }
              print('   → Redirecting to: $currentUrl');
            } else {
              print('   ⚠️ No location header found');
              break;
            }
          } else {
            // Not a redirect, check if we got the final URL from the request
            final finalUrl = streamedResponse.request?.url.toString() ?? currentUrl;
            if (finalUrl.contains('amazon.com')) {
              currentUrl = finalUrl;
              break;
            }
            break;
          }
        } catch (e) {
          print('   ⚠️ Error in redirect: $e');
          break;
        }
        
        redirectCount++;
        
        // If we reached a full amazon.com URL, stop
        if (currentUrl.contains('amazon.com')) {
          break;
        }
      }
      
      client.close();
      print('✅ Final resolved URL: $currentUrl');
      return currentUrl;
    } catch (e) {
      print('❌ Error resolving short URL: $e');
      return shortUrl; // Return original URL if resolution fails
    }
  }

  /// Agregar producto usando Edge Function (fallback cuando scraping local falla)
  Future<Product?> _addProductViaEdgeFunction(String url, double? targetPrice) async {
    try {
      final supabase = Supabase.instance.client;
      
      print('🌐 Calling add-product Edge Function...');
      
      final response = await supabase.functions.invoke(
        'add-product',
        body: {
          'url': url,
          'targetPrice': targetPrice,
        },
      );
      
      if (response.data == null || response.data['success'] != true) {
        print('❌ Edge Function failed: ${response.data}');
        return null;
      }
      
      print('✅ Product added via Edge Function');
      
      // Convertir respuesta a Product
      final productData = response.data['product'];
      return Product(
        id: productData['id'],
        asin: productData['asin'],
        title: productData['title'],
        url: productData['url'],
        currentPrice: (productData['current_price'] as num).toDouble(),
        originalPrice: (productData['original_price'] as num?)?.toDouble(),
        imageUrl: productData['image_url'],
        currency: productData['currency'] ?? 'USD',
        targetPrice: targetPrice,
        isTracking: true,
        lastUpdated: DateTime.now(),
        priceHistory: [],
      );
    } catch (e) {
      print('❌ Error calling Edge Function: $e');
      return null;
    }
  }

  // ==================== COLLECTIONS METHODS ====================

  /// Load user's collections
  Future<void> loadCollections() async {
    if (!_useSupabase) return;

    try {
      _collections = await _supabaseDbService.getCollections();
      notifyListeners();
    } catch (e) {
      print('❌ Error loading collections: $e');
    }
  }

  /// Create a new collection
  Future<FavoriteCollection?> createCollection({
    required String name,
    String? description,
    String? icon,
    String? color,
  }) async {
    if (!_useSupabase) return null;

    try {
      final collection = await _supabaseDbService.createCollection(
        name: name,
        description: description,
        icon: icon,
        color: color,
      );
      await loadCollections();
      return collection;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update a collection
  Future<void> updateCollection(
    String collectionId, {
    String? name,
    String? description,
    String? icon,
    String? color,
  }) async {
    if (!_useSupabase) return;

    try {
      await _supabaseDbService.updateCollection(
        collectionId,
        name: name,
        description: description,
        icon: icon,
        color: color,
      );
      await loadCollections();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete a collection
  Future<void> deleteCollection(String collectionId) async {
    if (!_useSupabase) return;

    try {
      await _supabaseDbService.deleteCollection(collectionId);
      await loadCollections();
      await loadProducts(); // Reload products as their collection_id may have changed
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Add product to collection
  Future<void> addProductToCollection(String productId, String collectionId) async {
    if (!_useSupabase) return;

    try {
      await _supabaseDbService.addProductToCollection(productId, collectionId);
      await loadProducts(); // Reload to reflect changes
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Remove product from collection
  Future<void> removeProductFromCollection(String productId) async {
    if (!_useSupabase) return;

    try {
      await _supabaseDbService.removeProductFromCollection(productId);
      await loadProducts(); // Reload to reflect changes
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get products by collection
  Future<List<Product>> getProductsByCollection(String collectionId) async {
    if (!_useSupabase) return [];

    try {
      return await _supabaseDbService.getProductsByCollection(collectionId);
    } catch (e) {
      print('❌ Error getting products by collection: $e');
      return [];
    }
  }

  /// Get products without collection (uncategorized)
  Future<List<Product>> getProductsWithoutCollection() async {
    if (!_useSupabase) return _products;

    try {
      return await _supabaseDbService.getProductsWithoutCollection();
    } catch (e) {
      print('❌ Error getting uncategorized products: $e');
      return [];
    }
  }

  // ==================== FAVORITES FROM EXPLORE ====================

  /// Check if a product is in user's favorites
  Future<bool> isProductInFavorites(String productId) async {
    if (!_useSupabase) {
      // For local mode, check if product exists in _products list
      return _products.any((p) => p.id == productId);
    }

    try {
      return await _supabaseDbService.isInFavorites(productId);
    } catch (e) {
      print('❌ Error checking if product is in favorites: $e');
      return false;
    }
  }

  /// Add a product from explore to favorites (product already exists in shared DB)
  Future<bool> addProductToFavorites(String productId, {double? targetPrice}) async {
    if (!_useSupabase) {
      _error = 'Esta funcionalidad requiere Supabase';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Add to user favorites
      await _supabaseDbService.addToFavorites(productId, targetPrice: targetPrice);
      
      // Reload user's products to reflect the change
      await loadProducts();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove a product from favorites (only removes from user_favorites, not from shared products)
  Future<bool> removeProductFromFavorites(String productId) async {
    if (!_useSupabase) {
      // For local mode, delete the product
      await deleteProduct(productId);
      return true;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Remove from user favorites
      await _supabaseDbService.removeFromFavorites(productId);
      
      // Reload user's products to reflect the change
      await loadProducts();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
