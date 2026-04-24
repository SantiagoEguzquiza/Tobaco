import 'package:tobaco/Models/Cotizacion.dart';
import 'package:tobaco/Services/Cotizaciones_Service/brou_cotizaciones_service.dart';
import 'dart:developer' as developer;

class CotizacionesResult {
  final List<Cotizacion> items;
  final DateTime? timestamp;

  CotizacionesResult({required this.items, this.timestamp});
}

/// Repositorio de cotizaciones que consume la API del BROU (Banco República).
/// Reemplaza el anterior BcuRepository.
class BcuRepository {
  String _getCurrencyName(String iso) {
    switch (iso.toUpperCase()) {
      case 'USD':
        return 'Dólar Americano';
      case 'BRL':
        return 'Real Brasileño';
      case 'ARS':
        return 'Peso Argentino';
      case 'EUR':
        return 'Euro';
      default:
        return 'Moneda $iso';
    }
  }

  List<String> _getCodigosIsoForGrupo(int grupo) {
    switch (grupo) {
      case 1:
        return ['USD', 'BRL', 'EUR'];
      case 2:
        return ['ARS'];
      case 3:
        return [];
      case 0:
      default:
        return ['USD', 'BRL', 'ARS', 'EUR'];
    }
  }

  Future<CotizacionesResult> getCotizaciones({
    required List<int> monedas,
    required DateTime desde,
    required DateTime hasta,
    required int grupo,
  }) async {
    try {
      final rates = await BrouCotizacionesService.getBrouRates();
      final codigosPermitidos = _getCodigosIsoForGrupo(grupo);

      final hoy = DateTime.now();
      final fechaStr =
          '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';

      final items = <Cotizacion>[];
      final ordenMonedas = ['USD', 'BRL', 'ARS', 'EUR'];

      for (final iso in ordenMonedas) {
        if (!codigosPermitidos.contains(iso)) continue;
        final data = rates[iso];
        if (data == null) continue;

        final tcc = data['bid'];
        final tcv = data['ask'];

        items.add(Cotizacion(
          fecha: fechaStr,
          codigoIso: iso,
          nombre: _getCurrencyName(iso),
          tcc: tcc,
          tcv: tcv,
        ));
      }

      developer.log(
          'Cotizaciones BROU obtenidas: ${items.length} (${codigosPermitidos.join(", ")})');

      return CotizacionesResult(
        items: items,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      developer.log('Error en getCotizaciones: $e');
      rethrow;
    }
  }
}
