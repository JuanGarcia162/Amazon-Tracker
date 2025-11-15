import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/favorite_collection.dart';

class SupabaseDatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user ID
  String? get _userId => _supabase.auth.currentUser?.id;

  // Helper: Convert Supabase JSON to Product
  Product _productFromSupabase(Map<String, dynamic> json) {
    try {
      // Safe conversion for prices (handles both int and double)
      double parsePrice(dynamic value) {
        if (value == null) return 0.0;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      }

      return Product(
        id: json['id'] as String,
        asin: json['asin'] as String,
        title: json['title'] as String,
        imageUrl: json['image_url'] as String,
        currentPrice: parsePrice(json['current_price']),
        originalPrice: json['original_price'] != null ? parsePrice(json['original_price']) : null,
        currency: json['currency'] as String? ?? 'USD',
        url: json['url'] as String,
        lastUpdated: DateTime.parse(json['last_updated'] as String),
      );
    } catch (e) {
      print('❌ Error parsing product from Supabase: $e');
      print('   JSON: $json');
      rethrow;
    }
  }

  // Check if product exists by ASIN
  Future<Product?> getProductByAsin(String asin) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('asin', asin)
          .maybeSingle();

      if (response == null) return null;

      return _productFromSupabase(response);
    } catch (e) {
      print('Error getting product by ASIN: $e');
      return null;
    }
  }

  // Insert or update product (shared)
  Future<Product> insertProduct(Product product) async {
    final userId = _userId;
    if (userId == null) throw Exception('Usuario no autenticado');

    // Check if product already exists by ASIN
    final existing = await getProductByAsin(product.asin);
    if (existing != null) {
      print('✅ Product already exists, returning existing product');
      return existing;
    }

    // Insert new product
    final supabaseData = {
      'id': product.id,
      'asin': product.asin,
      'title': product.title,
      'image_url': product.imageUrl,
      'current_price': product.currentPrice,
      'original_price': product.originalPrice,
      'currency': product.currency,
      'url': product.url,
      'last_updated': product.lastUpdated.toIso8601String(),
      'created_by': userId,
    };

    await _supabase.from('products').insert(supabaseData);
    print('✅ New product created in shared database');
    return product;
  }

  // Insert price history
  Future<void> insertPriceHistory(PriceHistory history) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final historyData = history.toJson();
    
    // Convert snake_case for Supabase
    final supabaseData = {
      'id': historyData['id'],
      'product_id': historyData['productId'],
      'price': historyData['price'],
      'timestamp': historyData['timestamp'],
    };

    await _supabase.from('price_history').upsert(supabaseData);
  }

  // Add product to user favorites
  Future<void> addToFavorites(String productId, {double? targetPrice}) async {
    final userId = _userId;
    if (userId == null) throw Exception('Usuario no autenticado');

    final favoriteData = {
      'user_id': userId,
      'product_id': productId,
      'target_price': targetPrice,
      'is_tracking': true,
    };

    await _supabase.from('user_favorites').upsert(favoriteData);
    print('✅ Product added to favorites');
  }

  // Remove product from user favorites
  Future<void> removeFromFavorites(String productId) async {
    final userId = _userId;
    if (userId == null) throw Exception('Usuario no autenticado');

    await _supabase
        .from('user_favorites')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
    
    print('✅ Product removed from favorites');
  }

  // Get all favorite products for current user
  Future<List<Product>> getAllProducts() async {
    final userId = _userId;
    if (userId == null) throw Exception('Usuario no autenticado');

    // Safe conversion for prices (handles both int and double)
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Join favorites with products
    final response = await _supabase
        .from('user_favorites')
        .select('*, products(*)')
        .eq('user_id', userId)
        .order('added_at', ascending: false);

    return (response as List).map((json) {
      try {
        final productJson = json['products'];
        final favorite = json;
        
        // Create product with favorite data
        return Product(
          id: productJson['id'] as String,
          asin: productJson['asin'] as String,
          title: productJson['title'] as String,
          imageUrl: productJson['image_url'] as String,
          currentPrice: parsePrice(productJson['current_price']),
          originalPrice: productJson['original_price'] != null 
              ? parsePrice(productJson['original_price'])
              : null,
          currency: productJson['currency'] as String? ?? 'USD',
          url: productJson['url'] as String,
          lastUpdated: DateTime.parse(productJson['last_updated'] as String),
          targetPrice: favorite['target_price'] != null 
              ? parsePrice(favorite['target_price'])
              : null,
          isTracking: favorite['is_tracking'] as bool? ?? true,
          collectionId: favorite['collection_id'] as String?,
        );
      } catch (e) {
        print('❌ Error parsing favorite product: $e');
        print('   JSON: $json');
        rethrow;
      }
    }).toList();
  }

  // Get single product by ID
  Future<Product?> getProduct(String id) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return _productFromSupabase(response);
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  // Check if user has product in favorites
  Future<bool> isInFavorites(String productId) async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      final response = await _supabase
          .from('user_favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Get price history for a product
  Future<List<PriceHistory>> getPriceHistory(String productId) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    // Safe conversion for prices (handles both int and double)
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final response = await _supabase
        .from('price_history')
        .select()
        .eq('product_id', productId)
        .order('timestamp', ascending: true);

    return (response as List).map((json) {
      try {
        // Convert from snake_case to camelCase with safe type conversion
        final historyData = {
          'id': json['id'] as String,
          'productId': json['product_id'] as String,
          'price': parsePrice(json['price']),  // Safe conversion
          'timestamp': json['timestamp'] as String,
        };
        return PriceHistory.fromJson(historyData);
      } catch (e) {
        print('❌ Error parsing price history: $e');
        print('   JSON: $json');
        rethrow;
      }
    }).toList();
  }

  // Update product (shared - anyone can update prices)
  Future<void> updateProduct(Product product) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final supabaseData = {
      'title': product.title,
      'image_url': product.imageUrl,
      'current_price': product.currentPrice,
      'original_price': product.originalPrice,
      'currency': product.currency,
      'url': product.url,
      'last_updated': product.lastUpdated.toIso8601String(),
    };

    await _supabase
        .from('products')
        .update(supabaseData)
        .eq('id', product.id);
  }

  // Update user favorite settings (target price, tracking)
  Future<void> updateFavorite(String productId, {double? targetPrice, bool? isTracking}) async {
    final userId = _userId;
    if (userId == null) throw Exception('Usuario no autenticado');

    final updateData = <String, dynamic>{};
    if (targetPrice != null) updateData['target_price'] = targetPrice;
    if (isTracking != null) updateData['is_tracking'] = isTracking;

    if (updateData.isEmpty) return;

    await _supabase
        .from('user_favorites')
        .update(updateData)
        .eq('user_id', userId)
        .eq('product_id', productId);
  }

  // Delete product (only removes from favorites, not from shared database)
  Future<void> deleteProduct(String id) async {
    await removeFromFavorites(id);
  }

  // Search products in shared database
  Future<List<Product>> searchProducts(String query) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final response = await _supabase
        .from('products')
        .select()
        .or('title.ilike.%$query%,asin.ilike.%$query%')
        .order('last_updated', ascending: false)
        .limit(20);

    return (response as List).map((json) => _productFromSupabase(json)).toList();
  }

  // Get ALL products in shared database (not just user favorites)
  Future<List<Product>> getAllSharedProducts({int limit = 50}) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final response = await _supabase
        .from('products')
        .select()
        .order('last_updated', ascending: false)
        .limit(limit);

    return (response as List).map((json) => _productFromSupabase(json)).toList();
  }

  // ==================== COLLECTIONS METHODS ====================

  // Get all collections for current user
  Future<List<FavoriteCollection>> getCollections() async {
    final userId = _userId;
    if (userId == null) throw Exception('Usuario no autenticado');

    final response = await _supabase
        .from('favorite_collections')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => FavoriteCollection.fromJson(json)).toList();
  }

  // Create a new collection
  Future<FavoriteCollection> createCollection({
    required String name,
    String? description,
    String? icon,
    String? color,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Usuario no autenticado');

    final collectionData = {
      'user_id': userId,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
    };

    final response = await _supabase
        .from('favorite_collections')
        .insert(collectionData)
        .select()
        .single();

    print('✅ Collection created: $name');
    return FavoriteCollection.fromJson(response);
  }

  // Update a collection
  Future<void> updateCollection(
    String collectionId, {
    String? name,
    String? description,
    String? icon,
    String? color,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Usuario no autenticado');

    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) updateData['name'] = name;
    if (description != null) updateData['description'] = description;
    if (icon != null) updateData['icon'] = icon;
    if (color != null) updateData['color'] = color;

    await _supabase
        .from('favorite_collections')
        .update(updateData)
        .eq('id', collectionId)
        .eq('user_id', userId);

    print('✅ Collection updated');
  }

  // Delete a collection
  Future<void> deleteCollection(String collectionId) async {
    final userId = _userId;
    if (userId == null) throw Exception('Usuario no autenticado');

    await _supabase
        .from('favorite_collections')
        .delete()
        .eq('id', collectionId)
        .eq('user_id', userId);

    print('✅ Collection deleted');
  }

  // Add product to collection
  Future<void> addProductToCollection(String productId, String collectionId) async {
    final userId = _userId;
    if (userId == null) throw Exception('Usuario no autenticado');

    await _supabase
        .from('user_favorites')
        .update({'collection_id': collectionId})
        .eq('user_id', userId)
        .eq('product_id', productId);

    print('✅ Product added to collection');
  }

  // Remove product from collection (set collection_id to null)
  Future<void> removeProductFromCollection(String productId) async {
    final userId = _userId;
    if (userId == null) throw Exception('Usuario no autenticado');

    await _supabase
        .from('user_favorites')
        .update({'collection_id': null})
        .eq('user_id', userId)
        .eq('product_id', productId);

    print('✅ Product removed from collection');
  }

  // Get products by collection
  Future<List<Product>> getProductsByCollection(String collectionId) async {
    final userId = _userId;
    if (userId == null) throw Exception('Usuario no autenticado');

    // Safe conversion for prices (handles both int and double)
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Join favorites with products, filtering by collection
    final response = await _supabase
        .from('user_favorites')
        .select('*, products(*)')
        .eq('user_id', userId)
        .eq('collection_id', collectionId)
        .order('added_at', ascending: false);

    return (response as List).map((json) {
      try {
        final productJson = json['products'];
        final favorite = json;
        
        // Create product with favorite data
        return Product(
          id: productJson['id'] as String,
          asin: productJson['asin'] as String,
          title: productJson['title'] as String,
          imageUrl: productJson['image_url'] as String,
          currentPrice: parsePrice(productJson['current_price']),
          originalPrice: productJson['original_price'] != null 
              ? parsePrice(productJson['original_price'])
              : null,
          currency: productJson['currency'] as String? ?? 'USD',
          url: productJson['url'] as String,
          lastUpdated: DateTime.parse(productJson['last_updated'] as String),
          targetPrice: favorite['target_price'] != null 
              ? parsePrice(favorite['target_price'])
              : null,
          isTracking: favorite['is_tracking'] as bool? ?? true,
          collectionId: favorite['collection_id'] as String?,
        );
      } catch (e) {
        print('❌ Error parsing favorite product: $e');
        print('   JSON: $json');
        rethrow;
      }
    }).toList();
  }

  // Get products without collection (uncategorized)
  Future<List<Product>> getProductsWithoutCollection() async {
    final userId = _userId;
    if (userId == null) throw Exception('Usuario no autenticado');

    // Safe conversion for prices (handles both int and double)
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Join favorites with products, filtering by null collection_id
    final response = await _supabase
        .from('user_favorites')
        .select('*, products(*)')
        .eq('user_id', userId)
        .isFilter('collection_id', null)
        .order('added_at', ascending: false);

    return (response as List).map((json) {
      try {
        final productJson = json['products'];
        final favorite = json;
        
        // Create product with favorite data
        return Product(
          id: productJson['id'] as String,
          asin: productJson['asin'] as String,
          title: productJson['title'] as String,
          imageUrl: productJson['image_url'] as String,
          currentPrice: parsePrice(productJson['current_price']),
          originalPrice: productJson['original_price'] != null 
              ? parsePrice(productJson['original_price'])
              : null,
          currency: productJson['currency'] as String? ?? 'USD',
          url: productJson['url'] as String,
          lastUpdated: DateTime.parse(productJson['last_updated'] as String),
          targetPrice: favorite['target_price'] != null 
              ? parsePrice(favorite['target_price'])
              : null,
          isTracking: favorite['is_tracking'] as bool? ?? true,
          collectionId: favorite['collection_id'] as String?,
        );
      } catch (e) {
        print('❌ Error parsing favorite product: $e');
        print('   JSON: $json');
        rethrow;
      }
    }).toList();
  }
}
