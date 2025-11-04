import 'package:flutter/material.dart';
import '../../Models/RecorridoProgramado.dart';
import '../../Models/DiaSemana.dart';
import 'recorridos_programados_service.dart';

class RecorridosProgramadosProvider extends ChangeNotifier {
  final RecorridosProgramadosService _service = RecorridosProgramadosService();

  List<RecorridoProgramado> _recorridos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RecorridoProgramado> get recorridos => _recorridos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Obtiene todos los recorridos programados de un vendedor
  Future<List<RecorridoProgramado>> obtenerRecorridosPorVendedor(int vendedorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recorridos = await _service.obtenerRecorridosPorVendedor(vendedorId);
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return _recorridos.where((r) => r.activo).toList();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      debugPrint('Error al obtener recorridos: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Crea un nuevo recorrido programado
  Future<RecorridoProgramado> crearRecorrido({
    required int vendedorId,
    required int clienteId,
    required DiaSemana diaSemana,
    required int orden,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nuevoRecorrido = await _service.crearRecorrido(
        vendedorId: vendedorId,
        clienteId: clienteId,
        diaSemana: diaSemana,
        orden: orden,
      );
      
      // Agregar a la lista local
      _recorridos.add(nuevoRecorrido);
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return nuevoRecorrido;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      debugPrint('Error al crear recorrido: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Actualiza un recorrido programado
  Future<RecorridoProgramado> actualizarRecorrido({
    required int id,
    int? clienteId,
    DiaSemana? diaSemana,
    int? orden,
    bool? activo,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final recorridoActualizado = await _service.actualizarRecorrido(
        id: id,
        clienteId: clienteId,
        diaSemana: diaSemana,
        orden: orden,
        activo: activo,
      );
      
      // Actualizar en la lista local
      final index = _recorridos.indexWhere((r) => r.id == id);
      if (index != -1) {
        _recorridos[index] = recorridoActualizado;
      }
      
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return recorridoActualizado;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      debugPrint('Error al actualizar recorrido: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Elimina un recorrido programado
  Future<bool> eliminarRecorrido(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultado = await _service.eliminarRecorrido(id);
      
      if (resultado) {
        // Remover de la lista local
        _recorridos.removeWhere((r) => r.id == id);
      }
      
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return resultado;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      debugPrint('Error al eliminar recorrido: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Obtiene los recorridos filtrados por día
  List<RecorridoProgramado> recorridosPorDia(DiaSemana dia, int? vendedorId) {
    return _recorridos
        .where((r) => r.diaSemana == dia && 
                      r.vendedorId == vendedorId && 
                      r.activo)
        .toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));
  }
}

