import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tobaco/Models/Entrega.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';
import 'package:tobaco/Services/Entregas_Service/entregas_service.dart';
import 'package:tobaco/Services/Entregas_Service/ubicacion_service.dart';
import 'package:tobaco/Services/Cache/database_helper.dart';
import 'package:tobaco/Services/Connectivity/connectivity_service.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';
import 'package:tobaco/Models/User.dart';
import 'package:tobaco/Services/RecorridosProgramados_Service/recorridos_programados_service.dart';
import 'package:tobaco/Models/RecorridoProgramado.dart';
import 'package:tobaco/Models/DiaSemana.dart';
import 'package:tobaco/Models/Cliente.dart';

/// Provider para gestionar el estado de las entregas y el mapa
/// Maneja SQLite para modo offline y sincronización
class EntregasProvider with ChangeNotifier {
  final EntregasService entregasService;
  final UbicacionService ubicacionService;
  final DatabaseHelper databaseHelper;
  final ConnectivityService connectivityService;
  final RecorridosProgramadosService _recorridosService = RecorridosProgramadosService();

  List<Entrega> _entregas = [];
  Position? _posicionActual;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _seguimientoActivo = false;
  bool _disposed = false;

  EntregasProvider({
    required this.entregasService,
    required this.ubicacionService,
    required this.databaseHelper,
    required this.connectivityService,
  });

  // Getters
  List<Entrega> get entregas => _entregas;
  Position? get posicionActual => _posicionActual;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get seguimientoActivo => _seguimientoActivo;

  // Entregas por estado (solo del día actual)
  List<Entrega> get entregasPendientes => 
      _entregas.where((e) => e.estaPendiente && _esDelDiaActual(e)).toList();
  
  List<Entrega> get entregasCompletadas => 
      _entregas.where((e) => e.estaCompletada && _esDelDiaActual(e)).toList();
  
  /// Verifica si una entrega es del día actual
  bool _esDelDiaActual(Entrega entrega) {
    final hoy = DateTime.now();
    final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDelDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);
    
    // Para entregas completadas, verificar por fecha de entrega si existe, sino por fecha de asignación
    if (entrega.estaCompletada && entrega.fechaEntrega != null) {
      return entrega.fechaEntrega!.isAfter(inicioDelDia.subtract(const Duration(days: 1))) &&
             entrega.fechaEntrega!.isBefore(finDelDia.add(const Duration(days: 1)));
    }
    
    // Para entregas pendientes, verificar por fecha de asignación
    return entrega.fechaAsignacion.isAfter(inicioDelDia.subtract(const Duration(days: 1))) &&
           entrega.fechaAsignacion.isBefore(finDelDia.add(const Duration(days: 1)));
  }

  List<Entrega> get entregasParciales => 
      _entregas.where((e) => e.estado == EstadoEntrega.parcial).toList();

  // Siguiente entrega
  Entrega? get siguienteEntrega => 
      ubicacionService.obtenerSiguienteEntrega(_entregas);

  /// Inicializa el provider (carga entregas y ubicación)
  Future<void> inicializar() async {
    try {
      // Cargar en paralelo para mejor rendimiento
      await Future.wait([
        cargarEntregasDelDia(),
        obtenerUbicacionActual(),
      ]);
    } catch (e) {
      _error = 'Error al inicializar: $e';
      if (!_disposed && hasListeners) notifyListeners();
    }
  }

  /// Carga las entregas o recorridos del día según el tipo de usuario
  /// Si hay conexión: carga del servidor y guarda en SQLite
  /// Si no hay conexión: carga de SQLite
  Future<void> cargarEntregasDelDia() async {
    try {
      _isLoading = true;
      _error = null;
      if (!_disposed && hasListeners) notifyListeners();

      // Limpiar entregas completadas de días anteriores (no bloquear si falla)
      try {
        await _limpiarEntregasCompletadasDeDiasAnteriores();
      } catch (e) {
        debugPrint('⚠️ Error al limpiar entregas de días anteriores: $e');
        // Continuar aunque falle
      }

      if (connectivityService.isFullyConnected) {
        // Online: intentar obtener del servidor con timeout
        try {
          final entregasDelServidor = await entregasService.obtenerEntregasDelServidor()
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  debugPrint('⚠️ Timeout al obtener entregas del servidor');
                  throw Exception('Timeout al conectar con el servidor');
                },
              );
          // Guardar en SQLite (preservando estados locales completados)
          await _guardarEntregasEnSQLite(entregasDelServidor);
          // Cargar desde SQLite para tener los estados preservados
          _entregas = await _obtenerEntregasDeSQLite();
        } catch (e) {
          // Si falla el servidor (timeout, conexión, etc.), cargar de SQLite
          debugPrint('⚠️ Error al obtener del servidor, cargando de SQLite: $e');
          _entregas = await _obtenerEntregasDeSQLite();
        }
      } else {
        // Offline: cargar de SQLite
        debugPrint('📡 Sin conexión, cargando desde SQLite');
        _entregas = await _obtenerEntregasDeSQLite();
      }
      
      // Si es Vendedor, asegurar que tenga los recorridos programados del día
      // IMPORTANTE: Vendedor NO debe ver entregas asignadas (ventaId > 0), solo recorridos programados
      final usuario = await AuthService.getCurrentUser();
      if (usuario?.esVendedor == true && !usuario!.isAdmin) {
        // Filtrar cualquier entrega de venta asignada que pueda haber venido del servidor
        _entregas.removeWhere((e) => e.ventaId != null && e.ventaId! > 0);
        
        // Agregar recorridos programados si faltan (solo si hay conexión)
        // En modo offline, los recorridos ya deberían estar en SQLite
        if (connectivityService.isFullyConnected) {
          try {
            await _agregarRecorridosProgramadosSiFaltan(usuario.id);
          } catch (e) {
            debugPrint('⚠️ Error al agregar recorridos programados: $e');
            // Continuar aunque falle, los recorridos pueden estar en SQLite
          }
        }
      }

      // Filtrar entregas del día actual (incluye completadas del día)
      final usuarioActual = await AuthService.getCurrentUser();
      _entregas = _filtrarEntregasDelDia(_entregas, usuarioActual);

      // Ordenar por cercanía si tenemos posición actual
      if (_posicionActual != null) {
        _entregas = ubicacionService.ordenarEntregasPorCercania(
          _entregas,
          _posicionActual,
        );
      }

      // Si hay conexión, sincronizar entregas pendientes en segundo plano
      // (no bloquear la carga inicial)
      if (connectivityService.isFullyConnected) {
        sincronizar().then((cantidad) {
          if (cantidad > 0 && !_disposed) {
            debugPrint('✅ Sincronizadas $cantidad entregas pendientes');
            // Recargar entregas después de sincronizar para actualizar estados
            // Solo actualizar la lista si hay cambios
            _actualizarEntregasDesdeSQLite();
          }
        }).catchError((e) {
          debugPrint('⚠️ Error al sincronizar entregas: $e');
        });
      }

      _isLoading = false;
      if (!_disposed && hasListeners) notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Error crítico al cargar entregas: $e');
      debugPrint('Stack trace: $stackTrace');
      _error = 'Error al cargar entregas: $e';
      // Asegurar que siempre se intente cargar desde SQLite como fallback
      try {
        _entregas = await _obtenerEntregasDeSQLite();
        debugPrint('✅ Cargadas ${_entregas.length} entregas desde SQLite como fallback');
      } catch (sqliteError) {
        debugPrint('❌ Error también al cargar desde SQLite: $sqliteError');
        _entregas = []; // Lista vacía como último recurso
      }
      _isLoading = false;
      if (!_disposed && hasListeners) notifyListeners();
    }
  }

  /// Limpia entregas completadas de días anteriores de SQLite
  /// Elimina entregas completadas que fueron entregadas antes del día actual
  Future<void> _limpiarEntregasCompletadasDeDiasAnteriores() async {
    final usuario = await AuthService.getCurrentUser();
    final repartidorId = usuario?.id;
    
    final hoy = DateTime.now();
    final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day).toIso8601String();
    
    final db = await databaseHelper.database;
    
    // Limpiar entregas completadas de días anteriores
    // Por fecha de entrega (si existe) o por fecha de asignación (si no tiene fecha de entrega)
    // También limpiar recorridos programados completados de días anteriores (ventaId == 0)
    String whereClause = '''
      estado = ? AND (
        (fecha_entrega IS NOT NULL AND fecha_entrega < ?) OR
        (fecha_entrega IS NULL AND fecha_asignacion < ?)
      )
    ''';
    List<dynamic> whereArgs = [
      EstadoEntrega.entregada.toJson(), 
      inicioDelDia,  // fecha_entrega < inicioDelDia
      inicioDelDia,  // fecha_asignacion < inicioDelDia
    ];
    
    if (repartidorId != null) {
      whereClause += ' AND repartidor_id = ?';
      whereArgs.add(repartidorId);
    }
    
    await db.delete(
      'entregas_offline',
      where: whereClause,
      whereArgs: whereArgs,
    );
  }

  /// Guarda entregas en SQLite
  /// Preserva el estado local de entregas completadas (no sobrescribe con datos del servidor)
  Future<void> _guardarEntregasEnSQLite(List<Entrega> entregas) async {
    final usuario = await AuthService.getCurrentUser();
    final repartidorId = usuario?.id;
    
    // Obtener IDs de las entregas que vienen del servidor
    final idsDelServidor = entregas.map((e) => e.id).whereType<int>().toSet();
    
    // Obtener entregas del día actual del cache
    final entregasDelDia = await databaseHelper.obtenerEntregasDelDia(repartidorId: repartidorId);
    
    // Crear un mapa de entregas completadas localmente (para preservarlas)
    final entregasCompletadasLocal = <int, Entrega>{};
    for (var entregaCache in entregasDelDia) {
      if (entregaCache.id != null && 
          entregaCache.estaCompletada &&
          entregaCache.repartidorId == repartidorId) {
        entregasCompletadasLocal[entregaCache.id!] = entregaCache;
      }
    }
    
    // Eliminar entregas que ya no están en el servidor (excepto completadas y recorridos programados)
    // Los recorridos programados (ventaId == 0) no vienen del servidor, así que no los eliminamos
    for (var entregaCache in entregasDelDia) {
      if (entregaCache.id != null && 
          !idsDelServidor.contains(entregaCache.id) &&
          !entregaCache.estaCompletada &&
          entregaCache.ventaId != 0) { // No eliminar recorridos programados
        await databaseHelper.eliminarEntregaPorId(entregaCache.id!);
      }
    }
    
    // Guardar/actualizar las entregas del servidor
    // Si una entrega fue completada localmente, preservar ese estado
    // IMPORTANTE: Para recorridos programados (ventaId == 0), SIEMPRE preservar el estado local si existe
    for (var entrega in entregas) {
      // Si es un recorrido programado y existe en SQLite, preservar su estado local
      if (entrega.ventaId == 0 && entregasCompletadasLocal.containsKey(entrega.id)) {
        final entregaCompletada = entregasCompletadasLocal[entrega.id]!;
        // Preservar completamente el estado local del recorrido programado
        await databaseHelper.insertarEntrega(entregaCompletada);
      } else if (entrega.id != null && entregasCompletadasLocal.containsKey(entrega.id)) {
        // Preservar la entrega completada localmente (no sobrescribir)
        // Solo actualizar otros campos pero mantener el estado completado
        final entregaCompletada = entregasCompletadasLocal[entrega.id]!;
        await databaseHelper.insertarEntrega(
          entrega.copyWith(
            estado: entregaCompletada.estado,
            fechaEntrega: entregaCompletada.fechaEntrega,
            notas: entregaCompletada.notas ?? entrega.notas,
          ),
        );
      } else {
        // Entregas normales del servidor
        await databaseHelper.insertarEntrega(entrega);
      }
    }
  }

  /// Obtiene entregas de SQLite
  Future<List<Entrega>> _obtenerEntregasDeSQLite() async {
    final usuario = await AuthService.getCurrentUser();
    final repartidorId = usuario?.id;
    final entregas = await databaseHelper.obtenerEntregasDelDia(repartidorId: repartidorId);
    
    // Si es Vendedor (no Admin), filtrar entregas asignadas (solo recorridos programados)
    if (usuario?.esVendedor == true && !usuario!.isAdmin) {
      final recorridosProgramados = entregas.where((e) => e.ventaId == null || e.ventaId == 0).toList();
      debugPrint('📦 Cargadas ${recorridosProgramados.length} recorridos programados desde SQLite (filtradas ${entregas.length - recorridosProgramados.length} entregas asignadas)');
      return recorridosProgramados;
    }
    
    return entregas;
  }

  /// Actualiza las entregas desde SQLite sin recargar desde el servidor
  /// Útil para actualizar después de sincronizar cambios
  Future<void> _actualizarEntregasDesdeSQLite() async {
    try {
      final entregasDesdeSQLite = await _obtenerEntregasDeSQLite();
      
      // Actualizar la lista preservando el orden y posición actual
      final usuario = await AuthService.getCurrentUser();
      if (usuario?.esVendedor == true && !usuario!.isAdmin) {
        _entregas.removeWhere((e) => e.ventaId != null && e.ventaId! > 0);
        await _agregarRecorridosProgramadosSiFaltan(usuario.id);
      }
      
      final usuarioActual = await AuthService.getCurrentUser();
      _entregas = _filtrarEntregasDelDia(entregasDesdeSQLite, usuarioActual);
      
      // Ordenar por cercanía si tenemos posición actual
      if (_posicionActual != null) {
        _entregas = ubicacionService.ordenarEntregasPorCercania(
          _entregas,
          _posicionActual,
        );
      }
      
      if (!_disposed && hasListeners) notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Error al actualizar entregas desde SQLite: $e');
    }
  }

  /// Agrega recorridos programados del día si faltan (para Vendedor)
  /// Esto asegura que incluso si están en SQLite, se muestren los recorridos del día
  /// Verifica si ya están completados en SQLite y preserva su estado
  Future<void> _agregarRecorridosProgramadosSiFaltan(int vendedorId) async {
    try {
      // Obtener recorridos programados del día actual
      final recorridosDelDia = await _obtenerRecorridosProgramadosDelDia(vendedorId);
      
      if (recorridosDelDia.isEmpty) return;
      
      // Obtener IDs de recorridos que ya están en la lista
      final idsExistentes = _entregas
          .where((e) => e.ventaId == 0)
          .map((e) => e.id)
          .whereType<int>()
          .toSet();
      
      // Verificar en SQLite cuáles recorridos ya existen (completados o no)
      final hoy = DateTime.now();
      final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day);
      final finDelDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);
      
      // Primero, verificar y actualizar los recorridos que ya están en la lista
      // para asegurar que tengan el estado correcto desde SQLite
      for (var i = 0; i < _entregas.length; i++) {
        if (_entregas[i].ventaId == 0) {
          try {
            final entregaEnSQLite = await databaseHelper.obtenerEntregaPorId(_entregas[i].id!);
            if (entregaEnSQLite != null) {
              // Si en SQLite está completada y la fecha de entrega es de hoy, usar ese estado
              if (entregaEnSQLite.estaCompletada && 
                  entregaEnSQLite.fechaEntrega != null &&
                  entregaEnSQLite.fechaEntrega!.isAfter(inicioDelDia.subtract(const Duration(days: 1))) &&
                  entregaEnSQLite.fechaEntrega!.isBefore(finDelDia.add(const Duration(days: 1)))) {
                // Actualizar el estado en la lista con el de SQLite
                _entregas[i] = entregaEnSQLite;
              }
            }
          } catch (e) {
            // Continuar si hay error
          }
        }
      }
      
      // Obtener IDs de clientes que ya tienen ventas asignadas (entregas de venta, no recorridos)
      final clientesConVentaAsignada = _entregas
          .where((e) => e.ventaId != null && e.ventaId! > 0) // Solo entregas de venta
          .map((e) => e.clienteId)
          .toSet();
      
      // Ahora agregar los recorridos que faltan, pero filtrar los que ya tienen ventas asignadas
      int agregados = 0;
      int actualizados = 0;
      
      for (var recorrido in recorridosDelDia) {
        // Si el recorrido no está en la lista Y no tiene una venta asignada para ese cliente, agregarlo
        if (!idsExistentes.contains(recorrido.id) && 
            !clientesConVentaAsignada.contains(recorrido.clienteId)) {
          try {
            // Verificar si existe en SQLite con estado completado
            final entregaExistente = await databaseHelper.obtenerEntregaPorId(recorrido.id);
            
            if (entregaExistente != null && 
                entregaExistente.estaCompletada && 
                entregaExistente.fechaEntrega != null &&
                entregaExistente.fechaEntrega!.isAfter(inicioDelDia.subtract(const Duration(days: 1))) &&
                entregaExistente.fechaEntrega!.isBefore(finDelDia.add(const Duration(days: 1)))) {
              // Existe en SQLite y está completada hoy, usar ese estado
              _entregas.add(entregaExistente);
              actualizados++;
            } else {
              // No existe o no está completada, crear como pendiente
              final entrega = Entrega(
                id: recorrido.id,
                ventaId: 0, // VentaId = 0 indica recorrido programado
                clienteId: recorrido.clienteId,
                cliente: Cliente(
                  id: recorrido.clienteId,
                  nombre: recorrido.clienteNombre ?? 'Cliente',
                  direccion: recorrido.clienteDireccion,
                  latitud: recorrido.clienteLatitud,
                  longitud: recorrido.clienteLongitud,
                ),
                latitud: recorrido.clienteLatitud,
                longitud: recorrido.clienteLongitud,
                estado: EstadoEntrega.noEntregada,
                fechaAsignacion: inicioDelDia,
                repartidorId: recorrido.vendedorId,
                orden: recorrido.orden,
              );
              
              // Si existe en SQLite pero no está completada, usar el estado de SQLite
              if (entregaExistente != null) {
                entrega.estado = entregaExistente.estado;
                entrega.fechaEntrega = entregaExistente.fechaEntrega;
                entrega.notas = entregaExistente.notas;
              }
              
              _entregas.add(entrega);
              // Solo guardar en SQLite si no existe
              if (entregaExistente == null) {
                await databaseHelper.insertarEntrega(entrega);
              }
              agregados++;
            }
          } catch (e) {
            // Si hay error, crear como pendiente
            final entrega = Entrega(
              id: recorrido.id,
              ventaId: 0,
              clienteId: recorrido.clienteId,
              cliente: Cliente(
                id: recorrido.clienteId,
                nombre: recorrido.clienteNombre ?? 'Cliente',
                direccion: recorrido.clienteDireccion,
                latitud: recorrido.clienteLatitud,
                longitud: recorrido.clienteLongitud,
              ),
              latitud: recorrido.clienteLatitud,
              longitud: recorrido.clienteLongitud,
              estado: EstadoEntrega.noEntregada,
              fechaAsignacion: inicioDelDia,
              repartidorId: recorrido.vendedorId,
              orden: recorrido.orden,
            );
            _entregas.add(entrega);
            await databaseHelper.insertarEntrega(entrega);
            agregados++;
          }
        }
      }
      
      if (agregados > 0 || actualizados > 0) {
        debugPrint('✅ Agregados $agregados recorridos programados, actualizados $actualizados desde SQLite para Vendedor');
      }
    } catch (e) {
      debugPrint('⚠️ Error al agregar recorridos programados: $e');
      // No fallar, solo continuar
    }
  }

  /// Obtiene los recorridos programados del día actual
  Future<List<RecorridoProgramado>> _obtenerRecorridosProgramadosDelDia(int vendedorId) async {
    try {
      // Obtener todos los recorridos del vendedor
      final todosLosRecorridos = await _recorridosService.obtenerRecorridosPorVendedor(vendedorId);
      
      // Obtener el día actual de la semana
      final hoy = DateTime.now();
      final diaActual = _obtenerDiaSemana(hoy);
      
      // Filtrar solo los recorridos del día actual y activos
      return todosLosRecorridos.where((r) => 
        r.diaSemana == diaActual && 
        r.activo
      ).toList();
    } catch (e) {
      debugPrint('⚠️ Error al obtener recorridos programados del día: $e');
      return [];
    }
  }

  /// Obtiene el día de la semana actual
  DiaSemana _obtenerDiaSemana(DateTime fecha) {
    // DateTime.weekday: 1=Lunes, 2=Martes, ..., 7=Domingo
    // Nuestro enum: 0=Domingo, 1=Lunes, 2=Martes, ..., 6=Sábado
    int diaValue = fecha.weekday % 7; // Convierte 7 (domingo) a 0
    return DiaSemana.values.firstWhere(
      (d) => d.value == diaValue,
      orElse: () => DiaSemana.lunes,
    );
  }

  /// Filtra entregas del día actual (incluye completadas del día)
  /// Los recorridos programados completados solo se muestran si fueron completados hoy
  /// [usuario] Usuario actual para determinar si es Repartidor y filtrar recorridos
  List<Entrega> _filtrarEntregasDelDia(List<Entrega> entregas, User? usuario) {
    final hoy = DateTime.now();
    final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDelDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);
    
    // Verificar si es Repartidor para filtrar recorridos programados
    final esRepartidor = usuario?.esRepartidor == true && !usuario!.isAdmin;
    
    return entregas.where((e) {
      // Repartidor: NO debe ver recorridos programados (ventaId == 0)
      if (esRepartidor && e.ventaId == 0) {
        return false;
      }
      
      // Si es un recorrido programado (VentaId == 0) - solo para Vendedor/RepartidorVendedor
      if (e.ventaId == 0) {
        // Si está completado, solo mostrarlo si fue completado hoy
        if (e.estaCompletada && e.fechaEntrega != null) {
          return e.fechaEntrega!.isAfter(inicioDelDia.subtract(const Duration(days: 1))) &&
                 e.fechaEntrega!.isBefore(finDelDia.add(const Duration(days: 1)));
        }
        // Si está pendiente, verificamos que la fecha de asignación sea del día actual
        return e.fechaAsignacion.isAfter(inicioDelDia.subtract(const Duration(days: 1))) &&
               e.fechaAsignacion.isBefore(finDelDia.add(const Duration(days: 1)));
      }
      
      // Para entregas normales (no recorridos programados)
      // Verificar que la fecha de asignación sea del día actual
      if (e.fechaAsignacion.isBefore(inicioDelDia) || e.fechaAsignacion.isAfter(finDelDia)) {
        return false;
      }
      
      // Mostrar todas las entregas del día: pendientes, parciales y completadas
      // Las entregas completadas se muestran si fueron completadas hoy
      if (e.estaCompletada && e.fechaEntrega != null) {
        return e.fechaEntrega!.isAfter(inicioDelDia.subtract(const Duration(days: 1))) &&
               e.fechaEntrega!.isBefore(finDelDia.add(const Duration(days: 1)));
      }
      
      // Mostrar entregas pendientes y parciales del día
      return true;
    }).toList();
  }

  /// Obtiene la ubicación actual
  /// No bloquea si no puede obtener la ubicación (permisos, GPS, etc.)
  Future<bool> obtenerUbicacionActual() async {
    try {
      // Usar timeout para evitar que se quede bloqueado
      _posicionActual = await ubicacionService.obtenerPosicionActual()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⚠️ Timeout al obtener ubicación');
              return null;
            },
          );
      
      if (_posicionActual != null) {
        // Recalcular distancias
        _entregas = ubicacionService.ordenarEntregasPorCercania(
          _entregas,
          _posicionActual,
        );
        if (!_disposed && hasListeners) notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error al obtener ubicación: $e';
      if (!_disposed && hasListeners) notifyListeners();
      return false;
    }
  }

  /// Inicia el seguimiento en tiempo real de la ubicación
  void iniciarSeguimientoUbicacion() {
    if (_seguimientoActivo || _disposed) return;

    _positionStreamSubscription = ubicacionService
        .iniciarSeguimientoUbicacion()
        .listen((Position position) {
      if (_disposed) return; // No procesar si ya fue disposed
      
      _posicionActual = position;
      
      // Actualizar distancias de las entregas pendientes
      for (var entrega in _entregas) {
        if (entrega.tieneCoordenadasValidas && !entrega.estaCompletada) {
          entrega.distanciaDesdeUbicacionActual = 
              ubicacionService.calcularDistanciaDesdeActual(
                entrega.latitud!,
                entrega.longitud!,
              );
        }
      }
      
      if (!_disposed && hasListeners) notifyListeners();
    });

    _seguimientoActivo = true;
    if (!_disposed && hasListeners) notifyListeners();
  }

  /// Detiene el seguimiento de ubicación
  void detenerSeguimientoUbicacion() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _seguimientoActivo = false;
    // NO notificar aquí - puede causar error si se llama desde dispose()
  }

  /// Marca una entrega como completada
  /// Si hay conexión: actualiza en servidor y SQLite
  /// Si no hay conexión: actualiza solo en SQLite y marca para sincronizar
  Future<bool> marcarComoEntregada(int entregaId, {String? notas}) async {
    try {
      // Actualizar en SQLite primero
      await databaseHelper.marcarEntregaComoEntregada(entregaId, notas);

      // Actualizar en la lista del provider (NO remover, solo cambiar estado)
      // Así aparecerá en entregas completadas del día
      int index = _entregas.indexWhere((e) => e.id == entregaId);
      if (index != -1) {
        _entregas[index] = _entregas[index].copyWith(
          estado: EstadoEntrega.entregada,
          fechaEntrega: DateTime.now(),
          notas: notas,
        );
        // NO remover de la lista - debe aparecer en completadas del día
      }

      // Si hay conexión, sincronizar con servidor
      if (connectivityService.isFullyConnected) {
        try {
          bool exito = await entregasService.marcarComoEntregada(
            entregaId,
            notas: notas,
          );
          if (exito) {
            await databaseHelper.marcarEntregaSincronizada(entregaId);
          } else {
            await databaseHelper.marcarEntregaParaSincronizar(entregaId);
          }
        } catch (e) {
          // Si falla, marcar para sincronizar después
          await databaseHelper.marcarEntregaParaSincronizar(entregaId);
        }
      } else {
        // Offline: marcar para sincronizar cuando haya conexión
        await databaseHelper.marcarEntregaParaSincronizar(entregaId);
      }

      if (!_disposed && hasListeners) notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al marcar entrega como completada: $e';
      if (!_disposed && hasListeners) notifyListeners();
      return false;
    }
  }

  /// Actualiza el estado de una entrega
  /// Si hay conexión: actualiza en servidor y SQLite
  /// Si no hay conexión: actualiza solo en SQLite y marca para sincronizar
  Future<bool> actualizarEstado(int entregaId, EstadoEntrega nuevoEstado) async {
    try {
      // Actualizar en SQLite primero
      await databaseHelper.actualizarEstadoEntrega(entregaId, nuevoEstado);

      // Actualizar en la lista del provider
      int index = _entregas.indexWhere((e) => e.id == entregaId);
      if (index != -1) {
        _entregas[index] = _entregas[index].copyWith(estado: nuevoEstado);
      }

      // Si hay conexión, sincronizar con servidor
      if (connectivityService.isFullyConnected) {
        try {
          bool exito = await entregasService.actualizarEstadoEntrega(
            entregaId,
            nuevoEstado,
          );
          if (exito) {
            await databaseHelper.marcarEntregaSincronizada(entregaId);
          } else {
            await databaseHelper.marcarEntregaParaSincronizar(entregaId);
          }
        } catch (e) {
          await databaseHelper.marcarEntregaParaSincronizar(entregaId);
        }
      } else {
        await databaseHelper.marcarEntregaParaSincronizar(entregaId);
      }

      if (!_disposed && hasListeners) notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al actualizar estado: $e';
      if (!_disposed && hasListeners) notifyListeners();
      return false;
    }
  }

  /// Agrega notas a una entrega
  /// Si hay conexión: actualiza en servidor y SQLite
  /// Si no hay conexión: actualiza solo en SQLite
  Future<bool> agregarNotas(int entregaId, String notas) async {
    try {
      // Actualizar en SQLite primero
      await databaseHelper.actualizarNotasEntrega(entregaId, notas);

      // Actualizar en la lista del provider
      int index = _entregas.indexWhere((e) => e.id == entregaId);
      if (index != -1) {
        _entregas[index] = _entregas[index].copyWith(notas: notas);
      }

      // Si hay conexión, sincronizar con servidor
      if (connectivityService.isFullyConnected) {
        try {
          await entregasService.agregarNotas(entregaId, notas);
        } catch (e) {
          debugPrint('⚠️ Error al sincronizar notas: $e');
        }
      }

      if (!_disposed && hasListeners) notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al agregar notas: $e';
      if (!_disposed && hasListeners) notifyListeners();
      return false;
    }
  }

  /// Calcula la ruta óptima
  void calcularRutaOptima() {
    if (_posicionActual == null) {
      _error = 'No se puede calcular ruta sin ubicación actual';
      if (!_disposed && hasListeners) notifyListeners();
      return;
    }

    _entregas = ubicacionService.calcularRutaOptima(
      _entregas,
      _posicionActual!,
    );
    
    if (!_disposed && hasListeners) notifyListeners();
  }

  /// Obtiene estadísticas del día desde las entregas en memoria
  Map<String, dynamic> obtenerEstadisticas() {
    int totales = _entregas.length;
    int completadas = _entregas.where((e) => e.estaCompletada).length;
    int pendientes = _entregas.where((e) => e.estaPendiente).length;
    int parciales = _entregas.where((e) => e.estado == EstadoEntrega.parcial).length;
    
    double distanciaTotal = 0;
    if (_posicionActual != null) {
      distanciaTotal = ubicacionService.calcularDistanciaTotal(_entregas, _posicionActual);
    }
    
    return {
      'totales': totales,
      'completadas': completadas,
      'pendientes': pendientes,
      'parciales': parciales,
      'distanciaTotal': distanciaTotal,
      'porcentajeCompletado': totales > 0 ? (completadas / totales * 100).round() : 0,
    };
  }

  /// Sincroniza entregas pendientes con el servidor
  /// Intenta sincronizar entregas que fueron marcadas como completadas/parciales offline
  Future<int> sincronizar() async {
    try {
      if (!connectivityService.isFullyConnected) {
        debugPrint('📡 Sin conexión, no se puede sincronizar');
        return 0;
      }

      List<Entrega> entregasPendientes = 
          await databaseHelper.obtenerEntregasPendientesDeSincronizar();
      
      if (entregasPendientes.isEmpty) {
        debugPrint('✅ No hay entregas pendientes de sincronizar');
        return 0;
      }
      
      debugPrint('🔄 Sincronizando ${entregasPendientes.length} entregas pendientes...');
      int sincronizadas = 0;
      
      for (var entrega in entregasPendientes) {
        try {
          // Sincronizar estado y notas
          bool exito = await entregasService.marcarComoEntregada(
            entrega.id!,
            notas: entrega.notas,
          );
          
          if (exito) {
            await databaseHelper.marcarEntregaSincronizada(entrega.id!);
            sincronizadas++;
            debugPrint('✅ Sincronizada entrega ${entrega.id}');
          } else {
            debugPrint('⚠️ No se pudo sincronizar entrega ${entrega.id}');
          }
        } catch (e) {
          debugPrint('⚠️ Error al sincronizar entrega ${entrega.id}: $e');
          // Continuar con las siguientes entregas
        }
      }
      
      if (sincronizadas > 0) {
        debugPrint('✅ Sincronizadas $sincronizadas de ${entregasPendientes.length} entregas');
      }
      
      return sincronizadas;
    } catch (e) {
      debugPrint('⚠️ Error al sincronizar entregas: $e');
      _error = 'Error al sincronizar: $e';
      if (!_disposed && hasListeners) notifyListeners();
      return 0;
    }
  }

  /// Refresca las entregas desde el servidor
  Future<void> refrescar() async {
    await cargarEntregasDelDia();
    // Obtener ubicación sin bloquear si falla
    try {
      await obtenerUbicacionActual().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ Timeout al obtener ubicación en refrescar');
          return false;
        },
      );
    } catch (e) {
      debugPrint('⚠️ Error al obtener ubicación en refrescar: $e');
      // Continuar aunque falle la ubicación
    }
  }

  /// Calcula la distancia total de la ruta
  double get distanciaTotal {
    if (_posicionActual == null) return 0;
    return ubicacionService.calcularDistanciaTotal(_entregas, _posicionActual);
  }

  /// Calcula el tiempo estimado restante
  Duration get tiempoEstimado {
    double distanciaPendiente = 0;
    
    if (_posicionActual != null) {
      List<Entrega> pendientes = entregasPendientes
          .where((e) => e.tieneCoordenadasValidas)
          .toList();
      
      distanciaPendiente = ubicacionService.calcularDistanciaTotal(
        pendientes,
        _posicionActual,
      );
    }
    
    return ubicacionService.calcularTiempoEstimado(distanciaPendiente);
  }

  /// Avanza a la siguiente entrega
  void avanzarSiguienteEntrega() {
    final siguiente = siguienteEntrega;
    if (siguiente != null && !_disposed && hasListeners) {
      notifyListeners();
    }
  }

  /// Limpia el error
  void limpiarError() {
    _error = null;
    if (!_disposed && hasListeners) notifyListeners();
  }

  @override
  void dispose() {
    // Marcar como disposed PRIMERO para prevenir cualquier notificación
    _disposed = true;
    
    // Cancelar stream de ubicación inmediatamente
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _seguimientoActivo = false;
    
    // Limpiar servicio de ubicación
    ubicacionService.dispose();
    
    // Llamar al dispose del padre
    super.dispose();
  }
}

