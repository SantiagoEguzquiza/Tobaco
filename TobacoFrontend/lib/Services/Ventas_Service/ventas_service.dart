import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';

class VentasService {
  final Uri baseUrl = Apihandler.baseUrl;

  Future<List<Ventas>> obtenerVentas() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Pedidos'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> ventasJson = jsonDecode(response.body);
        
        // Debug: Imprimir la estructura de datos recibida
        debugPrint('Datos recibidos del backend: ${jsonEncode(ventasJson)}');
        
        return ventasJson.map((json) {
          debugPrint('Procesando venta individual: ${jsonEncode(json)}');
          return Ventas.fromJson(json);
        }).toList();
      } else {
        throw Exception(
          'Error al obtener las ventas. Código de estado: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error al obtener las ventas: $e');
      rethrow;
    }
  }

  Future<void> crearVenta(Ventas venta) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      
      // Debug: Imprimir los datos que se están enviando
      final ventaJson = venta.toJson();
      debugPrint('Enviando venta: ${jsonEncode(ventaJson)}');
      debugPrint('URL: $baseUrl/Pedidos');
      debugPrint('Headers: $headers');
      
      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/Pedidos'),
        headers: headers,
        body: jsonEncode(ventaJson),
      );

      debugPrint('Respuesta del servidor: ${response.statusCode}');
      debugPrint('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'Error al guardar la venta. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      } else {
        debugPrint('Venta guardada exitosamente');
      }
    } catch (e) {
      debugPrint('Error al guardar la venta: $e');
      rethrow;
    }
  }

  Future<void> editarVenta(Ventas venta) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      final response = await Apihandler.client.put(
        Uri.parse('$baseUrl/Pedidos/${venta.id}'),
        headers: headers,
        body: jsonEncode(venta.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al editar la venta. Código de estado: ${response.statusCode}');
      } else {
        debugPrint('Venta editada exitosamente');
      }
    } catch (e) {
      debugPrint('Error al editar la venta: $e');
      rethrow;
    }
  }

  Future<void> eliminarVenta(int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.delete(
        Uri.parse('$baseUrl/Pedidos/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al eliminar la venta. Código de estado: ${response.statusCode}');
      } else {
        debugPrint('Venta eliminada exitosamente');
      }
    } catch (e) {
      debugPrint('Error al eliminar la venta: $e');
      rethrow;
    }
  }
}
