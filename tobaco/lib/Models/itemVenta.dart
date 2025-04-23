class ItemVenta {
  int productoId;
  int cantidad;

  ItemVenta({
    required this.productoId,
    required this.cantidad,
  });

  factory ItemVenta.fromJson(Map<String, dynamic> json) {
    return ItemVenta(
      productoId: json['productoId'],
      cantidad: json['cantidad'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'cantidad': cantidad,
    };
  }
}
