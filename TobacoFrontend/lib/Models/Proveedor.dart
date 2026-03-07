class Proveedor {
  final int id;
  final String nombre;
  final String? contacto;
  final String? email;

  Proveedor({
    required this.id,
    required this.nombre,
    this.contacto,
    this.email,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: (json['id'] ?? json['Id']) as int,
      nombre: (json['nombre'] ?? json['Nombre']) as String? ?? '',
      contacto: (json['contacto'] ?? json['Contacto']) as String?,
      email: (json['email'] ?? json['Email']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'contacto': contacto,
        'email': email,
      };
}
