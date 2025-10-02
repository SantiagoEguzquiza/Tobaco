import 'package:flutter/material.dart';
import 'package:tobaco/Models/Abono.dart';
import 'package:tobaco/Services/Abonos_Service/abonos_service.dart';

class AbonosProvider with ChangeNotifier {
  final AbonosService _abonosService = AbonosService();

  List<Abono> _abonos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Abono> get abonos => _abonos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<List<Abono>> obtenerAbonos() async {
    _setLoading(true);
    _clearError();
    
    try {
      _abonos = await _abonosService.obtenerAbonos();
      notifyListeners();
      return _abonos;
    } catch (e) {
      _setError('Error al obtener los abonos: $e');
      debugPrint('Error: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Abono>> obtenerAbonosPorClienteId(int clienteId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final abonos = await _abonosService.obtenerAbonosPorClienteId(clienteId);
      notifyListeners();
      return abonos;
    } catch (e) {
      _setError('Error al obtener los abonos del cliente: $e');
      debugPrint('Error: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<Abono?> crearAbono(Abono abono) async {
    _setLoading(true);
    _clearError();
    
    try {
      final abonoCreado = await _abonosService.crearAbono(abono);
      _abonos.add(abonoCreado);
      notifyListeners();
      return abonoCreado;
    } catch (e) {
      _setError('Error al crear el abono: $e');
      debugPrint('Error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> actualizarAbono(Abono abono) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _abonosService.actualizarAbono(abono);
      int index = _abonos.indexWhere((a) => a.id == abono.id);
      if (index != -1) {
        _abonos[index] = abono;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Error al actualizar el abono: $e');
      debugPrint('Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> eliminarAbono(int id) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _abonosService.eliminarAbono(id);
      _abonos.removeWhere((abono) => abono.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar el abono: $e');
      debugPrint('Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Abono?> saldarDeuda(int clienteId, double monto, DateTime fecha, String? nota) async {
    _setLoading(true);
    _clearError();
    
    try {
      final abonoCreado = await _abonosService.saldarDeuda(clienteId, monto, fecha, nota);
      _abonos.add(abonoCreado);
      notifyListeners();
      return abonoCreado;
    } catch (e) {
      _setError('Error al saldar la deuda: $e');
      debugPrint('Error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearAbonos() {
    _abonos.clear();
    notifyListeners();
  }
}
