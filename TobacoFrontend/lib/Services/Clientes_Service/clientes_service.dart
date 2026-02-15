import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';
import 'package:tobaco/Services/Cache/datos_cache_service.dart';

class ClienteService {
  final Uri baseUrl = Apihandler.baseUrl;
  static const Duration _timeoutDuration = Duration(seconds: 3); // Timeout razonable para detectar offline
  final DatosCacheService _cacheService = DatosCacheService();

  Future<List<Cliente>> obtenerClientes() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Clientes'),
        headers: headers,
      ).timeout(_timeoutDuration);

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
      ).timeout(_timeoutDuration);

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
      ).timeout(_timeoutDuration);

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
      ).timeout(_timeoutDuration);

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
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        debugPrint('Cliente eliminado exitosamente');
        return;
      }
      // Leer mensaje del backend (400/404 suelen traer { "message": "..." })
      String message = 'Error al eliminar el cliente. Código de estado: ${response.statusCode}';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] != null) {
          message = body['message'] as String;
        }
      } catch (_) {}
      throw Exception(message);
    } catch (e) {
      debugPrint('Error al eliminar el cliente: $e');
      rethrow;
    }
  }

  Future<List<Cliente>> buscarClientes(String nombre) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Clientes/buscar?query=$nombre'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Cliente.fromJson(json)).toList();
      } else {
        throw Exception('Error al buscar clientes');
      }
    } catch (e) {
      debugPrint('Error al buscar clientes: $e');
      rethrow;
    }
  }

  Future<List<Cliente>> obtenerClientesConDeuda() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Clientes/con-deuda'),
        headers: headers,
      ).timeout(_timeoutDuration);

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
    print('📡 ClienteService: Intentando obtener clientes paginados del servidor...');
    
    try {
      // Intentar obtener del servidor con timeout
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Clientes/paginados?page=$page&pageSize=$pageSize'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> clientesJson = data['clientes'];
        final List<Cliente> clientes = clientesJson.map((json) => Cliente.fromJson(json)).toList();
        
        print('✅ ClienteService: ${clientes.length} clientes obtenidos del servidor');
        
        // NO guardar aquí - el provider maneja la actualización completa del caché
        // para asegurar que siempre refleje TODOS los clientes del servidor
        
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
      print('⚠️ ClienteService: Error obteniendo del servidor: $e');
      print('📦 ClienteService: Cargando clientes del caché...');
      
      // Si falla, cargar del caché
      final clientesCache = await _cacheService.obtenerClientesDelCache();
      
      if (clientesCache.isEmpty) {
        print('❌ ClienteService: No hay clientes en caché');
        debugPrint('Error al obtener los clientes paginados: $e');
        rethrow;
      }
      
      print('✅ ClienteService: ${clientesCache.length} clientes cargados del caché');
      
      // Paginar manualmente desde el caché
      final start = (page - 1) * pageSize;
      final end = start + pageSize;
      final clientesPag = clientesCache.sublist(
        start,
        end > clientesCache.length ? clientesCache.length : end,
      );
      
      return {
        'clientes': clientesPag,
        'totalCount': clientesCache.length,
        'page': page,
        'pageSize': pageSize,
        'totalPages': (clientesCache.length / pageSize).ceil(),
        'hasNextPage': end < clientesCache.length,
        'hasPreviousPage': page > 1,
      };
    }
  }

  Future<Map<String, dynamic>> obtenerClientesConDeudaPaginados(int page, int pageSize) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Clientes/con-deuda/paginados?page=$page&pageSize=$pageSize'),
        headers: headers,
      ).timeout(_timeoutDuration);

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

  Future<Map<String, dynamic>> obtenerDetalleDeuda(int clienteId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Clientes/$clienteId/deuda'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Error al obtener el detalle de deuda. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al obtener el detalle de deuda: $e');
      rethrow;
    }
  }

  /// Obtiene o crea el cliente "Consumidor Final" del tenant actual
  Future<Cliente> obtenerOCrearConsumidorFinal() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Clientes/consumidor-final'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> clienteJson = jsonDecode(response.body);
        return Cliente.fromJson(clienteJson);
      }
      String msg = 'Error al obtener o crear Consumidor Final (${response.statusCode})';
      if (response.body.isNotEmpty) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>?;
          if (data != null && data['message'] != null) {
            msg = data['message'] as String;
          }
        } catch (_) {}
      }
      throw Exception(msg);
    } catch (e) {
      debugPrint('Error al obtener o crear Consumidor Final: $e');
      rethrow;
    }
  }
  
}
