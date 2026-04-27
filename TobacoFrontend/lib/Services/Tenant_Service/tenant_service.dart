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

  /// Obtiene el tenant del usuario autenticado.
  ///
  /// Pega contra `/api/Tenant/me`, que resuelve el tenant a partir del JWT.
  /// Es el endpoint que deben usar los Admins (no SuperAdmins) para administrar
  /// la configuración de su propia empresa.
  Future<Tenant> obtenerMiTenant() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/Tenant/me');
      debugPrint('GET $url');

      final response = await Apihandler.client.get(
        url,
        headers: headers,
      ).timeout(_timeoutDuration);

      debugPrint('GET /api/Tenant/me -> ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> tenantJson = jsonDecode(response.body);
        return Tenant.fromJson(tenantJson);
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else {
        debugPrint('Body: ${response.body}');
        throw Exception(_extractErrorMessage(
          response.body,
          fallback:
              'Error al obtener el tenant (HTTP ${response.statusCode}).',
        ));
      }
    } catch (e) {
      debugPrint('Error al obtener mi tenant: $e');
      rethrow;
    }
  }

  /// Actualiza el tenant del usuario autenticado.
  ///
  /// Pega contra `/api/Tenant/me`, que resuelve el tenant a partir del JWT.
  Future<Tenant> actualizarMiTenant(Tenant tenant) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final url = Uri.parse('$baseUrl/api/Tenant/me');
      final body = jsonEncode(tenant.toUpdateJson());
      debugPrint('PUT $url body=$body');

      final response = await Apihandler.client.put(
        url,
        headers: headers,
        body: body,
      ).timeout(_timeoutDuration);

      debugPrint('PUT /api/Tenant/me -> ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> tenantJson = jsonDecode(response.body);
        return Tenant.fromJson(tenantJson);
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else {
        debugPrint('Body: ${response.body}');
        throw Exception(_extractErrorMessage(
          response.body,
          fallback:
              'Error al actualizar el tenant (HTTP ${response.statusCode}).',
        ));
      }
    } catch (e) {
      debugPrint('Error al actualizar mi tenant: $e');
      rethrow;
    }
  }

  /// Intenta sacar un mensaje legible del body JSON del backend.
  /// Soporta tanto `{ "message": "..." }` (formato custom) como
  /// el ProblemDetails de ASP.NET Core (`{ "title": "...", "detail": "..." }`).
  String _extractErrorMessage(String body, {required String fallback}) {
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ??
            decoded['detail'] ??
            decoded['title'] ??
            decoded['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
        if (decoded['errors'] is Map) {
          final firstErrorList = (decoded['errors'] as Map).values.first;
          if (firstErrorList is List && firstErrorList.isNotEmpty) {
            return firstErrorList.first.toString();
          }
        }
      }
    } catch (_) {
      // body no es JSON; usamos el fallback.
    }
    return fallback;
  }

  /// Atajo para activar/desactivar el control de stock global del tenant actual.
  Future<Tenant> actualizarControlDeStockGlobal(
    Tenant tenantActual,
    bool nuevoValor,
  ) async {
    final actualizado = tenantActual.copyWith(
      stockControlEnabledByDefault: nuevoValor,
    );
    return actualizarMiTenant(actualizado);
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

