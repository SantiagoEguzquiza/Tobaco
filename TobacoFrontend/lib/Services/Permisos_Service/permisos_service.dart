import 'dart:convert';
import 'package:flutter/material.dart';
import '../../Helpers/api_handler.dart';
import '../../Models/PermisosEmpleado.dart';
import '../Auth_Service/auth_service.dart';

class PermisosService {
  static const String _permisosEndpoint = '/api/PermisosEmpleado';
  static const Duration _timeoutDuration = Duration(seconds: 10);

  /// Obtener permisos de un usuario (Admin only)
  static Future<PermisosEmpleado> getPermisosByUserId(int userId) async {
    try {
      final url = Apihandler.baseUrl.resolve('$_permisosEndpoint/usuario/$userId');
      final response = await Apihandler.client.get(
        url,
        headers: await _getAuthHeaders(),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final permisosJson = jsonDecode(response.body);
        return PermisosEmpleado.fromJson(permisosJson);
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para acceder a esta funcionalidad');
      } else if (response.statusCode == 404) {
        throw Exception('Permisos no encontrados para este usuario');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al obtener permisos');
      }
    } catch (e) {
      debugPrint('PermisosService: Error getting permisos: $e');
      throw Exception('Error al obtener permisos: $e');
    }
  }

  /// Actualizar permisos de un usuario (Admin only)
  static Future<PermisosEmpleado> updatePermisos(int userId, PermisosEmpleado permisos) async {
    try {
      final url = Apihandler.baseUrl.resolve('$_permisosEndpoint/usuario/$userId');
      final response = await Apihandler.client.put(
        url,
        headers: await _getAuthHeaders(),
        body: jsonEncode(permisos.toUpdateJson()),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final permisosJson = jsonDecode(response.body);
        return PermisosEmpleado.fromJson(permisosJson);
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para modificar permisos');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al actualizar permisos');
      }
    } catch (e) {
      debugPrint('PermisosService: Error updating permisos: $e');
      throw Exception('Error al actualizar permisos: $e');
    }
  }

  /// Obtener mis propios permisos (para empleados)
  static Future<PermisosEmpleado> getMisPermisos() async {
    try {
      final url = Apihandler.baseUrl.resolve('$_permisosEndpoint/mis-permisos');
      debugPrint('PermisosService.getMisPermisos: Llamando a $url');
      final headers = await _getAuthHeaders();
      debugPrint('PermisosService.getMisPermisos: Headers preparados');
      final response = await Apihandler.client.get(
        url,
        headers: headers,
      ).timeout(_timeoutDuration);
      debugPrint('PermisosService.getMisPermisos: Respuesta recibida - Status: ${response.statusCode}');
      
      if (response.statusCode == 401) {
        debugPrint('PermisosService.getMisPermisos: Error 401 - Body: ${response.body}');
        debugPrint('PermisosService.getMisPermisos: Error 401 - Headers enviados: ${headers.keys.toList()}');
      }

      if (response.statusCode == 200) {
        // Verificar que la respuesta sea JSON válido
        if (response.body.isEmpty) {
          throw Exception('Respuesta vacía del servidor');
        }
        
        try {
          final permisosJson = jsonDecode(response.body);
          debugPrint('PermisosService.getMisPermisos: JSON recibido: $permisosJson');
          final permisos = PermisosEmpleado.fromJson(permisosJson);
          debugPrint('PermisosService.getMisPermisos: Permisos parseados - productosVisualizar: ${permisos.productosVisualizar}');
          return permisos;
        } catch (e) {
          // Si no es JSON válido, probablemente es un mensaje de error de texto plano
          debugPrint('PermisosService: Respuesta no es JSON válido: ${response.body}');
          throw Exception('Respuesta inválida del servidor: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');
        }
      } else if (response.statusCode == 429) {
        // Rate limiting
        throw Exception('Demasiadas solicitudes. Por favor espera un momento e intenta nuevamente.');
      } else {
        // Intentar parsear como JSON, si falla usar el texto plano
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'Error al obtener permisos');
        } catch (e) {
          // Si no es JSON, usar el texto plano de la respuesta
          throw Exception(response.body.isNotEmpty 
              ? response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)
              : 'Error al obtener permisos (código: ${response.statusCode})');
        }
      }
    } catch (e) {
      debugPrint('PermisosService: Error getting mis permisos: $e');
      // Si ya es una Exception con mensaje, relanzarla
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error al obtener permisos: $e');
    }
  }

  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await AuthService.getToken();
    debugPrint('PermisosService._getAuthHeaders: Token ${token != null ? "presente (${token.length} chars)" : "NULL"}');
    
    if (token == null) {
      throw Exception('No hay token de autenticación. Por favor, inicia sesión nuevamente.');
    }
    
    // Log de los primeros y últimos caracteres del token para verificar formato
    if (token.length > 20) {
      debugPrint('PermisosService._getAuthHeaders: Token inicia con: ${token.substring(0, 10)}... termina con: ...${token.substring(token.length - 10)}');
    }
    
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    
    debugPrint('PermisosService._getAuthHeaders: Header Authorization: ${headers['Authorization']?.substring(0, 30)}...');
    
    return headers;
  }
}

