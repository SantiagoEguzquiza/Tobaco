import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Categoria.dart';
import 'package:tobaco/Models/CategoriaReorderDTO.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';

class CategoriaService {
  final Uri baseUrl = Apihandler.baseUrl;
  static const Duration _timeoutDuration = Duration(milliseconds: 500); // Ultra rápido para modo offline

  Future<List<Categoria>> obtenerCategorias() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Categoria'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        // Validar que la respuesta no esté vacía
        if (response.body.isEmpty) {
          throw Exception('El servidor devolvió una respuesta vacía');
        }

        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Categoria.fromJson(json)).toList();
      } else {
        throw Exception(
            'Error al obtener categorías. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error al obtener categorías: $e');
      rethrow;
    }
  }

  Future<void> crearCategoria(Categoria categoria) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/Categoria'),
        headers: headers,
        body: jsonEncode(categoria.toJson()),
      ).timeout(_timeoutDuration);

      if (response.statusCode != 200) {
        throw Exception(
            'Error al guardar el cliente. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      } else {
        debugPrint('Cliente guardado exitosamente');
      }
    } catch (e) {
      debugPrint('Error al guardar el cliente: $e');
      rethrow;
    }
  }

  Future<void> eliminarCategoria(int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.delete(
        Uri.parse('$baseUrl/Categoria/$id'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode != 200) {
        // Intentar extraer el mensaje del backend
        String errorMessage = 'Error al eliminar la categoria. Código de estado: ${response.statusCode}';
        
        try {
          if (response.body.isNotEmpty) {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            if (errorData.containsKey('message')) {
              errorMessage = errorData['message'];
            } else if (errorData.containsKey('error')) {
              errorMessage = errorData['error'];
            }
          }
        } catch (e) {
          // Si no se puede parsear el JSON, usar el mensaje por defecto
          debugPrint('No se pudo parsear el error del backend: $e');
        }
        
        throw Exception(errorMessage);
      } else {
        debugPrint('Categoria eliminado exitosamente');
      }
    } catch (e) {
      debugPrint('Error al eliminar la categoria: $e');
      rethrow;
    }
  }

  Future<Categoria> editarCategoria(int id, String nombre, String colorHex) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.put(
        Uri.parse('$baseUrl/Categoria/$id'),
        headers: headers,
        body: jsonEncode({
          'id': id,
          'nombre': nombre,
          'colorHex': colorHex,
        }),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return Categoria.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Error al editar categoría. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error al editar categoría: $e');
      rethrow;
    }
  }

  Future<void> reordenarCategorias(List<CategoriaReorderDTO> categoriaOrders) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.put(
        Uri.parse('$baseUrl/Categoria/reordenar'),
        headers: headers,
        body: jsonEncode(categoriaOrders.map((co) => co.toJson()).toList()),
      ).timeout(_timeoutDuration);

      if (response.statusCode != 200) {
        throw Exception(
            'Error al reordenar categorías. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      } else {
        debugPrint('Categorías reordenadas exitosamente');
      }
    } catch (e) {
      debugPrint('Error al reordenar categorías: $e');
      rethrow;
    }
  }
}
