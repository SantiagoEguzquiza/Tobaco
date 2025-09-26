class Producto {
  int? id;
  String nombre;
  double? cantidad;
  double precio;
  int categoriaId;
  String? categoriaNombre;
  bool half;
  bool isActive;

  Producto({
    required this.id,
    required this.nombre,
    this.cantidad,
    required this.precio,
    required this.categoriaId,
    this.categoriaNombre,
    required this.half,
    this.isActive = true,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as int?, 
      nombre: json['nombre'] as String,
      cantidad: json['cantidad'] != null
          ? double.tryParse(json['cantidad'].toString())
          : null,
      precio: json['precio'] != null
          ? double.tryParse(json['precio'].toString()) ?? 0.0
          : 0.0,
      categoriaId: json['categoriaId'] as int,
      categoriaNombre: json['categoriaNombre'] as String ?,
      half: json['half'] ?? false,
      isActive: json['isActive'] ?? true, 
    );
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'nombre': nombre,
      'cantidad': cantidad ?? 0.0, // Asegurar que no sea null
      'precio': precio,
      'categoriaId': categoriaId,
      'categoriaNombre': categoriaNombre ?? '',
      'half': half,
      'isActive': isActive,
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
      'cantidad': cantidad,
      'precio': precio,
      'categoriaId': categoriaId,
      'categoriaNombre': categoriaNombre,
      'half': half,
      'isActive': isActive,
    };
  }
}
