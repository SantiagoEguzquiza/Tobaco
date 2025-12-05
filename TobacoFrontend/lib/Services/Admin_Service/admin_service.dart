import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/User.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';

class AdminService {
  final Uri baseUrl = Apihandler.baseUrl;
  static const Duration _timeoutDuration = Duration(seconds: 10);

  Future<List<User>> obtenerAdminsPorTenant(int tenantId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/SuperAdmin/tenants/$tenantId/admins');
      
      debugPrint('AdminService: Obteniendo administradores para tenant $tenantId');
      debugPrint('AdminService: URL: $url');
      
      final response = await Apihandler.client.get(
        url,
        headers: headers,
      ).timeout(_timeoutDuration);

      debugPrint('AdminService: Status code: ${response.statusCode}');
      debugPrint('AdminService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> adminsJson = jsonDecode(response.body);
        debugPrint('AdminService: Se encontraron ${adminsJson.length} administradores');
        final admins = adminsJson.map((json) => User.fromJson(json)).toList();
        return admins;
      } else if (response.statusCode == 404) {
        debugPrint('AdminService: No se encontraron administradores (404)');
        return []; // Retornar lista vacía en lugar de lanzar error
      } else {
        String errorMessage = 'Error al obtener los administradores. Código de estado: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Error ${response.statusCode}: ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('AdminService: Error al obtener los administradores: $e');
      debugPrint('AdminService: Error tipo: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<User> crearAdmin(int tenantId, {
    required String userName,
    required String password,
    String? email,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final createData = <String, dynamic>{
        'userName': userName,
        'password': password,
        'role': 'Admin',
      };
      
      if (email != null && email.isNotEmpty) {
        createData['email'] = email;
      }

      debugPrint('Creando admin para tenant $tenantId');
      debugPrint('Datos: ${jsonEncode(createData)}');
      debugPrint('URL: $baseUrl/api/SuperAdmin/tenants/$tenantId/admins');

      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/api/SuperAdmin/tenants/$tenantId/admins'),
        headers: headers,
        body: jsonEncode(createData),
      ).timeout(_timeoutDuration);

      debugPrint('Respuesta del servidor: ${response.statusCode}');
      debugPrint('Body de respuesta: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> adminJson = jsonDecode(response.body);
        return User.fromJson(adminJson);
      } else {
        String errorMessage = 'Error al crear el administrador';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData.toString();
          if (errorData['errors'] != null) {
            debugPrint('Errores de validación: ${errorData['errors']}');
          }
        } catch (e) {
          errorMessage = 'Error ${response.statusCode}: ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error al crear el administrador: $e');
      rethrow;
    }
  }

  Future<User> actualizarAdmin(int tenantId, int adminId, {
    String? userName,
    String? password,
    String? email,
    bool? isActive,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final updateData = <String, dynamic>{};
      if (userName != null) updateData['userName'] = userName;
      if (password != null) updateData['password'] = password;
      if (email != null) updateData['email'] = email;
      if (isActive != null) updateData['isActive'] = isActive;

      final response = await Apihandler.client.put(
        Uri.parse('$baseUrl/api/SuperAdmin/tenants/$tenantId/admins/$adminId'),
        headers: headers,
        body: jsonEncode(updateData),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> adminJson = jsonDecode(response.body);
        return User.fromJson(adminJson);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al actualizar el administrador');
      }
    } catch (e) {
      debugPrint('Error al actualizar el administrador: $e');
      rethrow;
    }
  }

  Future<void> eliminarAdmin(int tenantId, int adminId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.delete(
        Uri.parse('$baseUrl/api/SuperAdmin/tenants/$tenantId/admins/$adminId'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al eliminar el administrador');
      }
    } catch (e) {
      debugPrint('Error al eliminar el administrador: $e');
      rethrow;
    }
  }
}

