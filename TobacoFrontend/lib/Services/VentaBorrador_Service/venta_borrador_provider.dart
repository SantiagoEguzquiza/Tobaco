import 'package:flutter/material.dart';
import 'package:tobaco/Models/VentaBorrador.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/ProductoSeleccionado.dart';
import 'package:tobaco/Services/VentaBorrador_Service/venta_borrador_service.dart';

/// Provider para gestionar el estado de la venta en borrador
/// Maneja la creación, actualización y eliminación del borrador
class VentaBorradorProvider with ChangeNotifier {
  final VentaBorradorService _service = VentaBorradorService();
  VentaBorrador? _borradorActual;
  bool _mounted = true;

  VentaBorrador? get borradorActual => _borradorActual;
  bool get tieneBorrador => _borradorActual != null && _borradorActual!.tieneContenido;
  bool get mounted => _mounted;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  /// Carga el borrador desde el almacenamiento local al iniciar
  Future<void> cargarBorradorInicial() async {
    try {
      _borradorActual = await _service.cargarBorrador();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar borrador inicial: $e');
    }
  }

  /// Crea un nuevo borrador vacío
  void crearNuevoBorrador() {
    if (!_mounted) return; // No hacer nada si el provider no está montado

    _borradorActual = VentaBorrador(
      productosSeleccionados: [],
      preciosEspeciales: {},
      fechaCreacion: DateTime.now(),
      fechaUltimaModificacion: DateTime.now(),
    );
    _guardarBorrador();
    
    // Notificar listeners de forma segura
    if (_mounted) {
      Future.microtask(() {
        if (_mounted) {
          notifyListeners();
        }
      });
    }
  }

  /// Actualiza el cliente seleccionado en el borrador
  Future<void> actualizarCliente(Cliente? cliente) async {
    if (_borradorActual == null) {
      crearNuevoBorrador();
    }

    _borradorActual = _borradorActual!.copyWith(
      cliente: cliente,
      fechaUltimaModificacion: DateTime.now(),
    );
    
    await _guardarBorrador();
    notifyListeners();
  }

  /// Actualiza los productos seleccionados en el borrador
  Future<void> actualizarProductos(List<ProductoSeleccionado> productos) async {
    if (_borradorActual == null) {
      crearNuevoBorrador();
    }

    _borradorActual = _borradorActual!.copyWith(
      productosSeleccionados: productos,
      fechaUltimaModificacion: DateTime.now(),
    );
    
    await _guardarBorrador();
    notifyListeners();
  }

  /// Actualiza los precios especiales del cliente en el borrador
  Future<void> actualizarPreciosEspeciales(Map<int, double> precios) async {
    if (_borradorActual == null) {
      crearNuevoBorrador();
    }

    _borradorActual = _borradorActual!.copyWith(
      preciosEspeciales: precios,
      fechaUltimaModificacion: DateTime.now(),
    );
    
    await _guardarBorrador();
    notifyListeners();
  }

  /// Actualiza todo el borrador de una vez
  Future<void> actualizarBorrador({
    Cliente? cliente,
    List<ProductoSeleccionado>? productos,
    Map<int, double>? preciosEspeciales,
  }) async {
    if (!_mounted) return; // No hacer nada si el provider no está montado

    if (_borradorActual == null) {
      crearNuevoBorrador();
    }

    _borradorActual = _borradorActual!.copyWith(
      cliente: cliente ?? _borradorActual!.cliente,
      productosSeleccionados: productos ?? _borradorActual!.productosSeleccionados,
      preciosEspeciales: preciosEspeciales ?? _borradorActual!.preciosEspeciales,
      fechaUltimaModificacion: DateTime.now(),
    );
    
    await _guardarBorrador();
    
    // Notificar listeners de forma segura
    if (_mounted) {
      Future.microtask(() {
        if (_mounted) {
          notifyListeners();
        }
      });
    }
  }

  /// Elimina el borrador actual (al confirmar o cancelar venta)
  Future<void> eliminarBorrador() async {
    try {
      await _service.eliminarBorrador();
      _borradorActual = null;
      // Usar un microtask para evitar problemas con el tree lock
      Future.microtask(() {
        if (mounted) {
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Error al eliminar borrador: $e');
      rethrow;
    }
  }

  /// Limpia el borrador y crea uno nuevo (para empezar una nueva venta)
  Future<void> limpiarYCrearNuevo() async {
    await eliminarBorrador();
    crearNuevoBorrador();
  }

  /// Verifica si existe un borrador guardado
  Future<bool> verificarExistenciaBorrador() async {
    return await _service.existeBorrador();
  }

  /// Guarda el borrador actual en almacenamiento local
  Future<void> _guardarBorrador() async {
    if (_borradorActual != null) {
      await _service.guardarBorrador(_borradorActual!);
    }
  }

  /// Obtiene el tiempo transcurrido desde la última modificación
  String getTiempoTranscurrido() {
    if (_borradorActual == null) return '';

    final diferencia = DateTime.now().difference(_borradorActual!.fechaUltimaModificacion);
    
    if (diferencia.inMinutes < 1) {
      return 'Hace menos de un minuto';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} minuto${diferencia.inMinutes > 1 ? 's' : ''}';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} hora${diferencia.inHours > 1 ? 's' : ''}';
    } else {
      return 'Hace ${diferencia.inDays} día${diferencia.inDays > 1 ? 's' : ''}';
    }
  }
}

