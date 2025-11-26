import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../Cache/database_helper.dart';
import '../Cache/cuenta_corriente_cache_service.dart';
import '../Ventas_Service/ventas_service.dart';
import '../../Models/Ventas.dart';
import '../../Models/VentasProductos.dart';
import '../../Models/Cliente.dart';
import '../../Models/User.dart';
import '../../Models/metodoPago.dart';
import '../../Models/EstadoEntrega.dart';
import '../../Models/ventasPago.dart';
import '../Connectivity/connectivity_service.dart';

/// Servicio simple de sincronización de ventas offline
class SimpleSyncService {
  static final SimpleSyncService _instance = SimpleSyncService._internal();
  factory SimpleSyncService() => _instance;
  SimpleSyncService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final VentasService _ventasService = VentasService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final CuentaCorrienteCacheService _ccCacheService = CuentaCorrienteCacheService();

  Timer? _syncTimer;
  bool _isSyncing = false;
  int _intentosSinDatos = 0;

  /// Inicia el servicio de sincronización (optimizado)
  void iniciar() {
    // Auto-sincronización deshabilitada: solo manual mediante botón
    // Método dejado intencionalmente vacío para evitar ejecuciones en background
  }

  /// Sincronización inteligente que verifica conectividad primero
  Future<void> _sincronizarInteligente() async {
    // Solo sincronizar si hay conexión
    if (!_connectivityService.isFullyConnected) {
      // Si no hay conexión, saltar esta sincronización
      return;
    }

    // Si llevamos 5 intentos sin datos, reducir frecuencia
    if (_intentosSinDatos >= 5) {
      // Solo sincronizar 1 de cada 3 veces (efectivamente cada 3 minutos)
      if (DateTime.now().second % 3 != 0) {
        return;
      }
    }

    await sincronizarAhora();
  }

  /// Sincroniza ventas offline pendientes
  Future<Map<String, dynamic>> sincronizarAhora() async {
    if (_isSyncing) {
      debugPrint('⚠️ SimpleSyncService: Sincronización ya en curso');
      return {
        'success': false,
        'sincronizadas': 0,
        'fallidas': 0,
        'message': 'Sincronización en curso',
        'ventasSincronizadas': [],
      };
    }

    // Verificar conectividad antes de sincronizar
    final isConnected = await _connectivityService.checkFullConnectivity();
    if (!isConnected) {
      debugPrint('⚠️ SimpleSyncService: Sin conexión o backend no disponible');
      // Obtener cantidad de ventas pendientes para mostrar en el mensaje
      final ventasPendientes = await _dbHelper.getPendingVentas();
      final cantidadPendientes = ventasPendientes.length;
      return {
        'success': false,
        'sincronizadas': 0,
        'fallidas': cantidadPendientes,
        'message': 'No hay conexión al backend. Verifica que el servidor esté encendido y que tengas conexión a internet.',
        'ventasSincronizadas': [],
      };
    }

    _isSyncing = true;
    int sincronizadas = 0;
    int fallidas = 0;
    List<Ventas> ventasSincronizadas = [];

    try {
      // Obtener ventas pendientes desde DatabaseHelper
      final ventasPendientes = await _dbHelper.getPendingVentas();
      
      debugPrint('📦 SimpleSyncService: ${ventasPendientes.length} ventas pendientes encontradas');
      
      if (ventasPendientes.isEmpty) {
        _intentosSinDatos++; // Incrementar contador
        return {
          'success': true,
          'sincronizadas': 0,
          'fallidas': 0,
          'message': 'No hay ventas pendientes',
          'ventasSincronizadas': [],
        };
      }

      // Resetear contador cuando hay datos
      _intentosSinDatos = 0;

      for (var ventaData in ventasPendientes) {
        final ventaRow = ventaData['venta'] as Map<String, dynamic>;
        final localId = ventaRow['local_id'] as String;
        
        bool ventaCreadaExitosamente = false;
        int? serverIdObtenido;
        Ventas? ventaCreada;
        Ventas? venta; // Declarar venta fuera del try para que esté disponible en el catch
        
        try {
          // Construir objeto Ventas desde los datos de la base de datos
          debugPrint('🔧 SimpleSyncService: Construyendo venta desde BD para $localId');
          venta = await _construirVentaDesdeRow(ventaRow, ventaData);
          debugPrint('✅ SimpleSyncService: Venta construida exitosamente');
          
          debugPrint('📤 SimpleSyncService: Enviando venta $localId al servidor...');
          debugPrint('   Cliente ID: ${venta.clienteId}');
          debugPrint('   Cliente nombre: ${venta.cliente.nombre}');
          debugPrint('   Total: ${venta.total}');
          debugPrint('   Productos: ${venta.ventasProductos.length}');
          debugPrint('   Pagos: ${venta.pagos?.length ?? 0}');
          if (venta.pagos != null && venta.pagos!.isNotEmpty) {
            for (var pago in venta.pagos!) {
              debugPrint('     - Pago: método=${pago.metodo.index}, monto=${pago.monto}, ventaId=${pago.ventaId}, id=${pago.id}');
            }
          }
          
          // Usar un timeout más largo para sincronización (30 segundos)
          // porque el servidor puede tardar en procesar y guardar la venta
          final response = await _ventasService.crearVenta(venta, customTimeout: const Duration(seconds: 30));
          
          debugPrint('📥 SimpleSyncService: Respuesta del servidor recibida: $response');
          debugPrint('   Tipo de respuesta: ${response.runtimeType}');
          debugPrint('   Keys: ${response.keys.toList()}');
          
          // Verificar que la respuesta sea válida
          if (response is! Map<String, dynamic>) {
            throw Exception('Respuesta inválida del servidor: $response');
          }
          
          // Si llegamos aquí, la venta se creó exitosamente en el servidor (sin excepción)
          ventaCreadaExitosamente = true;
          ventaCreada = venta;
          
          // Actualizar el ID de la venta en la venta local
          final serverId = response['ventaId'] as int?;
          serverIdObtenido = serverId;
          
          debugPrint('🆔 SimpleSyncService: ID del servidor: $serverId');
          debugPrint('✅ SimpleSyncService: Venta creada exitosamente en el servidor');
          
          // Si el servidor retornó un ID, lo usamos
          if (serverId != null) {
            venta.id = serverId;
            debugPrint('✅ SimpleSyncService: ID asignado a la venta local: ${venta.id}');
          } else {
            debugPrint('⚠️ SimpleSyncService: El servidor no retornó un ID de venta');
          }

        } catch (e, stackTrace) {
          debugPrint('');
          debugPrint('═══════════════════════════════════════════════════════════');
          debugPrint('❌ SimpleSyncService: ERROR AL SINCRONIZAR VENTA');
          debugPrint('═══════════════════════════════════════════════════════════');
          debugPrint('   Local ID: $localId');
          debugPrint('   Error completo: $e');
          debugPrint('   Tipo de error: ${e.runtimeType}');
          debugPrint('   Mensaje: ${e.toString()}');
          
          // Extraer código de estado HTTP si está disponible
          String errorString = e.toString();
          int? statusCode;
          if (errorString.contains('400')) {
            statusCode = 400;
          } else if (errorString.contains('401')) {
            statusCode = 401;
          } else if (errorString.contains('403')) {
            statusCode = 403;
          } else if (errorString.contains('404')) {
            statusCode = 404;
          } else if (errorString.contains('500')) {
            statusCode = 500;
          }
          
          debugPrint('   Código de estado HTTP detectado: $statusCode');
          
          // Extraer mensaje de error más descriptivo
          String errorMessage = errorString;
          String userMessage = '';
          
          if (statusCode == 400) {
            // Error 400: Bad Request - problema con los datos
            userMessage = 'Error en los datos de la venta (400). Posibles causas:\n';
            userMessage += '• El cliente o productos pueden no existir en el servidor\n';
            userMessage += '• Datos inválidos o faltantes\n';
            userMessage += '• Verifica los logs del backend para más detalles';
            errorMessage = 'Error 400: Datos inválidos en la venta';
            debugPrint('   ⚠️ ERROR 400: La venta NO se guardó en el servidor');
            debugPrint('   ⚠️ Verifica los logs del backend para el "inner exception"');
          } else if (statusCode == 401 || statusCode == 403) {
            userMessage = 'Error de autenticación. Inicia sesión nuevamente.';
            errorMessage = 'Error ${statusCode}: Autenticación';
          } else if (statusCode == 404) {
            userMessage = 'Recurso no encontrado en el servidor.';
            errorMessage = 'Error 404: No encontrado';
          } else if (statusCode == 500) {
            userMessage = 'Error interno del servidor. Intenta más tarde.';
            errorMessage = 'Error 500: Error del servidor';
          } else {
            userMessage = 'Error al sincronizar: ${e.toString()}';
            errorMessage = errorString;
          }
          
          debugPrint('   Mensaje de error para BD: $errorMessage');
          debugPrint('   Mensaje para usuario: $userMessage');
          debugPrint('   Stack trace:');
          debugPrint('   $stackTrace');
          debugPrint('═══════════════════════════════════════════════════════════');
          debugPrint('');
          
          // Si es error 400, verificar si la venta realmente se guardó en el servidor
          // (a veces el servidor guarda la venta pero retorna error por validaciones adicionales)
          bool ventaExisteEnServidor = false;
          int? serverIdEncontrado;
          
          if (statusCode == 400) {
            debugPrint('🔍 SimpleSyncService: Verificando si la venta se guardó en el servidor a pesar del error 400...');
            try {
              // Obtener ventas del servidor para verificar si esta venta existe
              final ventasDelServidor = await _ventasService.obtenerVentas(timeoutRapido: false, timeoutNormal: true);
              
              // Buscar una venta que coincida con esta (mismo cliente, misma fecha, mismo total aproximado)
              if (venta != null) {
                debugPrint('   Buscando venta en servidor:');
                debugPrint('     Cliente ID: ${venta!.clienteId}');
                debugPrint('     Fecha: ${venta!.fecha.year}-${venta!.fecha.month}-${venta!.fecha.day}');
                debugPrint('     Total: ${venta!.total}');
                debugPrint('   Total de ventas en servidor: ${ventasDelServidor.length}');
                
                Ventas? ventaEncontrada;
                try {
                  ventaEncontrada = ventasDelServidor.firstWhere(
                    (v) {
                      final mismoCliente = v.clienteId == venta!.clienteId;
                      final mismaFecha = v.fecha.year == venta!.fecha.year &&
                                       v.fecha.month == venta!.fecha.month &&
                                       v.fecha.day == venta!.fecha.day;
                      final mismoTotal = (v.total - venta!.total).abs() < 0.01;
                      
                      if (mismoCliente && mismaFecha && mismoTotal) {
                        debugPrint('   ✅ Coincidencia encontrada: ID=${v.id}, Total=${v.total}');
                      }
                      
                      return mismoCliente && mismaFecha && mismoTotal;
                    },
                    orElse: () {
                      debugPrint('   ❌ No se encontró coincidencia');
                      return venta!; // Si no encuentra, retornar la venta original
                    },
                  );
                } catch (e) {
                  debugPrint('   ⚠️ Error buscando venta: $e');
                  ventaEncontrada = null;
                }
                
                if (ventaEncontrada != null && ventaEncontrada.id != null && ventaEncontrada.id != venta!.id) {
                  ventaExisteEnServidor = true;
                  serverIdEncontrado = ventaEncontrada.id;
                  debugPrint('✅ SimpleSyncService: ¡VENTA ENCONTRADA EN EL SERVIDOR!');
                  debugPrint('   ID del servidor: $serverIdEncontrado');
                  debugPrint('   La venta se guardó correctamente a pesar del error 400');
                } else {
                  debugPrint('❌ SimpleSyncService: La venta NO existe en el servidor');
                  debugPrint('   ventaEncontrada: $ventaEncontrada');
                  debugPrint('   ventaEncontrada.id: ${ventaEncontrada?.id}');
                  debugPrint('   venta.id: ${venta!.id}');
                }
              }
            } catch (verifyError) {
              debugPrint('⚠️ SimpleSyncService: Error al verificar si la venta existe: $verifyError');
              // Continuar con el flujo normal si no se puede verificar
            }
          }
          
          // Si la venta existe en el servidor, marcarla como sincronizada
          if (ventaExisteEnServidor && serverIdEncontrado != null && venta != null) {
            debugPrint('💾 SimpleSyncService: Marcando venta como sincronizada (se encontró en el servidor)...');
            try {
              await _dbHelper.markVentaAsSynced(localId, serverIdEncontrado);
              // Actualizar también el movimiento de cuenta corriente
              await _ccCacheService.marcarMovimientosDeVentaComoSincronizados(
                ventaLocalId: localId,
                ventaServerId: serverIdEncontrado,
              );
              venta.id = serverIdEncontrado;
              ventasSincronizadas.add(venta);
              sincronizadas++;
              debugPrint('✅ SimpleSyncService: Venta marcada como sincronizada exitosamente');
              debugPrint('📊 SimpleSyncService: Contador actualizado - sincronizadas: $sincronizadas, fallidas: $fallidas');
              continue; // Continuar con la siguiente venta
            } catch (markError) {
              debugPrint('⚠️ Error al marcar venta como sincronizada: $markError');
              // Si falla el marcado, continuar como fallida
            }
          }
          
          // Si no se encontró en el servidor, marcar como fallida
          try {
            debugPrint('💾 SimpleSyncService: Marcando venta $localId como fallida...');
            await _dbHelper.markVentaAsSyncFailed(localId, errorMessage);
            debugPrint('✅ SimpleSyncService: Venta marcada como fallida');
          } catch (markError) {
            debugPrint('⚠️ Error al marcar venta como fallida: $markError');
          }
          fallidas++;
          debugPrint('📊 SimpleSyncService: Contador actualizado (fallida) - sincronizadas: $sincronizadas, fallidas: $fallidas');
          continue; // Continuar con la siguiente venta
        }

        // Si la venta se creó exitosamente en el servidor, marcarla como sincronizada
        // Esto se hace FUERA del try-catch anterior para asegurar que siempre se marque
        if (ventaCreadaExitosamente && ventaCreada != null) {
          debugPrint('💾 SimpleSyncService: Marcando venta $localId como sincronizada...');
          try {
            await _dbHelper.markVentaAsSynced(localId, serverIdObtenido);
            // Actualizar también el movimiento de cuenta corriente
            if (serverIdObtenido != null) {
              await _ccCacheService.marcarMovimientosDeVentaComoSincronizados(
                ventaLocalId: localId,
                ventaServerId: serverIdObtenido,
              );
            }
            debugPrint('✅ SimpleSyncService: Venta $localId sincronizada exitosamente (ID servidor: $serverIdObtenido)');
            
            // Agregar a lista de ventas sincronizadas
            ventasSincronizadas.add(ventaCreada);
            sincronizadas++;
            debugPrint('📊 SimpleSyncService: Contador actualizado - sincronizadas: $sincronizadas, fallidas: $fallidas');
          } catch (markError, stackTrace) {
            // Si falla el marcado pero la venta ya está en el servidor, considerarla como exitosa
            debugPrint('⚠️ SimpleSyncService: Venta creada en servidor pero error al marcar como sincronizada: $markError');
            debugPrint('   Stack trace: $stackTrace');
            debugPrint('   La venta se creó exitosamente en el servidor, pero no se pudo actualizar el estado local');
            // Aún así considerar como sincronizada porque está en el servidor
            ventasSincronizadas.add(ventaCreada);
            sincronizadas++;
            debugPrint('📊 SimpleSyncService: Contador actualizado (con error de marcado) - sincronizadas: $sincronizadas, fallidas: $fallidas');
          }
        }

        // Pausa pequeña entre ventas
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      // Limpiar ventas sincronizadas antiguas (opcional, para mantener la BD limpia)
      if (sincronizadas > 0) {
        await _dbHelper.cleanOldSyncedVentas(daysOld: 30);
      }

      debugPrint('');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('📊 SimpleSyncService: RESUMEN FINAL DE SINCRONIZACIÓN');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('   Total de ventas procesadas: ${ventasPendientes.length}');
      debugPrint('   ✅ Ventas sincronizadas exitosamente: $sincronizadas');
      debugPrint('   ❌ Ventas fallidas: $fallidas');
      debugPrint('   📦 Ventas sincronizadas (lista): ${ventasSincronizadas.length}');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('');

      // Si sincronizamos al menos una venta, considerarlo como éxito parcial
      // Solo marcar como fallido si todas las ventas fallaron
      final todasFallaron = sincronizadas == 0 && fallidas > 0;
      final mensaje = sincronizadas > 0 && fallidas > 0
          ? '$sincronizadas ventas sincronizadas correctamente. $fallidas fallaron.'
          : sincronizadas > 0
              ? '$sincronizadas ventas sincronizadas exitosamente'
              : fallidas > 0
                  ? '$fallidas ventas fallaron al sincronizar'
                  : 'No hay ventas pendientes';

      debugPrint('📝 SimpleSyncService: Mensaje para el usuario: $mensaje');
      debugPrint('✅ SimpleSyncService: Success calculado: ${!todasFallaron}');
      debugPrint('   (todasFallaron = $todasFallaron)');
      debugPrint('');

      return {
        'success': !todasFallaron, // Éxito si al menos una se sincronizó
        'sincronizadas': sincronizadas,
        'fallidas': fallidas,
        'message': mensaje,
        'ventasSincronizadas': ventasSincronizadas,
      };

    } catch (e) {
      debugPrint('❌ SimpleSyncService: Error en sincronización: $e');
      return {
        'success': false,
        'sincronizadas': sincronizadas,
        'fallidas': fallidas,
        'message': 'Error: $e',
        'ventasSincronizadas': ventasSincronizadas,
      };
    } finally {
      // Asegurar que el flag se resetee SIEMPRE
      _isSyncing = false;
    }
  }

  /// Construye un objeto Ventas desde una fila de base de datos
  Future<Ventas> _construirVentaDesdeRow(Map<String, dynamic> ventaRow, Map<String, dynamic> ventaData) async {
    final productos = (ventaData['productos'] as List).map((p) {
      return VentasProductos(
        productoId: p['producto_id'] as int,
        nombre: p['nombre'] as String,
        marca: p['marca'] as String?,
        precio: p['precio'] as double,
        cantidad: p['cantidad'] as double,
        categoria: p['categoria'] as String,
        categoriaId: p['categoria_id'] as int,
        precioFinalCalculado: p['precio_final_calculado'] as double,
        entregado: (p['entregado'] as int) == 1,
        motivo: p['motivo'] as String?,
        nota: p['nota'] as String?,
        fechaChequeo: p['fecha_chequeo'] != null ? DateTime.parse(p['fecha_chequeo'] as String) : null,
        usuarioChequeoId: p['usuario_chequeo_id'] as int?,
      );
    }).toList();

    // Construir pagos - cuando se crea una venta nueva, los pagos NO deben tener ID
    // porque el servidor los creará automáticamente
    final pagosRows = ventaData['pagos'] as List;
    debugPrint('💰 SimpleSyncService: Pagos encontrados en BD: ${pagosRows.length}');
    debugPrint('   Datos de pagos: $pagosRows');
    
    List<dynamic>? pagos;
    if (pagosRows.isNotEmpty) {
      debugPrint('💰 SimpleSyncService: Construyendo ${pagosRows.length} pago(s)...');
      pagos = pagosRows.map((p) {
        // Verificar que los datos estén presentes
        final metodo = p['metodo'] as int?;
        final monto = p['monto'];
        
        if (metodo == null) {
          debugPrint('   ⚠️ ERROR: Pago sin método: $p');
          throw Exception('Pago sin método de pago');
        }
        
        final montoDouble = monto is num ? monto.toDouble() : (monto as double);
        
        final pagoJson = {
          'id': 0, // ID debe ser 0 para nuevas ventas (el servidor lo asignará)
          'ventaId': 0, // ventaId debe ser 0 porque la venta aún no existe
          'metodo': metodo,
          'monto': montoDouble,
        };
        debugPrint('   ✅ Pago construido: método=${pagoJson['metodo']}, monto=${pagoJson['monto']}');
        return pagoJson;
      }).toList();
      debugPrint('✅ SimpleSyncService: ${pagos.length} pago(s) construidos correctamente');
    } else {
      debugPrint('⚠️ SimpleSyncService: No hay pagos en esta venta');
    }

    // Construir cliente
    final clienteJson = jsonDecode(ventaRow['cliente_json'] as String);
    final cliente = Cliente.fromJson(clienteJson);

    // Construir usuario creador si existe
    User? usuarioCreador;
    if (ventaRow['usuario_creador_json'] != null) {
      final usuarioJson = jsonDecode(ventaRow['usuario_creador_json'] as String);
      usuarioCreador = User.fromJson(usuarioJson);
    }
    
    // Construir usuario asignado si existe
    User? usuarioAsignado;
    if (ventaRow['usuario_asignado_json'] != null) {
      final usuarioJson = jsonDecode(ventaRow['usuario_asignado_json'] as String);
      usuarioAsignado = User.fromJson(usuarioJson);
    }

    return Ventas(
      id: ventaRow['id'] as int?,
      clienteId: ventaRow['cliente_id'] as int,
      cliente: cliente,
      ventasProductos: productos,
      total: ventaRow['total'] as double,
      fecha: DateTime.parse(ventaRow['fecha'] as String),
      metodoPago: ventaRow['metodo_pago'] != null 
        ? MetodoPago.values[ventaRow['metodo_pago'] as int]
        : null,
      pagos: pagos?.map((p) => VentaPago.fromJson(p)).toList(),
      usuarioIdCreador: ventaRow['usuario_id_creador'] as int?,
      usuarioCreador: usuarioCreador,
      usuarioIdAsignado: ventaRow['usuario_id_asignado'] as int?,
      usuarioAsignado: usuarioAsignado,
      estadoEntrega: EstadoEntregaExtension.fromJson(ventaRow['estado_entrega'] as int),
    );
  }

  /// Detiene el servicio
  void detener() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('🛑 SimpleSyncService: Servicio detenido');
  }
}
