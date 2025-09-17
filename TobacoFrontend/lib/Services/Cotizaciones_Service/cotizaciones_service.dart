import 'dart:convert';
import 'package:http/http.dart' as http;

class BcuCotizacionesService {
  static const _endpoint =
      'https://cotizaciones.bcu.gub.uy/wscotizaciones/servlet/awsbcucotizaciones';

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

  static Future<String> getCotizacionesRaw({
    required List<int> monedas,
    required DateTime desde,
    required DateTime hasta,
    required int grupo,
    http.Client? client,
  }) async {
    final body =
        _envelope(monedas: monedas, desde: desde, hasta: hasta, grupo: grupo);
    final httpClient = client ?? http.Client();
    try {
      final resp = await httpClient.post(
        Uri.parse(_endpoint),
        headers: {'Content-Type': 'text/xml; charset=utf-8'},
        body: utf8.encode(body),
      );
      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}: ${resp.body}');
      }
      return resp.body;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
