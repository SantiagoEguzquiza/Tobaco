import 'package:tobaco/Models/Cotizacion.dart';
import 'package:tobaco/Services/Cotizaciones_Service/cotizaciones_service.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:developer' as developer;

class CotizacionesResult {
  final List<Cotizacion> items;
  final DateTime? timestamp; // Timestamp de la respuesta de la API (si existe)

  CotizacionesResult({required this.items, this.timestamp});
}

class BcuRepository {
  Future<CotizacionesResult> getCotizaciones({
    required List<int> monedas,
    required DateTime desde,
    required DateTime hasta,
    required int grupo, // 1 int, 2 locales, 3 tasas, 0 todos
  }) async {
    try {
      // Usar el método SOAP correcto para obtener cotizaciones del grupo específico
      final raw = await BcuCotizacionesService.getCotizacionesCompletas(
        desde: desde,
        hasta: hasta,
        grupo: grupo,
      );

      final doc = xml.XmlDocument.parse(raw);

      // Verificar si hay un SOAP Fault
      final fault = doc.findAllElements('Fault');
      if (fault.isNotEmpty) {
        final msg = fault.first.findAllElements('faultstring').map((e) => e.text).join(' ');
        throw Exception('SOAP Fault: $msg');
      }

      // Buscar cotizaciones según la estructura del WSDL:
      // Salida -> datoscotizaciones -> datoscotizaciones.dato (con el punto!)
      final out = <Cotizacion>[];
      
      // Buscar primero dentro de la estructura: Salida -> datoscotizaciones -> datoscotizaciones.dato
      final salidaElements = doc.findAllElements('Salida');
      
      if (salidaElements.isNotEmpty) {
        final salida = salidaElements.first;
        final datosCotizaciones = salida.findAllElements('datoscotizaciones');
        
        if (datosCotizaciones.isNotEmpty) {
          // Buscar elementos datoscotizaciones.dato dentro de datoscotizaciones
          final todosLosDatos = datosCotizaciones.first.findAllElements('*');
          final datosConPunto = todosLosDatos.where((e) => 
            e.name.local == 'datoscotizaciones.dato'
          ).toList();
          
          for (final datoElement in datosConPunto) {
            final cotizacion = _parseCotizacionBCU(datoElement);
            if (cotizacion != null) {
              out.add(cotizacion);
            }
          }
        }
      }
      
      // Si no encontramos nada en la estructura anterior, buscar directamente
      if (out.isEmpty) {
        // Buscar todos los elementos datoscotizaciones.dato directamente
        final todosLosElementos = doc.findAllElements('*');
        final datosConPunto = todosLosElementos.where((e) => 
          e.name.local == 'datoscotizaciones.dato'
        ).toList();
        
        if (datosConPunto.isNotEmpty) {
          for (final datoElement in datosConPunto) {
            final cotizacion = _parseCotizacionBCU(datoElement);
            if (cotizacion != null) {
              out.add(cotizacion);
            }
          }
        } else {
          // Buscar elementos que contengan "dato" en su nombre y tengan los campos correctos
          final elementosConDato = todosLosElementos.where((e) {
            final nombre = e.name.local.toLowerCase();
            return nombre.contains('dato') && 
                   (e.findAllElements('Moneda').isNotEmpty || 
                    e.findAllElements('CodigoISO').isNotEmpty ||
                    e.findAllElements('TCC').isNotEmpty);
          }).toList();
          
          for (final datoElement in elementosConDato) {
            // Verificar que tenga los campos necesarios
            final tieneMoneda = datoElement.findAllElements('Moneda').isNotEmpty;
            final tieneCodigoISO = datoElement.findAllElements('CodigoISO').isNotEmpty;
            final tieneTCC = datoElement.findAllElements('TCC').isNotEmpty || 
                            datoElement.findAllElements('Tcc').isNotEmpty;
            
            if ((tieneMoneda || tieneCodigoISO) && tieneTCC) {
              final cotizacion = _parseCotizacionBCU(datoElement);
              if (cotizacion != null) {
                out.add(cotizacion);
              }
            }
          }
        }
      }

      // Normalizar códigos ISO y filtrar solo las monedas según el grupo seleccionado
      // La API del BCU puede usar "EURO" en lugar de "EUR", así que normalizamos
      final codigosIsoPermitidos = _getCodigosIsoPermitidosForGrupo(grupo);
      final cotizacionesFiltradas = out.map((cot) {
        // Normalizar código ISO si es necesario
        if (cot.codigoIso != null) {
          var iso = cot.codigoIso!.toUpperCase().trim();
          if (iso == 'EURO') {
            iso = 'EUR';
            // Actualizar el objeto con el ISO normalizado
            return Cotizacion(
              fecha: cot.fecha,
              moneda: cot.moneda,
              nombre: cot.nombre,
              codigoIso: iso,
              tcc: cot.tcc,
              tcv: cot.tcv,
            );
          }
        }
        return cot;
      }).where((cot) {
        if (cot.codigoIso != null) {
          final iso = cot.codigoIso!.toUpperCase().trim();
          return codigosIsoPermitidos.contains(iso);
        }
        return false;
      }).toList();

      // Eliminar duplicados: cuando hay múltiples cotizaciones de la misma moneda ISO y fecha,
      // mantener solo una (preferir la que NO sea "billete")
      final cotizacionesUnicas = <String, Cotizacion>{};
      for (final cot in cotizacionesFiltradas) {
        if (cot.codigoIso != null && cot.fecha != null) {
          final key = '${cot.codigoIso!.toUpperCase()}_${cot.fecha}';
          
          if (cotizacionesUnicas.containsKey(key)) {
            final existente = cotizacionesUnicas[key]!;
            // Preferir la cotización que NO sea billete (código 501) o que tenga mejor nombre
            final esBillete = cot.nombre?.toLowerCase().contains('billete') ?? false;
            final existenteEsBillete = existente.nombre?.toLowerCase().contains('billete') ?? false;
            
            // Si la existente es billete y la nueva no, reemplazar
            if (existenteEsBillete && !esBillete) {
              cotizacionesUnicas[key] = cot;
            }
            // Si ambas son billete o ambas no, mantener la existente (primera encontrada)
          } else {
            cotizacionesUnicas[key] = cot;
          }
        }
      }

      final cotizacionesSinDuplicados = cotizacionesUnicas.values.toList();

      // Ordenar: primero por fecha descendente (más recientes primero), luego por moneda (USD, BRL, ARS, EUR)
      final ordenMonedas = {'USD': 1, 'BRL': 2, 'ARS': 3, 'EUR': 4};
      cotizacionesSinDuplicados.sort((a, b) {
        // Primero comparar por fecha (descendente - más recientes primero)
        if (a.fecha == null && b.fecha == null) {
          // Si ambas no tienen fecha, ordenar por moneda
        } else if (a.fecha == null) {
          return 1; // Sin fecha al final
        } else if (b.fecha == null) {
          return -1; // Sin fecha al final
        } else {
          try {
            final fechaA = DateTime.parse(a.fecha!);
            final fechaB = DateTime.parse(b.fecha!);
            final comparacionFecha = fechaB.compareTo(fechaA); // Descendente
            
            // Si las fechas son diferentes, ordenar por fecha
            if (comparacionFecha != 0) {
              return comparacionFecha;
            }
            // Si es la misma fecha, continuar a ordenar por moneda
          } catch (e) {
            // Si hay error al parsear, mantener el orden original y continuar a ordenar por moneda
          }
        }
        
        // Si es la misma fecha (o ambas sin fecha), ordenar por moneda (USD, BRL, ARS, EUR)
        final isoA = a.codigoIso?.toUpperCase() ?? '';
        final isoB = b.codigoIso?.toUpperCase() ?? '';
        final ordenA = ordenMonedas[isoA] ?? 999;
        final ordenB = ordenMonedas[isoB] ?? 999;
        
        return ordenA.compareTo(ordenB);
      });

      developer.log('Cotizaciones obtenidas: ${cotizacionesSinDuplicados.length} (USD, EUR, ARS, BRL)');

      return CotizacionesResult(
        items: cotizacionesSinDuplicados,
        timestamp: null, // La API no devuelve timestamp, se usa el fetch local
      );
    } catch (e) {
      developer.log('Error in getCotizaciones: $e');
      rethrow;
    }
  }

  /// Parsea un elemento dato según la estructura del WSDL del BCU
  /// Estructura: Fecha, Moneda, Nombre, CodigoISO, Emisor, TCC, TCV, ArbAct, FormaArbitrar
  Cotizacion? _parseCotizacionBCU(xml.XmlElement datoElement) {
    String? fecha, nombre, iso;
    int? moneda;
    double? tcc, tcv;

    // Buscar los campos según el WSDL del BCU
    for (final child in datoElement.children) {
      if (child is xml.XmlElement) {
        final key = child.name.local; // Mantener el nombre original (case-sensitive)
        final value = child.text.trim();
        
        if (value.isNotEmpty) {
          // Según el WSDL, los elementos se llaman exactamente así:
          if (key == 'Fecha') {
            fecha = value;
          } else if (key == 'Moneda') {
            moneda = int.tryParse(value);
          } else if (key == 'Nombre') {
            nombre = value;
          } else if (key == 'CodigoISO') {
            iso = value;
          } else if (key == 'TCC') {
            final parsedValue = double.tryParse(value.replaceAll(',', '.'));
            if (parsedValue != null) {
              tcc = parsedValue;
            }
          } else if (key == 'TCV') {
            final parsedValue = double.tryParse(value.replaceAll(',', '.'));
            if (parsedValue != null) {
              tcv = parsedValue;
            }
          }
        }
      }
    }

    // También buscar sin distinguir mayúsculas/minúsculas como fallback
    // Pero asegurarse de que NO sobrescribamos valores ya encontrados
    if (fecha == null || moneda == null || nombre == null || tcc == null || tcv == null) {
      for (final child in datoElement.children) {
        if (child is xml.XmlElement) {
          final key = child.name.local.toLowerCase();
          final value = child.text.trim();
          
          if (value.isNotEmpty) {
            if (fecha == null && key.contains('fecha')) {
              fecha = value;
            } else if (moneda == null && key.contains('moneda')) {
              moneda = int.tryParse(value);
            } else if ((nombre == null || nombre.isEmpty) && key.contains('nombre')) {
              nombre = value;
            } else if ((iso == null || iso.isEmpty) && (key.contains('codigoiso') || key.contains('iso'))) {
              iso = value;
            } else if (tcc == null && (key == 'tcc' || key.contains('compra'))) {
              final parsedValue = double.tryParse(value.replaceAll(',', '.'));
              if (parsedValue != null) {
                tcc = parsedValue;
              }
            } else if (tcv == null && (key == 'tcv' || key.contains('venta'))) {
              final parsedValue = double.tryParse(value.replaceAll(',', '.'));
              if (parsedValue != null) {
                tcv = parsedValue;
              }
            }
          }
        }
      }
    }

    // Solo crear cotización si tenemos datos mínimos válidos
    if (moneda != null && (tcc != null || tcv != null)) {
      // Mapear códigos de moneda a nombres si no está presente
      if (nombre == null || nombre.isEmpty) {
        nombre = _getMonedaName(moneda);
      }
      
      // Mapear códigos de moneda a códigos ISO si no está presente
      if (iso == null || iso.isEmpty) {
        iso = _getMonedaIso(moneda);
      } else {
        // Normalizar códigos ISO: "EURO" -> "EUR"
        iso = iso.toUpperCase().trim();
        if (iso == 'EURO') {
          iso = 'EUR';
        }
      }
      
      return Cotizacion(
        fecha: fecha, 
        moneda: moneda, 
        nombre: nombre, 
        codigoIso: iso, 
        tcc: tcc, 
        tcv: tcv
      );
    }

    return null;
  }


  String _getMonedaName(int? moneda) {
    if (moneda == null) return 'Moneda Desconocida';
    
    switch (moneda) {
      case 0:
      case 858:
        return 'Peso Uruguayo';
      case 2222:
        return 'Dólar Americano';
      case 2223:
      case 1111:
        return 'Euro';
      case 2224:
      case 500:
        return 'Peso Argentino';
      case 501:
        return 'Peso Argentino'; // Billete, pero lo llamamos igual para evitar duplicados
      case 2225:
        return 'Real Brasileño';
      case 2226:
        return 'Libra Esterlina';
      case 2227:
        return 'Yen Japonés';
      case 2228:
        return 'Franco Suizo';
      case 2229:
        return 'Dólar Canadiense';
      case 2230:
        return 'Dólar Australiano';
      default:
        return 'Moneda $moneda';
    }
  }

  String _getMonedaIso(int? moneda) {
    if (moneda == null) return '';
    
    switch (moneda) {
      case 0:
      case 858:
        return 'UYU';
      case 2222:
        return 'USD';
      case 2223:
      case 1111:
        return 'EUR'; // Código 1111 también es EUR según la API del BCU
      case 2224:
      case 500:
      case 501:
        return 'ARS'; // Todos los códigos de peso argentino mapean a ARS
      case 2225:
        return 'BRL';
      case 2226:
        return 'GBP';
      case 2227:
        return 'JPY';
      case 2228:
        return 'CHF';
      case 2229:
        return 'CAD';
      case 2230:
        return 'AUD';
      default:
        return '';
    }
  }

  // Obtiene los códigos ISO permitidos según el grupo
  List<String> _getCodigosIsoPermitidosForGrupo(int grupo) {
    switch (grupo) {
      case 1: // Internacionales
        return ['USD', 'BRL', 'EUR']; // Solo internacionales (Dólar, Real, Euro)
      case 2: // Locales
        return ['ARS']; // Solo locales (Peso Argentino)
      case 3: // Tasas
        return []; // Por ahora vacío, ajustar según necesidad
      case 0: // Todas
      default:
        return ['USD', 'BRL', 'ARS', 'EUR']; // Todas las monedas (Dólar, Real, Peso Argentino, Euro)
    }
  }

}
