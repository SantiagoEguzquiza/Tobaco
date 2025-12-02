import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class BcuCotizacionesService {
  static const _endpoint =
      'https://cotizaciones.bcu.gub.uy/wscotizaciones/servlet/awsbcucotizaciones';
  static const _wsdlEndpoint =
      'https://cotizaciones.bcu.gub.uy/wscotizaciones/servlet/awsbcucotizaciones?wsdl';

  static String _envelope({
    required List<int> monedas,
    required DateTime desde,
    required DateTime hasta,
    required int grupo,
  }) {
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final items = monedas.map((m) => '<cot:item>$m</cot:item>').join();
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:cot="Cotiza">
  <soapenv:Header/>
  <soapenv:Body>
    <cot:wsbcucotizaciones.Execute>
      <cot:Entrada>
        <cot:Moneda>$items</cot:Moneda>
        <cot:FechaDesde>${fmt(desde)}</cot:FechaDesde>
        <cot:FechaHasta>${fmt(hasta)}</cot:FechaHasta>
        <cot:Grupo>$grupo</cot:Grupo>
      </cot:Entrada>
    </cot:wsbcucotizaciones.Execute>
  </soapenv:Body>
</soapenv:Envelope>''';
  }

  // Método SOAP correcto para obtener TODAS las cotizaciones
  static Future<String> getCotizacionesCompletas({
    required DateTime desde,
    required DateTime hasta,
    required int grupo, // 1=Internacional, 2=Local, 3=Tasas, 0=Todos
  }) async {
    try {
      String fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      
      final desdeStr = fmt(desde);
      final hastaStr = fmt(hasta);
      
      // SOAP envelope para obtener cotizaciones del grupo específico
      final soapBody = '''
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:cot="Cotiza">
  <soapenv:Header/>
  <soapenv:Body>
    <cot:wsbcucotizaciones.Execute>
      <cot:Entrada>
        <cot:Moneda>
          <cot:item>0</cot:item>
        </cot:Moneda>
        <cot:FechaDesde>$desdeStr</cot:FechaDesde>
        <cot:FechaHasta>$hastaStr</cot:FechaHasta>
        <cot:Grupo>$grupo</cot:Grupo>
      </cot:Entrada>
    </cot:wsbcucotizaciones.Execute>
  </soapenv:Body>
</soapenv:Envelope>''';

      final resp = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'text/xml; charset=utf-8',
          'SOAPAction': '""',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
        body: utf8.encode(soapBody),
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
      }

      return resp.body;
    } catch (e) {
      developer.log('Error in getCotizacionesCompletas: $e');
      rethrow;
    }
  }

  // Método alternativo usando la API REST del BCU
  static Future<String> getCotizacionesRest({
    required List<int> monedas,
    required DateTime desde,
    required DateTime hasta,
    required int grupo,
  }) async {
    try {
      String fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      
      final monedaParam = monedas.map((m) => m.toString()).join(',');
      final desdeStr = fmt(desde);
      final hastaStr = fmt(hasta);
      
      final url = 'https://cotizaciones.bcu.gub.uy/wscotizaciones/servlet/awsbcucotizaciones?Moneda=$monedaParam&FechaDesde=$desdeStr&FechaHasta=$hastaStr&Grupo=$grupo';
      
      developer.log('REST URL: $url');
      
      final resp = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/xml, text/xml, */*',
        },
      ).timeout(const Duration(seconds: 30));
      
      developer.log('REST Response status: ${resp.statusCode}');
      
      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
      }
      
      return resp.body;
    } catch (e) {
      developer.log('Error in getCotizacionesRest: $e');
      rethrow;
    }
  }

  // Método usando API alternativa más simple
  static Future<String> getCotizacionesSimple({
    required List<int> monedas,
    required DateTime desde,
    required DateTime hasta,
    required int grupo,
  }) async {
    try {
      // Usar la API más simple del BCU
      final url = 'https://cotizaciones.bcu.gub.uy/wscotizaciones/servlet/awsbcucotizaciones';
      
      developer.log('Simple API URL: $url');
      
      final resp = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/xml, text/xml, */*',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 30));
      
      developer.log('Simple API Response status: ${resp.statusCode}');
      
      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
      }
      
      return resp.body;
    } catch (e) {
      developer.log('Error in getCotizacionesSimple: $e');
      rethrow;
    }
  }

  // Método usando endpoint alternativo del BCU
  static Future<String> getCotizacionesAlternativo({
    required List<int> monedas,
    required DateTime desde,
    required DateTime hasta,
    required int grupo,
  }) async {
    try {
      String fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      
      final desdeStr = fmt(desde);
      final hastaStr = fmt(hasta);
      
      // Intentar con diferentes endpoints
      final endpoints = [
        'https://cotizaciones.bcu.gub.uy/wscotizaciones/servlet/awsbcucotizaciones',
        'https://cotizaciones.bcu.gub.uy/wscotizaciones/servlet/awsbcucotizaciones?Moneda=0&FechaDesde=$desdeStr&FechaHasta=$hastaStr&Grupo=2',
        'https://cotizaciones.bcu.gub.uy/wscotizaciones/servlet/awsbcucotizaciones?Moneda=0&FechaDesde=$desdeStr&FechaHasta=$hastaStr&Grupo=1',
      ];
      
      for (final endpoint in endpoints) {
        try {
          developer.log('Trying endpoint: $endpoint');
          
          final resp = await http.get(
            Uri.parse(endpoint),
            headers: {
              'Accept': 'application/xml, text/xml, */*',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
            },
          ).timeout(const Duration(seconds: 30));
          
          developer.log('Endpoint response status: ${resp.statusCode}');
          
          if (resp.statusCode == 200 && resp.body.isNotEmpty) {
            developer.log('Success with endpoint: $endpoint');
            return resp.body;
          }
        } catch (e) {
          developer.log('Error with endpoint $endpoint: $e');
          // Continuar con el siguiente endpoint
        }
      }
      
      throw Exception('All endpoints failed');
    } catch (e) {
      developer.log('Error in getCotizacionesAlternativo: $e');
      rethrow;
    }
  }

  // Método para obtener la lista de monedas disponibles
  static Future<String> getMonedasDisponibles() async {
    try {
      final url = 'https://cotizaciones.bcu.gub.uy/wscotizaciones/servlet/awsbcucotizaciones?Grupo=0';
      
      developer.log('Getting available currencies from: $url');
      
      final resp = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/xml, text/xml, */*',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
        },
      ).timeout(const Duration(seconds: 30));
      
      developer.log('Monedas API Response status: ${resp.statusCode}');
      
      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
      }
      
      return resp.body;
    } catch (e) {
      developer.log('Error in getMonedasDisponibles: $e');
      rethrow;
    }
  }

  // Método usando la API oficial del BCU con parámetros específicos
  static Future<String> getCotizacionesOficial({
    required List<int> monedas,
    required DateTime desde,
    required DateTime hasta,
    required int grupo,
  }) async {
    try {
      String fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      
      final desdeStr = fmt(desde);
      final hastaStr = fmt(hasta);
      
      // Usar diferentes grupos para obtener más monedas
      final grupos = [1, 2, 5]; // Mercado Internacional, Cotizaciones Locales, Tasas Locales
      String allData = '';
      
      for (final grupoActual in grupos) {
        try {
          final url = 'https://cotizaciones.bcu.gub.uy/wscotizaciones/servlet/awsbcucotizaciones?Moneda=0&FechaDesde=$desdeStr&FechaHasta=$hastaStr&Grupo=$grupoActual';
          
          developer.log('Oficial API URL (Grupo $grupoActual): $url');
          
          final resp = await http.get(
            Uri.parse(url),
            headers: {
              'Accept': 'application/xml, text/xml, */*',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Accept-Language': 'es-ES,es;q=0.9,en;q=0.8',
            },
          ).timeout(const Duration(seconds: 30));
          
          developer.log('Grupo $grupoActual Response status: ${resp.statusCode}');
          
          if (resp.statusCode == 200) {
            allData += resp.body;
            developer.log('Grupo $grupoActual data added, length: ${resp.body.length}');
          }
        } catch (e) {
          developer.log('Error with grupo $grupoActual: $e');
          // Continuar con el siguiente grupo
        }
      }
      
      if (allData.isEmpty) {
        throw Exception('No data received from any group');
      }
      
      return allData;
    } catch (e) {
      developer.log('Error in getCotizacionesOficial: $e');
      rethrow;
    }
  }

  static Future<String> getCotizacionesRaw({
    required List<int> monedas,
    required DateTime desde,
    required DateTime hasta,
    required int grupo,
  }) async {
    try {
      final body = _envelope(monedas: monedas, desde: desde, hasta: hasta, grupo: grupo);
      
      developer.log('Request body: $body');
      developer.log('Requesting cotizaciones for monedas: $monedas, desde: $desde, hasta: $hasta, grupo: $grupo');
      
      final resp = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'text/xml; charset=utf-8',
          'SOAPAction': '""',
        },
        body: utf8.encode(body),
      ).timeout(const Duration(seconds: 30));
      
      developer.log('Response status: ${resp.statusCode}');
      developer.log('Response headers: ${resp.headers}');
      
      if (resp.statusCode != 200) {
        developer.log('Error response body: ${resp.body}');
        throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
      }
      
      developer.log('Response body length: ${resp.body.length}');
      return resp.body;
    } catch (e) {
      developer.log('Error in getCotizacionesRaw: $e');
      rethrow;
    }
  }
}
