class UserFavorite {
  final String id;
  final String userId;
  final String productId;
  final String? collectionId;
  final double? targetPrice;
  final bool isTracking;
  final DateTime addedAt;

  UserFavorite({
    required this.id,
    required this.userId,
    required this.productId,
    this.collectionId,
    this.targetPrice,
    this.isTracking = true,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'collection_id': collectionId,
      'target_price': targetPrice,
      'is_tracking': isTracking,
      'added_at': addedAt.toIso8601String(),
    };
  }

  factory UserFavorite.fromJson(Map<String, dynamic> json) {
    return UserFavorite(
      id: json['id'],
      userId: json['user_id'],
      productId: json['product_id'],
      collectionId: json['collection_id'],
      targetPrice: json['target_price'],
      isTracking: json['is_tracking'] ?? true,
      addedAt: DateTime.parse(json['added_at']),
    );
  }

  UserFavorite copyWith({
    String? id,
    String? userId,
    String? productId,
    String? collectionId,
    double? targetPrice,
    bool? isTracking,
    DateTime? addedAt,
  }) {
    return UserFavorite(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      collectionId: collectionId ?? this.collectionId,
      targetPrice: targetPrice ?? this.targetPrice,
      isTracking: isTracking ?? this.isTracking,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
