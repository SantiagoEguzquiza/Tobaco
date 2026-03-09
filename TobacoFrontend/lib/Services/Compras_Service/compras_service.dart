import 'dart:convert';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Compra.dart';
import 'package:tobaco/Models/Proveedor.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';

class ComprasService {
  final Uri baseUrl = Apihandler.baseUrl;
  static const Duration _timeout = Duration(seconds: 15);

  Future<List<Proveedor>> getProveedores() async {
    final headers = await AuthService.getAuthHeaders();
    final response = await Apihandler.client
        .get(Uri.parse('$baseUrl/api/Proveedor'), headers: headers)
        .timeout(_timeout);
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => Proveedor.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (response.statusCode == 401) throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
    throw Exception('Error al obtener proveedores: ${response.statusCode}');
  }

  Future<Proveedor> crearProveedor(String nombre, {String? contacto, String? email}) async {
    final headers = await AuthService.getAuthHeaders();
    headers['Content-Type'] = 'application/json';
    final body = jsonEncode({
      'nombre': nombre,
      'contacto': contacto,
      'email': email,
    });
    final response = await Apihandler.client
        .post(Uri.parse('$baseUrl/api/Proveedor'), headers: headers, body: body)
        .timeout(_timeout);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Proveedor.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    if (response.statusCode == 401) throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
    final msg = response.body;
    throw Exception(msg.contains('message') ? _extractMessage(msg) : 'Error al crear proveedor');
  }

  String _extractMessage(String body) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>;
      return m['message'] as String? ?? body;
    } catch (_) {
      return body;
    }
  }

  Future<List<Compra>> getCompras({DateTime? desde, DateTime? hasta}) async {
    final headers = await AuthService.getAuthHeaders();
    var path = '$baseUrl/api/Compra';
    if (desde != null || hasta != null) {
      final q = <String>[];
      if (desde != null) q.add('desde=${desde.toIso8601String().split('T')[0]}');
      if (hasta != null) q.add('hasta=${hasta.toIso8601String().split('T')[0]}');
      path += '?${q.join('&')}';
    }
    final response = await Apihandler.client.get(Uri.parse(path), headers: headers).timeout(_timeout);
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => Compra.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (response.statusCode == 401) throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
    throw Exception('Error al obtener compras: ${response.statusCode}');
  }

  Future<Compra?> getCompraById(int id) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await Apihandler.client
        .get(Uri.parse('$baseUrl/api/Compra/$id'), headers: headers)
        .timeout(_timeout);
    if (response.statusCode == 200) {
      return Compra.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    if (response.statusCode == 404) return null;
    if (response.statusCode == 401) throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
    throw Exception('Error al obtener compra: ${response.statusCode}');
  }

  Future<Compra> crearCompra({
    required int proveedorId,
    required DateTime fecha,
    String? numeroComprobante,
    String? observaciones,
    required List<Map<String, dynamic>> items,
  }) async {
    final headers = await AuthService.getAuthHeaders();
    headers['Content-Type'] = 'application/json';
    final body = jsonEncode({
      'proveedorId': proveedorId,
      'fecha': fecha.toUtc().toIso8601String(),
      'numeroComprobante': numeroComprobante,
      'observaciones': observaciones,
      'items': items,
    });
    final response = await Apihandler.client
        .post(Uri.parse('$baseUrl/api/Compra'), headers: headers, body: body)
        .timeout(_timeout);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Compra.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    if (response.statusCode == 401) throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
    final msg = response.body;
    throw Exception(msg.contains('message') ? _extractMessage(msg) : 'Error al registrar la compra');
  }

  Future<void> eliminarCompra(int id) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await Apihandler.client
        .delete(Uri.parse('$baseUrl/api/Compra/$id'), headers: headers)
        .timeout(_timeout);
    if (response.statusCode == 204) return;
    if (response.statusCode == 401) throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
    if (response.statusCode == 400) {
      final msg = response.body;
      throw Exception(msg.contains('message') ? _extractMessage(msg) : 'Error al eliminar la compra');
    }
    throw Exception('Error al eliminar la compra: ${response.statusCode}');
  }
}
