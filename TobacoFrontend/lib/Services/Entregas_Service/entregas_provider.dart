import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tobaco/Models/Entrega.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';
import 'package:tobaco/Services/Entregas_Service/entregas_service.dart';
import 'package:tobaco/Services/Entregas_Service/ubicacion_service.dart';

/// Provider para gestionar el estado de las entregas y el mapa
class EntregasProvider with ChangeNotifier {
  final EntregasService entregasService;
  final UbicacionService ubicacionService;

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
  });

  // Getters
  List<Entrega> get entregas => _entregas;
  Position? get posicionActual => _posicionActual;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get seguimientoActivo => _seguimientoActivo;

  // Entregas por estado
  List<Entrega> get entregasPendientes => 
      _entregas.where((e) => e.estaPendiente).toList();
  
  List<Entrega> get entregasCompletadas => 
      _entregas.where((e) => e.estaCompletada).toList();

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
  Future<void> cargarEntregasDelDia() async {
    try {
      _isLoading = true;
      _error = null;
      if (!_disposed && hasListeners) notifyListeners();

      // Obtener entregas o recorridos según el tipo de usuario
      _entregas = await entregasService.obtenerEntregasORecorridosDelDia();

      // Ordenar por cercanía si tenemos posición actual
      if (_posicionActual != null) {
        _entregas = ubicacionService.ordenarEntregasPorCercania(
          _entregas,
          _posicionActual,
        );
      }

      _isLoading = false;
      if (!_disposed && hasListeners) notifyListeners();
    } catch (e) {
      _error = 'Error al cargar entregas: $e';
      _isLoading = false;
      if (!_disposed && hasListeners) notifyListeners();
    }
  }

  /// Obtiene la ubicación actual
  Future<bool> obtenerUbicacionActual() async {
    try {
      _posicionActual = await ubicacionService.obtenerPosicionActual();
      
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
  Future<bool> marcarComoEntregada(int entregaId, {String? notas}) async {
    try {
      bool exito = await entregasService.marcarComoEntregada(
        entregaId,
        notas: notas,
      );

      if (exito) {
        // Actualizar en la lista local
        int index = _entregas.indexWhere((e) => e.id == entregaId);
        if (index != -1) {
          _entregas[index] = _entregas[index].copyWith(
            estado: EstadoEntrega.entregada,
            fechaEntrega: DateTime.now(),
            notas: notas,
          );
        }
        if (!_disposed && hasListeners) notifyListeners();
      }

      return exito;
    } catch (e) {
      _error = 'Error al marcar entrega como completada: $e';
      if (!_disposed && hasListeners) notifyListeners();
      return false;
    }
  }

  /// Actualiza el estado de una entrega
  Future<bool> actualizarEstado(int entregaId, EstadoEntrega nuevoEstado) async {
    try {
      bool exito = await entregasService.actualizarEstadoEntrega(
        entregaId,
        nuevoEstado,
      );

      if (exito) {
        int index = _entregas.indexWhere((e) => e.id == entregaId);
        if (index != -1) {
          _entregas[index] = _entregas[index].copyWith(estado: nuevoEstado);
        }
        if (!_disposed && hasListeners) notifyListeners();
      }

      return exito;
    } catch (e) {
      _error = 'Error al actualizar estado: $e';
      if (!_disposed && hasListeners) notifyListeners();
      return false;
    }
  }

  /// Agrega notas a una entrega
  Future<bool> agregarNotas(int entregaId, String notas) async {
    try {
      bool exito = await entregasService.agregarNotas(entregaId, notas);

      if (exito) {
        int index = _entregas.indexWhere((e) => e.id == entregaId);
        if (index != -1) {
          _entregas[index] = _entregas[index].copyWith(notas: notas);
        }
        if (!_disposed && hasListeners) notifyListeners();
      }

      return exito;
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

  /// Obtiene estadísticas del día
  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    return await entregasService.obtenerEstadisticasDelDia();
  }

  /// Sincroniza entregas pendientes con el servidor
  Future<int> sincronizar() async {
    try {
      int sincronizadas = await entregasService.sincronizarEntregasPendientes();
      return sincronizadas;
    } catch (e) {
      _error = 'Error al sincronizar: $e';
      if (!_disposed && hasListeners) notifyListeners();
      return 0;
    }
  }

  /// Refresca las entregas desde el servidor
  Future<void> refrescar() async {
    await cargarEntregasDelDia();
    await obtenerUbicacionActual();
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

