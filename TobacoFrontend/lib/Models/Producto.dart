import 'ProductQuantityPrice.dart';

class Producto {
  int? id;
  String nombre;
  String? marca;
  double? stock;
  double precio;
  int categoriaId;
  String? categoriaNombre;
  bool half;
  bool isActive;
  List<ProductQuantityPrice> quantityPrices;

  Producto({
    required this.id,
    required this.nombre,
    this.marca,
    this.stock,
    required this.precio,
    required this.categoriaId,
    this.categoriaNombre,
    required this.half,
    this.isActive = true,
    this.quantityPrices = const [],
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as int?, 
      nombre: json['nombre'] as String,
      marca: json['marca'] as String?,
      stock: json['stock'] != null
          ? double.tryParse(json['stock'].toString())
          : null,
      precio: json['precio'] != null
          ? double.tryParse(json['precio'].toString()) ?? 0.0
          : 0.0,
      categoriaId: json['categoriaId'] as int,
      categoriaNombre: json['categoriaNombre'] as String?,
      half: json['half'] ?? false,
      isActive: json['isActive'] ?? true,
      quantityPrices: json['quantityPrices'] != null
          ? (json['quantityPrices'] as List)
              .map((e) => ProductQuantityPrice.fromJson(e))
              .toList()
          : [],
    );
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'nombre': nombre,
      'marca': marca,
      'stock': stock ?? 0.0, // Asegurar que no sea null
      'precio': precio,
      'categoriaId': categoriaId,
      'categoriaNombre': categoriaNombre ?? '',
      'half': half,
      'isActive': isActive,
      'quantityPrices': quantityPrices.map((qp) => qp.toJson()).toList(),
    };
    
    // Solo incluir id si no es null (para productos existentes)
    if (id != null) {
      json['id'] = id;
    }
    
    return json;
  }

  Map<String, dynamic> toJsonId() {
    return {
      'id': id,
      'nombre': nombre,
      'marca': marca,
      'stock': stock,
      'precio': precio,
      'categoriaId': categoriaId,
      'categoriaNombre': categoriaNombre,
      'half': half,
      'isActive': isActive,
      'quantityPrices': quantityPrices.map((qp) => qp.toJson()).toList(),
    };
  }
}
