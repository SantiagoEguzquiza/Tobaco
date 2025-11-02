import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/RecorridoProgramado.dart';
import 'package:tobaco/Models/DiaSemana.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';

class RecorridosProgramadosService {
  final Uri baseUrl = Apihandler.baseUrl;
  static const Duration _timeoutDuration = Duration(seconds: 10);

  /// Obtiene todos los recorridos programados de un vendedor
  Future<List<RecorridoProgramado>> obtenerRecorridosPorVendedor(int vendedorId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Uri.parse('$baseUrl/api/RecorridosProgramados/vendedor/$vendedorId'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> recorridosJson = jsonDecode(response.body);
        return recorridosJson.map((json) => RecorridoProgramado.fromJson(json)).toList();
      } else {
        throw Exception(
            'Error al obtener los recorridos. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al obtener los recorridos programados: $e');
      rethrow;
    }
  }

  /// Crea un nuevo recorrido programado
  Future<RecorridoProgramado> crearRecorrido({
    required int vendedorId,
    required int clienteId,
    required DiaSemana diaSemana,
    required int orden,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      
      final body = {
        'vendedorId': vendedorId,
        'clienteId': clienteId,
        'diaSemana': diaSemana.toJson(),
        'orden': orden,
        'activo': true,
      };

      final response = await Apihandler.client.post(
        Uri.parse('$baseUrl/api/RecorridosProgramados'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final recorridoJson = jsonDecode(response.body);
        return RecorridoProgramado.fromJson(recorridoJson);
      } else {
        throw Exception(
            'Error al crear el recorrido. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error al crear el recorrido programado: $e');
      rethrow;
    }
  }

  /// Actualiza un recorrido programado
  Future<RecorridoProgramado> actualizarRecorrido({
    required int id,
    int? clienteId,
    DiaSemana? diaSemana,
    int? orden,
    bool? activo,
  }) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      
      final body = <String, dynamic>{};
      if (clienteId != null) body['clienteId'] = clienteId;
      if (diaSemana != null) body['diaSemana'] = diaSemana.toJson();
      if (orden != null) body['orden'] = orden;
      if (activo != null) body['activo'] = activo;

      final response = await Apihandler.client.put(
        Uri.parse('$baseUrl/api/RecorridosProgramados/$id'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final recorridoJson = responseData['recorrido'] as Map<String, dynamic>;
        return RecorridoProgramado.fromJson(recorridoJson);
      } else {
        throw Exception(
            'Error al actualizar el recorrido. Código de estado: ${response.statusCode}, Respuesta: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error al actualizar el recorrido programado: $e');
      rethrow;
    }
  }

  /// Elimina un recorrido programado
  Future<bool> eliminarRecorrido(int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.delete(
        Uri.parse('$baseUrl/api/RecorridosProgramados/$id'),
        headers: headers,
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
            'Error al eliminar el recorrido. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al eliminar el recorrido programado: $e');
      rethrow;
    }
  }
}

