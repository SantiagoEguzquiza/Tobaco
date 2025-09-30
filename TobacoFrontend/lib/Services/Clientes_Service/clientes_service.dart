import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';

class ClienteService {
  final Uri baseUrl = Apihandler.baseUrl;

  Future<List<Cliente>> obtenerClientes() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Clientes'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> clientesJson = jsonDecode(response.body);
        return clientesJson.map((json) => Cliente.fromJson(json)).toList();
      } else {
        throw Exception(
            'Error al obtener los clientes. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al obtener los clientes: $e');
      rethrow;
    }
  }

  Future<Cliente> obtenerClientePorId(int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Clientes/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> clienteJson = jsonDecode(response.body);
        return Cliente.fromJson(clienteJson);
      } else {
        throw Exception(
            'Error al obtener el cliente. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al obtener el cliente: $e');
      rethrow;
    }
  }

  Future<Cliente> crearCliente(Cliente cliente) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/Clientes'),
        headers: headers,
        body: jsonEncode(cliente.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
            'Error al guardar el cliente. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      } else {
        debugPrint('Cliente guardado exitosamente');
        // Parsear la respuesta para obtener el cliente creado con el ID
        final clienteCreado = Cliente.fromJson(jsonDecode(response.body));
        return clienteCreado;
      }
    } catch (e) {
      debugPrint('Error al guardar el cliente: $e');
      rethrow;
    }
  }

  Future<void> editarCliente(Cliente cliente) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      final response = await Apihandler.client.put(
        Uri.parse('$baseUrl/Clientes/${cliente.id}'),
        headers: headers,
        body: jsonEncode(cliente.toJsonId()),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al editar el cliente. Código de estado: ${response.statusCode}');
      } else {
        debugPrint('Cliente editado exitosamente');
      }
    } catch (e) {
      debugPrint('Error al editar el cliente: $e');
      rethrow;
    }
  }

  Future<void> eliminarCliente(int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.delete(
        Uri.parse('$baseUrl/Clientes/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al eliminar el cliente. Código de estado: ${response.statusCode}');
      } else {
        debugPrint('Cliente eliminado exitosamente');
      }
    } catch (e) {
      debugPrint('Error al eliminar el cliente: $e');
      rethrow;
    }
  }

  Future<List<Cliente>> buscarClientes(String nombre) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await Apihandler.client.get(
      Uri.parse('$baseUrl/Clientes/buscar?query=$nombre'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Cliente.fromJson(json)).toList();
    } else {
      throw Exception('Error al buscar clientes');
    }
  }

  Future<List<Cliente>> obtenerClientesConDeuda() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Clientes/con-deuda'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> clientesJson = jsonDecode(response.body);
        return clientesJson.map((json) => Cliente.fromJson(json)).toList();
      } else {
        throw Exception(
            'Error al obtener los clientes. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al obtener los clientes: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerClientesPaginados(int page, int pageSize) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Clientes/paginados?page=$page&pageSize=$pageSize'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> clientesJson = data['clientes'];
        final List<Cliente> clientes = clientesJson.map((json) => Cliente.fromJson(json)).toList();
        
        return {
          'clientes': clientes,
          'totalCount': data['totalCount'],
          'page': data['page'],
          'pageSize': data['pageSize'],
          'totalPages': data['totalPages'],
          'hasNextPage': data['hasNextPage'],
          'hasPreviousPage': data['hasPreviousPage'],
        };
      } else {
        throw Exception(
            'Error al obtener los clientes paginados. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al obtener los clientes paginados: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerClientesConDeudaPaginados(int page, int pageSize) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Clientes/con-deuda/paginados?page=$page&pageSize=$pageSize'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> clientesJson = data['clientes'];
        final List<Cliente> clientes = clientesJson.map((json) => Cliente.fromJson(json)).toList();
        
        return {
          'clientes': clientes,
          'totalItems': data['totalItems'],
          'currentPage': data['currentPage'],
          'pageSize': data['pageSize'],
          'totalPages': data['totalPages'],
          'hasNextPage': data['hasNextPage'],
          'hasPreviousPage': data['hasPreviousPage'],
        };
      } else {
        throw Exception(
            'Error al obtener los clientes con deuda paginados. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al obtener los clientes con deuda paginados: $e');
      rethrow;
    }
  }
  
}
