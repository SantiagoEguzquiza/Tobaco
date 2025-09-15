import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Producto.dart';

class ProductoService {
  final Uri baseUrl = Apihandler.baseUrl;

  Future<List<Producto>> obtenerProductos() async {
    try {
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Productos'),
        headers: {'Content-Type': 'application/json'},
      );

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
      debugPrint('Error al obtener los productos: $e');
      rethrow;
    }
  }

  Future<void> crearProducto(Producto producto) async {
    try {
      final Map<String, dynamic> productoJson = producto.toJson();

      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/Productos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(productoJson),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al guardar el producto. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      } else {
        debugPrint('Producto guardado exitosamente');
      }
    } catch (e) {
      debugPrint('Error al guardar el producto: $e');
      rethrow; 
    }
  }

  Future<void> editarProducto(Producto producto) async {
    try {  
      final productoJson = producto.toJsonId();

      final response = await Apihandler.client.put(
        Uri.parse('$baseUrl/Productos/${producto.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(productoJson),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al editar el producto. Código de estado: ${response.statusCode}');
      } else {
        debugPrint('Producto editado exitosamente');
      }
    } catch (e) {
      debugPrint('Error al editar el producto: $e');
      rethrow; 
    }
  }

  Future<void> eliminarProducto(int id) async {
    try {
      
      final response = await Apihandler.client.delete(
        Uri.parse('$baseUrl/Productos/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al eliminar el producto. Código de estado: ${response.statusCode}');
      } else {
        debugPrint('Producto eliminado exitosamente');
      }
    } catch (e) {
      debugPrint('Error al eliminar el producto: $e');
      rethrow; 
    }
  }
}
