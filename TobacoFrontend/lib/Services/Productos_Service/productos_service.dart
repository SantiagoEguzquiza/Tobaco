import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Producto.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';

class ProductoService {
  final Uri baseUrl = Apihandler.baseUrl;
  static const Duration _timeoutDuration = Duration(milliseconds: 500); // Ultra rápido para modo offline

  Future<List<Producto>> obtenerProductos() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Productos'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          // Respuesta vacía, retorna lista vacía
          return [];
        }
        final decoded = jsonDecode(response.body);
        if (decoded == null || (decoded is List && decoded.isEmpty)) {
          // JSON vacío o lista vacía
          return [];
        }
        final List<dynamic> productosJson = decoded;
        return productosJson.map((json) => Producto.fromJson(json)).toList();
      } else {
        throw Exception(
            'Error al obtener los productos. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      
      rethrow;
    }
  }

  Future<void> crearProducto(Producto producto) async {
    try {
      final Map<String, dynamic> productoJson = producto.toJson();
      
      // Debug: Imprimir lo que se está enviando
      

      final headers = await AuthService.getAuthHeaders();
      
      
      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/Productos'),
        headers: headers,
        body: jsonEncode(productoJson),
      ).timeout(_timeoutDuration);

      

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
            'Error al guardar el producto. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      } else {
        
      }
    } catch (e) {
      
      rethrow; 
    }
  }

  Future<void> editarProducto(Producto producto) async {
    try {  
      final productoJson = producto.toJsonId();

      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      final response = await Apihandler.client.put(
        Uri.parse('$baseUrl/Productos/${producto.id}'),
        headers: headers,
        body: jsonEncode(productoJson),
      ).timeout(_timeoutDuration);

      if (response.statusCode != 200) {
        throw Exception(
            'Error al editar el producto. Código de estado: ${response.statusCode}');
      } else {
        
      }
    } catch (e) {
      
      rethrow; 
    }
  }

  Future<void> eliminarProducto(int id) async {
    try {
      
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.delete(
        Uri.parse('$baseUrl/Productos/$id'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        
      } else if (response.statusCode == 409) {
        // Manejar conflicto (producto con ventas vinculadas)
        final responseBody = jsonDecode(response.body);
        final message = responseBody['message'] ?? 'No se puede eliminar el producto';
        
        throw Exception(message);
      } else if (response.statusCode == 400) {
        // Manejar error de validación
        final responseBody = jsonDecode(response.body);
        final message = responseBody['message'] ?? 'No se puede eliminar el producto';
        
        throw Exception(message);
      } else {
        
        throw Exception(
            'Error al eliminar el producto. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      
      rethrow; 
    }
  }

  Future<void> desactivarProducto(int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/Productos/$id/deactivate'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        
      } else {
        final responseBody = jsonDecode(response.body);
        final message = responseBody['message'] ?? 'Error al desactivar el producto';
        throw Exception(message);
      }
    } catch (e) {
      
      rethrow; 
    }
  }

  Future<void> activarProducto(int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/Productos/$id/activate'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        
      } else {
        final responseBody = jsonDecode(response.body);
        final message = responseBody['message'] ?? 'Error al activar el producto';
        throw Exception(message);
      }
    } catch (e) {
      
      rethrow; 
    }
  }

  Future<Map<String, dynamic>> obtenerProductosPaginados(int page, int pageSize) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Productos/paginados?page=$page&pageSize=$pageSize'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> productosJson = data['productos'];
        final List<Producto> productos = productosJson.map((json) => Producto.fromJson(json)).toList();
        
        return {
          'productos': productos,
          'totalItems': data['totalItems'],
          'totalPages': data['totalPages'],
          'currentPage': data['currentPage'],
          'pageSize': data['pageSize'],
          'hasNextPage': data['hasNextPage'],
          'hasPreviousPage': data['hasPreviousPage'],
        };
      } else {
        throw Exception(
            'Error al obtener los productos paginados. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      
      rethrow;
    }
  }
}
