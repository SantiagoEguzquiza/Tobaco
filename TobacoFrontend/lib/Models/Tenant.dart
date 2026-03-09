class Tenant {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? email;
  final String? telefono;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Tenant({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.email,
    this.telefono,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tenant && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      email: json['email'],
      telefono: json['telefono'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'email': email,
      'telefono': telefono,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'empresaNombre': nombre,
      'empresaDescripcion': descripcion,
      'empresaEmail': email,
      'empresaTelefono': telefono,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'email': email,
      'telefono': telefono,
      'isActive': isActive,
    };
  }
}

