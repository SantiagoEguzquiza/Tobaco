import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';

class VentasService {
  final Uri baseUrl = Apihandler.baseUrl;
  static const Duration _timeoutDuration = Duration(seconds: 10); // Timeout normal para operaciones
  static const Duration _timeoutRapidoDuration = Duration(milliseconds: 500); // Timeout rápido para detección offline

  Future<List<Ventas>> obtenerVentas({bool timeoutRapido = false, bool timeoutNormal = false}) async {
    try {
      
      
      final headers = await AuthService.getAuthHeaders();
      
      Duration timeout = timeoutNormal ? _timeoutDuration : (timeoutRapido ? _timeoutRapidoDuration : _timeoutDuration);
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Ventas'),
        headers: headers,
      ).timeout(timeout);

      

      if (response.statusCode == 200) {
        final List<dynamic> ventasJson = jsonDecode(response.body);
        
        
        
        if (ventasJson.isEmpty) {
        }
        
        final ventas = ventasJson.map((json) {
          return Ventas.fromJson(json);
        }).toList();
        
        
        return ventas;
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

  Future<Map<String, dynamic>> crearVenta(Ventas venta, {Duration? customTimeout}) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      
      // Debug: Imprimir los datos que se están enviando
      final ventaJson = venta.toJson();
      
      
      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/Ventas'),
        headers: headers,
        body: jsonEncode(ventaJson),
      ).timeout(customTimeout ?? _timeoutDuration);

      

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parsear la respuesta del servidor
        final responseData = jsonDecode(response.body);
        return {
          'ventaId': responseData['ventaId'],
          'message': responseData['message'] ?? 'Venta creada exitosamente',
          'asignada': responseData['asignada'] ?? false,
          'usuarioAsignadoId': responseData['usuarioAsignadoId'],
          'usuarioAsignadoNombre': responseData['usuarioAsignadoNombre'],
        };
      } else {
        throw Exception(
            'Error al guardar la venta. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error al guardar la venta: $e');
      rethrow;
    }
  }

  /// Asigna una venta a un usuario
  Future<void> asignarVenta(int ventaId, int usuarioId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/Ventas/asignar'),
        headers: headers,
        body: jsonEncode({
          'ventaId': ventaId,
          'usuarioId': usuarioId,
        }),
      ).timeout(_timeoutDuration);

      if (response.statusCode != 200) {
        throw Exception(
            'Error al asignar la venta. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error al asignar la venta: $e');
      rethrow;
    }
  }

  /// Asigna una venta automáticamente a otro repartidor (excluyendo al usuario actual)
  Future<Map<String, dynamic>> asignarVentaAutomaticamente(int ventaId, int usuarioIdExcluir) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/Ventas/asignar-automaticamente'),
        headers: headers,
        body: jsonEncode({
          'ventaId': ventaId,
          'usuarioIdExcluir': usuarioIdExcluir,
        }),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'asignada': responseData['asignada'] ?? false,
          'usuarioAsignadoId': responseData['usuarioAsignadoId'],
          'usuarioAsignadoNombre': responseData['usuarioAsignadoNombre'],
          'message': responseData['message'] ?? 'Venta asignada exitosamente',
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al asignar la venta automáticamente');
      }
    } catch (e) {
      debugPrint('Error al asignar la venta automáticamente: $e');
      rethrow;
    }
  }

  Future<void> eliminarVenta(int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.delete(
        Uri.parse('$baseUrl/Ventas/$id'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode != 200) {
        throw Exception(
            'Error al eliminar la venta. Código de estado: ${response.statusCode}');
      } else {
        
      }
    } catch (e) {
      debugPrint('Error al eliminar la venta: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerVentasPaginadas(int page, int pageSize) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Ventas/paginados?page=$page&pageSize=$pageSize'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> ventasJson = data['ventas'];
        final List<Ventas> ventas = ventasJson.map((json) => Ventas.fromJson(json)).toList();
        
        return {
          'ventas': ventas,
          'totalItems': data['totalItems'],
          'totalPages': data['totalPages'],
          'currentPage': data['currentPage'],
          'pageSize': data['pageSize'],
          'hasNextPage': data['hasNextPage'],
          'hasPreviousPage': data['hasPreviousPage'],
        };
      } else {
        throw Exception(
            'Error al obtener las ventas paginadas. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al obtener las ventas paginadas: $e');
      rethrow;
    }
  }

  Future<Ventas> obtenerVentaPorId(int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Ventas/$id'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> ventaJson = jsonDecode(response.body);
        return Ventas.fromJson(ventaJson);
      } else {
        throw Exception(
            'Error al obtener la venta. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al obtener la venta: $e');
      rethrow;
    }
  }

  Future<Ventas> obtenerUltimaVenta() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Ventas'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> ventasJson = jsonDecode(response.body);
        
        if (ventasJson.isEmpty) {
          throw Exception('No hay ventas disponibles');
        }
        
        // Ordenar por fecha descendente y tomar la primera (más reciente)
        ventasJson.sort((a, b) {
          final fechaA = DateTime.parse(a['fecha']);
          final fechaB = DateTime.parse(b['fecha']);
          return fechaB.compareTo(fechaA);
        });
        
        return Ventas.fromJson(ventasJson.first);
      } else {
        throw Exception(
            'Error al obtener la última venta. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al obtener la última venta: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerVentasPorCliente(
    int clienteId, {
    int pageNumber = 1,
    int pageSize = 10,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      
      // Construir la URL con parámetros de consulta
      final uri = Uri.parse('$baseUrl/Ventas/por-cliente/$clienteId').replace(
        queryParameters: {
          'pageNumber': pageNumber.toString(),
          'pageSize': pageSize.toString(),
          if (dateFrom != null) 'dateFrom': dateFrom.toIso8601String(),
          if (dateTo != null) 'dateTo': dateTo.toIso8601String(),
        },
      );
      
      final response = await Apihandler.client.get(
        uri,
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> ventasJson = data['ventas'];
        final List<Ventas> ventas = ventasJson.map((json) => Ventas.fromJson(json)).toList();
        
        return {
          'ventas': ventas,
          'totalItems': data['totalItems'],
          'totalPages': data['totalPages'],
          'currentPage': data['currentPage'],
          'pageSize': data['pageSize'],
          'hasNextPage': data['hasNextPage'],
          'hasPreviousPage': data['hasPreviousPage'],
        };
      } else {
        throw Exception(
            'Error al obtener las ventas del cliente. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al obtener las ventas del cliente: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> obtenerVentasCuentaCorrientePorClienteId(
    int clienteId, 
    int page, 
    int pageSize
  ) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Clientes/$clienteId/ventas-cc?page=$page&pageSize=$pageSize'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> ventasJson = data['ventas'];
        final List<Ventas> ventas = ventasJson.map((json) => Ventas.fromJson(json)).toList();
        
        return {
          'ventas': ventas,
          'totalItems': data['totalItems'],
          'totalPages': data['totalPages'],
          'currentPage': data['currentPage'],
          'pageSize': data['pageSize'],
          'hasNextPage': data['hasNextPage'],
          'hasPreviousPage': data['hasPreviousPage'],
        };
      } else {
        throw Exception(
            'Error al obtener las ventas con cuenta corriente. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al obtener las ventas con cuenta corriente: $e');
      rethrow;
    }
  }

  Future<void> actualizarEstadoEntrega(int ventaId, List<VentasProductos> items) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      
      // Convertir la lista de items a JSON
      final itemsJson = items.map((item) => item.toJson()).toList();
      
      debugPrint('Actualizando estado de entrega para venta $ventaId');
      debugPrint('Items: ${jsonEncode(itemsJson)}');
      
      final response = await Apihandler.client.put(
        Uri.parse('$baseUrl/Ventas/$ventaId/estado-entrega'),
        headers: headers,
        body: jsonEncode(itemsJson),
      ).timeout(_timeoutDuration);

      debugPrint('Respuesta del servidor: ${response.statusCode}');
      debugPrint('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'Error al actualizar estado de entrega. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      } else {
        debugPrint('Estado de entrega actualizado exitosamente');
      }
    } catch (e) {
      debugPrint('Error al actualizar estado de entrega: $e');
      rethrow;
    }
  }
}
