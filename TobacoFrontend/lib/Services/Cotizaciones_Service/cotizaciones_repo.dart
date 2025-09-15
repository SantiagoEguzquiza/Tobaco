import 'package:tobaco/Models/Cotizacion.dart';
import 'package:tobaco/Services/Cotizaciones_Service/cotizaciones_service.dart';
import 'package:xml/xml.dart' as xml;


class BcuRepository {
  Future<List<Cotizacion>> getCotizaciones({
    required List<int> monedas,
    required DateTime desde,
    required DateTime hasta,
    required int grupo, // 1 int, 2 locales, 3 tasas, 0 todos
  }) async {
    final raw = await BcuCotizacionesService.getCotizacionesRaw(
      monedas: monedas, desde: desde, hasta: hasta, grupo: grupo,
    );

    final doc = xml.XmlDocument.parse(raw);

    // Fault?
    final fault = doc.findAllElements('Fault');
    if (fault.isNotEmpty) {
      final msg = fault.first.findAllElements('faultstring').map((e) => e.text).join(' ');
      throw Exception('SOAP Fault: $msg');
    }

    // Buscar sección de datos (nombre suele contener "datoscot")
    final dataNodes = doc.findAllElements('*')
      .where((e) => e.name.local.toLowerCase().contains('datoscot'));

    final out = <Cotizacion>[];
    for (final dn in dataNodes) {
      for (final item in dn.findElements('*')) {
        String? fecha, nombre, iso;
        int? moneda;
        double? tcc, tcv;

        for (final f in item.findElements('*')) {
          final k = f.name.local.toLowerCase();
          final v = f.text.trim();
          if (k.contains('fecha')) fecha = v;
          else if (k == 'moneda')  moneda = int.tryParse(v);
          else if (k.contains('nombre')) nombre = v;
          else if (k.contains('codigoiso')) iso = v;
          else if (k == 'tcc' || k.contains('compra')) tcc = double.tryParse(v.replaceAll(',', '.'));
          else if (k == 'tcv' || k.contains('venta'))  tcv = double.tryParse(v.replaceAll(',', '.'));
        }
        out.add(Cotizacion(fecha: fecha, moneda: moneda, nombre: nombre, codigoIso: iso, tcc: tcc, tcv: tcv));
      }
    }
    return out;
  }
}
