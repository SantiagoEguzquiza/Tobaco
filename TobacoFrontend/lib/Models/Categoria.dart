class Categoria {
  final int? id;
  final String nombre;

  Categoria({
    this.id,
    required this.nombre,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: json['id'],
        nombre: json['nombre'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        
        'nombre': nombre,
      };
}
