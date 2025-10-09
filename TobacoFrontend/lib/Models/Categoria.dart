class Categoria {
  final int? id;
  final String nombre;
  final String colorHex;
  final int sortOrder;

  Categoria({
    this.id,
    required this.nombre,
    this.colorHex = '#9E9E9E', // Default gray color
    this.sortOrder = 0, // Default sort order
  });

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: json['id'],
        nombre: json['nombre'] ?? '',
        colorHex: _validateColorHex(json['colorHex']),
        sortOrder: json['sortOrder'] ?? 0,
      );

  // Helper method to validate and ensure colorHex is always valid
  static String _validateColorHex(dynamic colorHex) {
    if (colorHex == null || colorHex.toString().isEmpty) {
      return '#9E9E9E';
    }
    String color = colorHex.toString();
    if (color.length < 7 || !color.startsWith('#')) {
      return '#9E9E9E';
    }
    return color;
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'colorHex': colorHex,
        'sortOrder': sortOrder,
      };
}
