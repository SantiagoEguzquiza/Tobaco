import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Abono.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';

class AbonosService {
  final Uri baseUrl = Apihandler.baseUrl;

  Future<List<Abono>> obtenerAbonos() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Abonos'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> abonosJson = jsonDecode(response.body);
        return abonosJson.map((json) => Abono.fromJson(json)).toList();
      } else {
        throw Exception(
          'Error al obtener los abonos. Código de estado: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error al obtener los abonos: $e');
      rethrow;
    }
  }

  Future<Abono> obtenerAbonoPorId(int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Abonos/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> abonoJson = jsonDecode(response.body);
        return Abono.fromJson(abonoJson);
      } else {
        throw Exception(
          'Error al obtener el abono. Código de estado: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error al obtener el abono: $e');
      rethrow;
    }
  }

  Future<List<Abono>> obtenerAbonosPorClienteId(int clienteId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/Abonos/cliente/$clienteId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> abonosJson = jsonDecode(response.body);
        return abonosJson.map((json) => Abono.fromJson(json)).toList();
      } else {
        throw Exception(
          'Error al obtener los abonos del cliente. Código de estado: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error al obtener los abonos del cliente: $e');
      rethrow;
    }
  }

  Future<Abono> crearAbono(Abono abono) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      
      final abonoJson = abono.toJson();
      debugPrint('Enviando abono: ${jsonEncode(abonoJson)}');
      
      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/Abonos'),
        headers: headers,
        body: jsonEncode(abonoJson),
      );

      debugPrint('Respuesta del servidor: ${response.statusCode}');
      debugPrint('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> abonoCreadoJson = jsonDecode(response.body);
        return Abono.fromJson(abonoCreadoJson);
      } else {
        throw Exception(
            'Error al crear el abono. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error al crear el abono: $e');
      rethrow;
    }
  }

  Future<void> actualizarAbono(Abono abono) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await Apihandler.client.put(
        Uri.parse('$baseUrl/Abonos/${abono.id}'),
        headers: headers,
        body: jsonEncode(abono.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al actualizar el abono. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al actualizar el abono: $e');
      rethrow;
    }
  }

  Future<void> eliminarAbono(int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.delete(
        Uri.parse('$baseUrl/Abonos/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Error al eliminar el abono. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al eliminar el abono: $e');
      rethrow;
    }
  }

  // Método para saldar deuda usando el endpoint del ClientesController
  Future<Abono> saldarDeuda(int clienteId, double monto, DateTime fecha, String? nota) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      
      final body = {
        'monto': monto,
        'fecha': fecha.toIso8601String(),
        'nota': nota ?? '',
      };
      
      debugPrint('Enviando saldar deuda: ${jsonEncode(body)}');
      
      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/Clientes/$clienteId/saldarDeuda'),
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('Respuesta del servidor: ${response.statusCode}');
      debugPrint('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> abonoCreadoJson = jsonDecode(response.body);
        return Abono.fromJson(abonoCreadoJson);
      } else {
        throw Exception(
            'Error al saldar la deuda. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error al saldar la deuda: $e');
      rethrow;
    }
  }
}
