class Product {
  final String id;
  final String asin;
  final String title;
  final String imageUrl;
  final double currentPrice;
  final double? originalPrice;
  final String currency;
  final String url;
  final DateTime lastUpdated;
  final List<PriceHistory> priceHistory;
  final double? targetPrice;
  final bool isTracking;
  final String? collectionId;

  Product({
    required this.id,
    required this.asin,
    required this.title,
    required this.imageUrl,
    required this.currentPrice,
    this.originalPrice,
    this.currency = 'USD',
    required this.url,
    required this.lastUpdated,
    this.priceHistory = const [],
    this.targetPrice,
    this.isTracking = true,
    this.collectionId,
  });

  double get discountPercentage {
    if (originalPrice == null || originalPrice! <= 0) return 0;
    return ((originalPrice! - currentPrice) / originalPrice!) * 100;
  }

  bool get hasDiscount => discountPercentage > 0;

  bool get isPriceAtTarget {
    if (targetPrice == null) return false;
    return currentPrice <= targetPrice!;
  }

  /// Obtiene el precio mínimo del historial
  double get minHistoricalPrice {
    if (priceHistory.isEmpty) return currentPrice;
    return priceHistory.map((h) => h.price).reduce((a, b) => a < b ? a : b);
  }

  /// Obtiene el precio máximo del historial
  double get maxHistoricalPrice {
    if (priceHistory.isEmpty) return currentPrice;
    return priceHistory.map((h) => h.price).reduce((a, b) => a > b ? a : b);
  }

  /// Calcula el porcentaje de descuento respecto al precio máximo histórico
  double get discountFromMaxPrice {
    final maxPrice = maxHistoricalPrice;
    if (maxPrice <= 0) return 0;
    return ((maxPrice - currentPrice) / maxPrice) * 100;
  }

  /// Indica si el precio actual es el más bajo del historial
  bool get isAtLowestPrice {
    return currentPrice <= minHistoricalPrice;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asin': asin,
      'title': title,
      'imageUrl': imageUrl,
      'currentPrice': currentPrice,
      'originalPrice': originalPrice,
      'currency': currency,
      'url': url,
      'lastUpdated': lastUpdated.toIso8601String(),
      'targetPrice': targetPrice,
      'isTracking': isTracking ? 1 : 0,
      'collectionId': collectionId,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      asin: json['asin'],
      title: json['title'],
      imageUrl: json['imageUrl'],
      currentPrice: json['currentPrice'],
      originalPrice: json['originalPrice'],
      currency: json['currency'] ?? 'USD',
      url: json['url'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      targetPrice: json['targetPrice'],
      isTracking: json['isTracking'] == 1,
      collectionId: json['collectionId'],
    );
  }

  Product copyWith({
    String? id,
    String? asin,
    String? title,
    String? imageUrl,
    double? currentPrice,
    double? originalPrice,
    String? currency,
    String? url,
    DateTime? lastUpdated,
    List<PriceHistory>? priceHistory,
    double? targetPrice,
    bool? isTracking,
    String? collectionId,
  }) {
    return Product(
      id: id ?? this.id,
      asin: asin ?? this.asin,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      currentPrice: currentPrice ?? this.currentPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      currency: currency ?? this.currency,
      url: url ?? this.url,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      priceHistory: priceHistory ?? this.priceHistory,
      targetPrice: targetPrice ?? this.targetPrice,
      isTracking: isTracking ?? this.isTracking,
      collectionId: collectionId ?? this.collectionId,
    );
  }
}

class PriceHistory {
  final String id;
  final String productId;
  final double price;
  final DateTime timestamp;

  PriceHistory({
    required this.id,
    required this.productId,
    required this.price,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'price': price,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PriceHistory.fromJson(Map<String, dynamic> json) {
    return PriceHistory(
      id: json['id'],
      productId: json['productId'],
      price: json['price'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
