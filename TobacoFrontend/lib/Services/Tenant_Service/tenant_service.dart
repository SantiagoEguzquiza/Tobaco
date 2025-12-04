import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Tenant.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';

class TenantService {
  final Uri baseUrl = Apihandler.baseUrl;
  static const Duration _timeoutDuration = Duration(seconds: 10);

  Future<List<Tenant>> obtenerTenants() async {
    try {
      final token = await AuthService.getToken();
      debugPrint('Token obtenido: ${token != null ? "Token presente (${token.length} chars)" : "Token NULL"}');
      
      final headers = await AuthService.getAuthHeaders();
      debugPrint('Headers: $headers');
      
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/api/SuperAdmin/tenants'),
        headers: headers,
      ).timeout(_timeoutDuration);

      debugPrint('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> tenantsJson = jsonDecode(response.body);
        return tenantsJson.map((json) => Tenant.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else {
        throw Exception(
            'Error al obtener los tenants. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al obtener los tenants: $e');
      rethrow;
    }
  }

  Future<Tenant> obtenerTenantPorId(int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/api/SuperAdmin/tenants/$id'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> tenantJson = jsonDecode(response.body);
        return Tenant.fromJson(tenantJson);
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else {
        throw Exception(
            'Error al obtener el tenant. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al obtener el tenant: $e');
      rethrow;
    }
  }

  Future<Tenant> crearTenant(Tenant tenant) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      
      final createData = {
        'nombre': tenant.nombre,
        'descripcion': tenant.descripcion,
        'email': tenant.email,
        'telefono': tenant.telefono,
      };

      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/api/SuperAdmin/tenants'),
        headers: headers,
        body: jsonEncode(createData),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> tenantJson = jsonDecode(response.body);
        return Tenant.fromJson(tenantJson);
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al crear el tenant');
      }
    } catch (e) {
      debugPrint('Error al crear el tenant: $e');
      rethrow;
    }
  }

  Future<Tenant> actualizarTenant(int id, Tenant tenant) async {
    try {
      final headers = await AuthService.getAuthHeaders();

      final response = await Apihandler.client.put(
        Uri.parse('$baseUrl/api/SuperAdmin/tenants/$id'),
        headers: headers,
        body: jsonEncode(tenant.toUpdateJson()),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> tenantJson = jsonDecode(response.body);
        return Tenant.fromJson(tenantJson);
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al actualizar el tenant');
      }
    } catch (e) {
      debugPrint('Error al actualizar el tenant: $e');
      rethrow;
    }
  }

  Future<void> eliminarTenant(int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.delete(
        Uri.parse('$baseUrl/api/SuperAdmin/tenants/$id'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al eliminar el tenant');
      }
    } catch (e) {
      debugPrint('Error al eliminar el tenant: $e');
      rethrow;
    }
  }
}

