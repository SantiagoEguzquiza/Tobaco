import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Helpers/http_interceptor.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/VentasProductos.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';

class VentasService {
  final Uri baseUrl = Apihandler.baseUrl;
  static const Duration _timeoutDuration = Duration(seconds: 30); // Timeout normal para operaciones (aumentado para sincronización)
  static const Duration _timeoutRapidoDuration = Duration(seconds: 5); // Timeout más corto para refrescos rápidos (pull-to-refresh)

  Future<List<Ventas>> obtenerVentas({bool timeoutRapido = false, bool timeoutNormal = false}) async {
    try {
      Duration timeout = timeoutNormal ? _timeoutDuration : (timeoutRapido ? _timeoutRapidoDuration : _timeoutDuration);
      
      // Usar HttpInterceptor para manejar automáticamente refresh de token en caso de 401/403
      final response = await HttpInterceptor.interceptRequest(() async {
        final headers = await AuthService.getAuthHeaders();
        return await Apihandler.client.get(
          Uri.parse('$baseUrl/Ventas'),
          headers: headers,
        ).timeout(timeout);
      });

      

      // El interceptor debería haber manejado 401/403 antes de llegar aquí
      // Si llegamos aquí con 401/403, significa que el refresh falló
      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('⚠️ VentasService: Recibido ${response.statusCode} después del interceptor - refresh falló');
        // El interceptor ya debería haber hecho logout, pero por si acaso
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
      }
      
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

      final ventaJson = venta.toJson();

      // Asegurar que los pagos tengan id: 0 y ventaId: 0 para nuevas ventas
      if (ventaJson['ventaPagos'] != null && ventaJson['ventaPagos'] is List) {
        final pagos = ventaJson['ventaPagos'] as List;
        for (var i = 0; i < pagos.length; i++) {
          final pago = pagos[i];
          if (pago is Map<String, dynamic>) {
            pago['id'] = 0;
            pago['ventaId'] = 0;
          }
        }
      }

      debugPrint('📤 VentasService: Enviando POST a $baseUrl/Ventas');
      debugPrint('   fecha (UTC): ${ventaJson['fecha']}'); // Debe terminar en 'Z' para indicar UTC
      debugPrint('   ventaPagos: ${ventaJson['ventaPagos']}');
      debugPrint('   Timeout: ${customTimeout ?? _timeoutDuration}');

      final jsonBody = jsonEncode(ventaJson);
      debugPrint('   Tamaño del body: ${jsonBody.length} bytes');
      debugPrint('   Body (primeros 500 chars): ${jsonBody.length > 500 ? "${jsonBody.substring(0, 500)}..." : jsonBody}');
      
      // Validación adicional: verificar que la fecha termine en 'Z'
      if (ventaJson['fecha'] != null && !ventaJson['fecha'].toString().endsWith('Z')) {
        debugPrint('⚠️ ADVERTENCIA: La fecha NO está en formato UTC (no termina en Z): ${ventaJson['fecha']}');
      } else {
        debugPrint('✅ Fecha correctamente formateada en UTC: ${ventaJson['fecha']}');
      }
      
      final stopwatch = Stopwatch()..start();
      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/Ventas'),
        headers: headers,
        body: jsonBody,
      ).timeout(customTimeout ?? _timeoutDuration);
      stopwatch.stop();
      
      debugPrint('⏱️ VentasService: Tiempo de respuesta: ${stopwatch.elapsedMilliseconds}ms');

      debugPrint('📥 VentasService: Respuesta recibida del servidor');
      debugPrint('   Status Code: ${response.statusCode}');
      debugPrint('   Body: ${response.body}');
      debugPrint('   Headers: ${response.headers}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parsear la respuesta del servidor
        debugPrint('✅ VentasService: Status code es 200 o 201, parseando respuesta...');
        final responseData = jsonDecode(response.body);
        debugPrint('   ResponseData: $responseData');
        debugPrint('   ventaId: ${responseData['ventaId']}');
        debugPrint('   message: ${responseData['message']}');
        
        final result = {
          'ventaId': responseData['ventaId'],
          'message': responseData['message'] ?? 'Venta creada exitosamente',
          'asignada': responseData['asignada'] ?? false,
          'usuarioAsignadoId': responseData['usuarioAsignadoId'],
          'usuarioAsignadoNombre': responseData['usuarioAsignadoNombre'],
        };
        
        debugPrint('✅ VentasService: Retornando resultado: $result');
        return result;
      } else {
        debugPrint('❌ VentasService: Status code NO es 200/201');
        debugPrint('   Status Code recibido: ${response.statusCode}');
        debugPrint('   Body completo: ${response.body}');

        // Intentar parsear el error para obtener más detalles
        String errorDetails = response.body;
        String? innerException;
        String? validationErrorsText;
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson is Map<String, dynamic>) {
            if (errorJson.containsKey('message')) {
              errorDetails = errorJson['message'] as String;
              debugPrint('   Mensaje de error parseado: $errorDetails');
            }
            if (errorJson.containsKey('innerException')) {
              final inner = errorJson['innerException'];
              innerException = inner is String ? inner : inner.toString();
              debugPrint('   Inner Exception: $innerException');
            }
            if (errorJson.containsKey('errors') && errorJson['errors'] is Map) {
              final errors = errorJson['errors'] as Map<String, dynamic>;
              debugPrint('   Validation errors: $errors');
              final parts = <String>[];
              for (final entry in errors.entries) {
                final key = entry.key;
                final value = entry.value;
                if (value is List && value.isNotEmpty) {
                  parts.add('$key: ${value.join(', ')}');
                } else {
                  parts.add('$key: $value');
                }
              }
              validationErrorsText = parts.join('. ');
            }
          }
        } catch (parseError) {
          debugPrint('   No se pudo parsear el error: $parseError');
        }

        final bool isGenericEfMessage = errorDetails.contains('inner exception') &&
            errorDetails.contains('saving the entity changes');
        final String userMessage = validationErrorsText != null && validationErrorsText.isNotEmpty
            ? validationErrorsText
            : innerException != null && innerException.isNotEmpty
                ? innerException
                : isGenericEfMessage
                    ? 'No se pudo guardar en el servidor. La venta se guardó localmente; puedes sincronizar después.'
                    : errorDetails;
        final String fullMsg = (validationErrorsText != null || innerException != null || isGenericEfMessage)
            ? userMessage
            : 'Error al guardar la venta (${response.statusCode}). $userMessage';
        debugPrint('   Error final: $fullMsg');
        throw Exception(fullMsg);
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('guardó localmente') || msg.contains('guardar en el servidor')) {
        debugPrint('VentasService: Servidor rechazó la venta (se guardará local). $msg');
      } else {
        debugPrint('❌ VentasService: Excepción al guardar venta: $e');
      }
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
          if (dateFrom != null) 'dateFrom': dateFrom.toUtc().toIso8601String(),
          if (dateTo != null) 'dateTo': dateTo.toUtc().toIso8601String(),
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
