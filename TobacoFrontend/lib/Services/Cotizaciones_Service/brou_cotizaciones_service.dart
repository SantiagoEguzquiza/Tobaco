import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

/// Servicio para obtener cotizaciones del Banco República (BROU)
/// API: https://uruguayapi.onrender.com/api/v1/banks/brou_rates
class BrouCotizacionesService {
  static const _baseUrl = 'https://uruguayapi.onrender.com';
  static const _endpoint = '/api/v1/banks/brou_rates';

  /// Parsea valores numéricos del BROU (ej: "39,10000" o "2.085,00000")
  static double? _parseBrouValue(String? s) {
    if (s == null || s.isEmpty || s == '-') return null;
    final cleaned = s.trim().replaceAll(' ', '');
    if (cleaned == '-') return null;
    // Formato: "39,10000" (coma decimal) o "2.085,00000" (punto miles, coma decimal)
    final parts = cleaned.split(',');
    if (parts.length == 2) {
      final intPart = parts[0].replaceAll('.', '');
      final decPart = parts[1];
      final combined = '$intPart.$decPart';
      return double.tryParse(combined);
    }
    return double.tryParse(cleaned.replaceAll(',', '.'));
  }

  /// Obtiene las cotizaciones actuales del BROU
  /// Retorna un Map: clave = codigo ISO (USD, EUR, ARS, BRL), valor = Map con bid/ask
  static Future<Map<String, Map<String, double?>>> getBrouRates() async {
    try {
      final uri = Uri.parse('$_baseUrl$_endpoint');
      final resp = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'TobacoApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        throw Exception(
            'Error del servidor: ${resp.statusCode}. ${resp.body.isNotEmpty ? resp.body.substring(0, resp.body.length.clamp(0, 200)) : ""}');
      }

      final body = resp.body.trim();
      if (body.isEmpty) {
        throw Exception('La API no devolvió datos');
      }

      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) {
        throw Exception('Estructura de respuesta inválida');
      }

      // Mapeo: clave BROU -> código ISO (una fuente por moneda)
      const mapping = {
        'dolar': 'USD',
        'euro': 'EUR',
        'peso_argentino': 'ARS',
        'real': 'BRL',
      };

      final result = <String, Map<String, double?>>{};
      for (final entry in mapping.entries) {
        final brouKey = entry.key;
        final iso = entry.value;
        if (!json.containsKey(brouKey)) continue;

        final data = json[brouKey];
        if (data is! Map<String, dynamic>) continue;

        final bid = _parseBrouValue(data['bid']?.toString());
        final ask = _parseBrouValue(data['ask']?.toString());

        if (bid == null && ask == null) continue;

        result[iso] = {'bid': bid, 'ask': ask};
      }

      if (result.isEmpty) {
        throw Exception('No se encontraron cotizaciones válidas en la respuesta');
      }

      developer.log('BrouCotizacionesService: ${result.length} monedas obtenidas');
      return result;
    } on SocketException {
      developer.log('BrouCotizacionesService: Sin conexión de red');
      throw Exception('No hay conexión a internet. Verificá tu conexión.');
    } on TimeoutException {
      developer.log('BrouCotizacionesService: Timeout');
      throw Exception('El servidor tardó demasiado en responder. Probá de nuevo.');
    } on FormatException catch (e) {
      developer.log('BrouCotizacionesService: JSON inválido - $e');
      throw Exception('La respuesta de la API tiene un formato inválido');
    } on http.ClientException catch (e) {
      developer.log('BrouCotizacionesService: Error de cliente HTTP - $e');
      throw Exception('Error de conexión: ${e.message}');
    } on Exception catch (e) {
      developer.log('Error en BrouCotizacionesService: $e');
      rethrow;
    } catch (e) {
      developer.log('Error inesperado en BrouCotizacionesService: $e');
      throw Exception('Error inesperado al obtener cotizaciones');
    }
  }
}
