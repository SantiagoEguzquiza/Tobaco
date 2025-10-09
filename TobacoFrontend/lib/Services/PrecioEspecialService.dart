import 'dart:convert';
import '../Models/PrecioEspecial.dart';
import '../Helpers/api_handler.dart';
import '../Services/Auth_Service/auth_service.dart';

class PrecioEspecialService {
  static final Uri _baseUrl = Apihandler.baseUrl;
  static const String _endpoint = 'preciosespeciales';
  static const Duration _timeoutDuration = Duration(seconds: 10);

  // Obtener todos los precios especiales
  static Future<List<PrecioEspecial>> getAllPreciosEspeciales() async {
    try {
      final response = await Apihandler.client.get(
        Uri.parse('$_baseUrl/$_endpoint'),
        headers: await AuthService.getAuthHeaders(),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PrecioEspecial.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener precios especiales: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener precio especial por ID
  static Future<PrecioEspecial?> getPrecioEspecialById(int id) async {
    try {
      final response = await Apihandler.client.get(
        Uri.parse('$_baseUrl/$_endpoint/$id'),
        headers: await AuthService.getAuthHeaders(),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return PrecioEspecial.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Error al obtener precio especial: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener precios especiales por cliente
  static Future<List<PrecioEspecial>> getPreciosEspecialesByCliente(int clienteId) async {
    try {
      final response = await Apihandler.client.get(
        Uri.parse('$_baseUrl/$_endpoint/cliente/$clienteId'),
        headers: await AuthService.getAuthHeaders(),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PrecioEspecial.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener precios especiales del cliente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener precio especial por cliente y producto
  static Future<PrecioEspecial?> getPrecioEspecialByClienteAndProducto(int clienteId, int productoId) async {
    try {
      final response = await Apihandler.client.get(
        Uri.parse('$_baseUrl/$_endpoint/cliente/$clienteId/producto/$productoId'),
        headers: await AuthService.getAuthHeaders(),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return PrecioEspecial.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Error al obtener precio especial: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener precio final de un producto (especial si existe, estándar si no)
  static Future<double> getPrecioFinalProducto(int clienteId, int productoId) async {
    try {
      final response = await Apihandler.client.get(
        Uri.parse('$_baseUrl/$_endpoint/precio-final/cliente/$clienteId/producto/$productoId'),
        headers: await AuthService.getAuthHeaders(),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['precio'] as num).toDouble();
      } else {
        throw Exception('Error al obtener precio del producto: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear nuevo precio especial
  static Future<PrecioEspecial> createPrecioEspecial(PrecioEspecial precioEspecial) async {
    try {
      final response = await Apihandler.client.post(
        Uri.parse('$_baseUrl/$_endpoint'),
        headers: await AuthService.getAuthHeaders(),
        body: json.encode(precioEspecial.toJson()),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PrecioEspecial.fromJson(data);
      } else {
        throw Exception('Error al crear precio especial: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar precio especial
  static Future<PrecioEspecial> updatePrecioEspecial(PrecioEspecial precioEspecial) async {
    try {
      final response = await Apihandler.client.put(
        Uri.parse('$_baseUrl/$_endpoint/${precioEspecial.id}'),
        headers: await AuthService.getAuthHeaders(),
        body: json.encode(precioEspecial.toJson()),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PrecioEspecial.fromJson(data);
      } else {
        throw Exception('Error al actualizar precio especial: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar precio especial por ID
  static Future<bool> deletePrecioEspecial(int id) async {
    try {
      final response = await Apihandler.client.delete(
        Uri.parse('$_baseUrl/$_endpoint/$id'),
        headers: await AuthService.getAuthHeaders(),
      ).timeout(_timeoutDuration);

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Eliminar precio especial por cliente y producto
  static Future<bool> deletePrecioEspecialByClienteAndProducto(int clienteId, int productoId) async {
    try {
      final response = await Apihandler.client.delete(
        Uri.parse('$_baseUrl/$_endpoint/cliente/$clienteId/producto/$productoId'),
        headers: await AuthService.getAuthHeaders(),
      ).timeout(_timeoutDuration);

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Upsert precio especial (crear o actualizar)
  static Future<bool> upsertPrecioEspecial(int clienteId, int productoId, double precio) async {
    try {
      final requestBody = {
        'clienteId': clienteId,
        'productoId': productoId,
        'precio': precio,
      };

      final response = await Apihandler.client.post(
        Uri.parse('$_baseUrl/$_endpoint/upsert'),
        headers: await AuthService.getAuthHeaders(),
        body: json.encode(requestBody),
      ).timeout(_timeoutDuration);

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
