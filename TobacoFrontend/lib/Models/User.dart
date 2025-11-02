import 'package:tobaco/Models/TipoVendedor.dart';

class User {
  final int id;
  final String userName;
  final String? email;
  final String role;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;
  final TipoVendedor tipoVendedor;
  final String? zona;

  User({
    required this.id,
    required this.userName,
    this.email,
    required this.role,
    required this.createdAt,
    this.lastLogin,
    required this.isActive,
    TipoVendedor? tipoVendedor,
    this.zona,
  }) : tipoVendedor = tipoVendedor ?? TipoVendedor.repartidor;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      userName: json['userName'],
      email: json['email'],
      role: json['role'] ?? 'Employee',
      createdAt: DateTime.parse(json['createdAt']),
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      isActive: json['isActive'],
      tipoVendedor: json['tipoVendedor'] != null 
          ? TipoVendedor.fromJson(json['tipoVendedor'])
          : TipoVendedor.repartidor,
      zona: json['zona'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'email': email,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'isActive': isActive,
      'tipoVendedor': tipoVendedor.toJson(),
      'zona': zona,
    };
  }

  bool get isAdmin => role == 'Admin';
  bool get isEmployee => role == 'Employee';
  
  /// Indica si es vendedor (visita sucursales y asigna entregas)
  bool get esVendedor => 
      (isAdmin || isEmployee) && tipoVendedor == TipoVendedor.vendedor;
  
  /// Indica si es repartidor puro (solo realiza entregas)
  bool get esRepartidor => 
      (isAdmin || isEmployee) && tipoVendedor == TipoVendedor.repartidor;
  
  /// Indica si es repartidor-vendedor (visita, vende y entrega)
  /// Los administradores tienen todos los permisos de repartidor-vendedor por defecto
  bool get esRepartidorVendedor => 
      isAdmin || (isEmployee && tipoVendedor == TipoVendedor.repartidorVendedor);
}
