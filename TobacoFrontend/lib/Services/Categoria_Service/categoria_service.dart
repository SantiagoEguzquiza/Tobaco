import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Categoria.dart';

class CategoriaService {
   final Uri baseUrl = Apihandler.baseUrl;

  Future<List<Categoria>> obtenerCategorias() async {
    final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Categoria'),
        headers: {'Content-Type': 'application/json'},
      );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Categoria.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener categorías');
    }
  }

  Future<void> crearCategoria(Categoria categoria) async {
    try {
      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/Categoria'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(categoria.toJson()),
      );

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
      final response = await Apihandler.client.delete(
        Uri.parse('$baseUrl/Categoria/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al eliminar la categoria. Código de estado: ${response.statusCode}');
      } else {
        debugPrint('Categoria eliminado exitosamente');
      }
    } catch (e) {
      debugPrint('Error al eliminar la categoria: $e');
      rethrow;
    }
  }


  Future<Categoria> editarCategoria(int id, String nombre) async {
    final response = await http.put(
      Uri.parse('$baseUrl/Categoria/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombre}),
    );

    if (response.statusCode == 200) {
      return Categoria.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al editar categoría');
    }
  }
}
