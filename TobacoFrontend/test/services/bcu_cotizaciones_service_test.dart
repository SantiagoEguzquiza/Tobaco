import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tobaco/Services/Cotizaciones_Service/cotizaciones_service.dart';

void main() {
  group('BcuCotizacionesService', () {
    test('getCotizacionesRaw envia el request SOAP y retorna la respuesta cruda', () async {
      late http.Request capturedRequest;
      const fakeResponseBody = '<soapenv:Envelope>respuesta</soapenv:Envelope>';
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response(fakeResponseBody, 200,
            headers: {'content-type': 'text/xml; charset=utf-8'});
      });

      final response = await BcuCotizacionesService.getCotizacionesRaw(
        monedas: const [2225],
        desde: DateTime(2024, 1, 2),
        hasta: DateTime(2024, 1, 5),
        grupo: 0,
        client: mockClient,
      );

      expect(response, fakeResponseBody);
      expect(capturedRequest.method, equals('POST'));
      expect(
        capturedRequest.url.toString(),
        equals('https://cotizaciones.bcu.gub.uy/wscotizaciones/servlet/awsbcucotizaciones'),
      );
      expect(
        capturedRequest.headers['Content-Type'],
        equals('text/xml; charset=utf-8'),
      );

      final soapBody = utf8.decode(capturedRequest.bodyBytes);
      expect(soapBody, contains('<cot:item>2225</cot:item>'));
      expect(soapBody, contains('<cot:FechaDesde>2024-01-02</cot:FechaDesde>'));
      expect(soapBody, contains('<cot:FechaHasta>2024-01-05</cot:FechaHasta>'));
      expect(soapBody, contains('<cot:Grupo>0</cot:Grupo>'));
    });
  });
}
