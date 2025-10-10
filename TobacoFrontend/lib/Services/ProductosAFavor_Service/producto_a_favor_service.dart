import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/ProductoAFavor.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';

class ProductoAFavorService {
  final Uri baseUrl = Apihandler.baseUrl;
  static const Duration _timeoutDuration = Duration(seconds: 10);

  Future<List<ProductoAFavor>> obtenerProductosAFavorByClienteId(
    int clienteId, {
    bool? soloNoEntregados,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      String url = '$baseUrl/ProductoAFavor/cliente/$clienteId';
      if (soloNoEntregados != null) {
        url += '?soloNoEntregados=$soloNoEntregados';
      }

      final response = await Apihandler.client.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> productosJson = jsonDecode(response.body);
        return productosJson.map((json) => ProductoAFavor.fromJson(json)).toList();
      } else {
        throw Exception(
          'Error al obtener productos a favor. Código de estado: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error al obtener productos a favor: $e');
      rethrow;
    }
  }

  Future<List<ProductoAFavor>> obtenerProductosAFavorByVentaId(int ventaId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/ProductoAFavor/venta/$ventaId'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> productosJson = jsonDecode(response.body);
        return productosJson.map((json) => ProductoAFavor.fromJson(json)).toList();
      } else {
        throw Exception(
          'Error al obtener productos a favor de la venta. Código de estado: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error al obtener productos a favor de la venta: $e');
      rethrow;
    }
  }

  Future<void> marcarComoEntregado(int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final response = await Apihandler.client.put(
        Uri.parse('$baseUrl/ProductoAFavor/$id/marcar-entregado'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode != 200) {
        throw Exception(
          'Error al marcar como entregado. Código de estado: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error al marcar como entregado: $e');
      rethrow;
    }
  }

  Future<void> eliminarProductoAFavor(int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.delete(
        Uri.parse('$baseUrl/ProductoAFavor/$id'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode != 200) {
        throw Exception(
          'Error al eliminar producto a favor. Código de estado: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error al eliminar producto a favor: $e');
      rethrow;
    }
  }
}

