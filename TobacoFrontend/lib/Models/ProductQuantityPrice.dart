class ProductQuantityPrice {
  int? id;
  int productId;
  int quantity;
  double totalPrice;
  double get unitPrice => quantity > 0 ? totalPrice / quantity : 0.0;

  ProductQuantityPrice({
    this.id,
    required this.productId,
    required this.quantity,
    required this.totalPrice,
  });

  factory ProductQuantityPrice.fromJson(Map<String, dynamic> json) {
    return ProductQuantityPrice(
      id: json['id'] as int?,
      productId: json['productId'] as int,
      quantity: json['quantity'] as int,
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
    
    // Solo incluir id y productId si no son null o 0
    if (id != null && id != 0) {
      json['id'] = id;
    }
    if (productId != 0) {
      json['productId'] = productId;
    }
    
    return json;
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }

  ProductQuantityPrice copyWith({
    int? id,
    int? productId,
    int? quantity,
    double? totalPrice,
  }) {
    return ProductQuantityPrice(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductQuantityPrice &&
        other.id == id &&
        other.productId == productId &&
        other.quantity == quantity &&
        other.totalPrice == totalPrice;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        productId.hashCode ^
        quantity.hashCode ^
        totalPrice.hashCode;
  }

  @override
  String toString() {
    return 'ProductQuantityPrice(id: $id, productId: $productId, quantity: $quantity, totalPrice: $totalPrice, unitPrice: $unitPrice)';
  }
}
