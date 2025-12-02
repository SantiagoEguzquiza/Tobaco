import 'package:flutter/foundation.dart';

class PermisosEmpleado {
  final int id;
  final int userId;

  // Permisos de Productos
  final bool productosVisualizar;
  final bool productosCrear;
  final bool productosEditar;
  final bool productosEliminar;

  // Permisos de Clientes
  final bool clientesVisualizar;
  final bool clientesCrear;
  final bool clientesEditar;
  final bool clientesEliminar;

  // Permisos de Ventas
  final bool ventasVisualizar;
  final bool ventasCrear;
  final bool ventasEditarBorrador;
  final bool ventasEliminar;

  // Permisos de Cuenta Corriente
  final bool cuentaCorrienteVisualizar;
  final bool cuentaCorrienteRegistrarAbonos;

  // Permisos de Entregas
  final bool entregasVisualizar;
  final bool entregasActualizarEstado;

  PermisosEmpleado({
    required this.id,
    required this.userId,
    required this.productosVisualizar,
    required this.productosCrear,
    required this.productosEditar,
    required this.productosEliminar,
    required this.clientesVisualizar,
    required this.clientesCrear,
    required this.clientesEditar,
    required this.clientesEliminar,
    required this.ventasVisualizar,
    required this.ventasCrear,
    required this.ventasEditarBorrador,
    required this.ventasEliminar,
    required this.cuentaCorrienteVisualizar,
    required this.cuentaCorrienteRegistrarAbonos,
    required this.entregasVisualizar,
    required this.entregasActualizarEstado,
  });

  factory PermisosEmpleado.fromJson(Map<String, dynamic> json) {
    // Helper para buscar propiedad con diferentes formatos de nombre
    dynamic getValue(Map<String, dynamic> json, List<String> keys) {
      for (var key in keys) {
        if (json.containsKey(key)) {
          debugPrint('PermisosEmpleado.fromJson: Encontrado key "$key" con valor: ${json[key]}');
          return json[key];
        }
      }
      debugPrint('PermisosEmpleado.fromJson: No se encontró ninguna key en: ${keys.join(", ")}');
      return null;
    }
    
    debugPrint('PermisosEmpleado.fromJson: Parsing JSON. Keys disponibles: ${json.keys.toList()}');
    
    final productosVisualizarValue = getValue(json, ['Productos_Visualizar', 'productos_Visualizar']);
    debugPrint('PermisosEmpleado.fromJson: productosVisualizarValue = $productosVisualizarValue');
    
    return PermisosEmpleado(
      id: json['id'] ?? json['Id'] ?? 0,
      userId: json['userId'] ?? json['UserId'] ?? 0,
      productosVisualizar: productosVisualizarValue ?? false,
      productosCrear: getValue(json, ['Productos_Crear', 'productos_Crear']) ?? false,
      productosEditar: getValue(json, ['Productos_Editar', 'productos_Editar']) ?? false,
      productosEliminar: getValue(json, ['Productos_Eliminar', 'productos_Eliminar']) ?? false,
      clientesVisualizar: getValue(json, ['Clientes_Visualizar', 'clientes_Visualizar']) ?? false,
      clientesCrear: getValue(json, ['Clientes_Crear', 'clientes_Crear']) ?? false,
      clientesEditar: getValue(json, ['Clientes_Editar', 'clientes_Editar']) ?? false,
      clientesEliminar: getValue(json, ['Clientes_Eliminar', 'clientes_Eliminar']) ?? false,
      ventasVisualizar: getValue(json, ['Ventas_Visualizar', 'ventas_Visualizar']) ?? false,
      ventasCrear: getValue(json, ['Ventas_Crear', 'ventas_Crear']) ?? false,
      ventasEditarBorrador: getValue(json, ['Ventas_EditarBorrador', 'ventas_EditarBorrador']) ?? false,
      ventasEliminar: getValue(json, ['Ventas_Eliminar', 'ventas_Eliminar']) ?? false,
      cuentaCorrienteVisualizar: getValue(json, ['CuentaCorriente_Visualizar', 'cuentaCorriente_Visualizar']) ?? false,
      cuentaCorrienteRegistrarAbonos: getValue(json, ['CuentaCorriente_RegistrarAbonos', 'cuentaCorriente_RegistrarAbonos']) ?? false,
      entregasVisualizar: getValue(json, ['Entregas_Visualizar', 'entregas_Visualizar']) ?? false,
      entregasActualizarEstado: getValue(json, ['Entregas_ActualizarEstado', 'entregas_ActualizarEstado']) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'productos_Visualizar': productosVisualizar,
      'productos_Crear': productosCrear,
      'productos_Editar': productosEditar,
      'productos_Eliminar': productosEliminar,
      'clientes_Visualizar': clientesVisualizar,
      'clientes_Crear': clientesCrear,
      'clientes_Editar': clientesEditar,
      'clientes_Eliminar': clientesEliminar,
      'ventas_Visualizar': ventasVisualizar,
      'ventas_Crear': ventasCrear,
      'ventas_EditarBorrador': ventasEditarBorrador,
      'ventas_Eliminar': ventasEliminar,
      'cuentaCorriente_Visualizar': cuentaCorrienteVisualizar,
      'cuentaCorriente_RegistrarAbonos': cuentaCorrienteRegistrarAbonos,
      'entregas_Visualizar': entregasVisualizar,
      'entregas_ActualizarEstado': entregasActualizarEstado,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'productos_Visualizar': productosVisualizar,
      'productos_Crear': productosCrear,
      'productos_Editar': productosEditar,
      'productos_Eliminar': productosEliminar,
      'clientes_Visualizar': clientesVisualizar,
      'clientes_Crear': clientesCrear,
      'clientes_Editar': clientesEditar,
      'clientes_Eliminar': clientesEliminar,
      'ventas_Visualizar': ventasVisualizar,
      'ventas_Crear': ventasCrear,
      'ventas_EditarBorrador': ventasEditarBorrador,
      'ventas_Eliminar': ventasEliminar,
      'cuentaCorriente_Visualizar': cuentaCorrienteVisualizar,
      'cuentaCorriente_RegistrarAbonos': cuentaCorrienteRegistrarAbonos,
      'entregas_Visualizar': entregasVisualizar,
      'entregas_ActualizarEstado': entregasActualizarEstado,
    };
  }

  PermisosEmpleado copyWith({
    int? id,
    int? userId,
    bool? productosVisualizar,
    bool? productosCrear,
    bool? productosEditar,
    bool? productosEliminar,
    bool? clientesVisualizar,
    bool? clientesCrear,
    bool? clientesEditar,
    bool? clientesEliminar,
    bool? ventasVisualizar,
    bool? ventasCrear,
    bool? ventasEditarBorrador,
    bool? ventasEliminar,
    bool? cuentaCorrienteVisualizar,
    bool? cuentaCorrienteRegistrarAbonos,
    bool? entregasVisualizar,
    bool? entregasActualizarEstado,
  }) {
    return PermisosEmpleado(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productosVisualizar: productosVisualizar ?? this.productosVisualizar,
      productosCrear: productosCrear ?? this.productosCrear,
      productosEditar: productosEditar ?? this.productosEditar,
      productosEliminar: productosEliminar ?? this.productosEliminar,
      clientesVisualizar: clientesVisualizar ?? this.clientesVisualizar,
      clientesCrear: clientesCrear ?? this.clientesCrear,
      clientesEditar: clientesEditar ?? this.clientesEditar,
      clientesEliminar: clientesEliminar ?? this.clientesEliminar,
      ventasVisualizar: ventasVisualizar ?? this.ventasVisualizar,
      ventasCrear: ventasCrear ?? this.ventasCrear,
      ventasEditarBorrador: ventasEditarBorrador ?? this.ventasEditarBorrador,
      ventasEliminar: ventasEliminar ?? this.ventasEliminar,
      cuentaCorrienteVisualizar: cuentaCorrienteVisualizar ?? this.cuentaCorrienteVisualizar,
      cuentaCorrienteRegistrarAbonos: cuentaCorrienteRegistrarAbonos ?? this.cuentaCorrienteRegistrarAbonos,
      entregasVisualizar: entregasVisualizar ?? this.entregasVisualizar,
      entregasActualizarEstado: entregasActualizarEstado ?? this.entregasActualizarEstado,
    );
  }
}

