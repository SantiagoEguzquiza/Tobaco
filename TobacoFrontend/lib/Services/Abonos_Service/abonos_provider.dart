import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Abono.dart';
import 'package:tobaco/Services/Abonos_Service/abonos_service.dart';
import 'package:tobaco/Services/Cache/cuenta_corriente_cache_service.dart';
import 'package:tobaco/Services/Connectivity/connectivity_service.dart';

class AbonosProvider with ChangeNotifier {
  final AbonosService _abonosService = AbonosService();
  final CuentaCorrienteCacheService _ccCacheService = CuentaCorrienteCacheService();
  final ConnectivityService _connectivityService = ConnectivityService();

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
      final tieneConexion = await _connectivityService.checkFullConnectivity();
      if (!tieneConexion) {
        final offline = await _ccCacheService.obtenerAbonosOffline(clienteId);
        _abonos = List<Abono>.from(offline);
        notifyListeners();
        return offline;
      }
      final abonos = await _abonosService.obtenerAbonosPorClienteId(clienteId);
      _abonos = List<Abono>.from(abonos);
      await _ccCacheService.cacheAbonos(clienteId, abonos);
      notifyListeners();
      return abonos;
    } catch (e) {
      _setError('Error al obtener los abonos del cliente: $e');
      debugPrint('Error: $e');
      final esTimeout = e is TimeoutException;
      if (Apihandler.isConnectionError(e) || esTimeout) {
        final offline = await _ccCacheService.obtenerAbonosOffline(clienteId);
        _abonos = List<Abono>.from(offline);
        notifyListeners();
        return offline;
      }
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

  Future<Abono?> saldarDeuda(
    int clienteId,
    double monto,
    DateTime fecha,
    String? nota, {
    required String clienteNombre,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final tieneConexion = await _connectivityService.checkFullConnectivity();
      if (!tieneConexion) {
        final abonoOffline = await _ccCacheService.registrarAbonoOffline(
          clienteId: clienteId,
          clienteNombre: clienteNombre,
          monto: monto,
          nota: nota,
        );
        _abonos.add(abonoOffline);
        notifyListeners();
        return abonoOffline;
      }

      final abonoCreado = await _abonosService.saldarDeuda(clienteId, monto, fecha, nota);
      _abonos.add(abonoCreado);
      await _ccCacheService.cacheAbonos(clienteId, _abonos);
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

  Future<bool> eliminarAbono(int id) async {
    _setLoading(true);
    _clearError();
    try {
      await _abonosService.eliminarAbono(id);
      int? clienteId;
      final index = _abonos.indexWhere((abono) => abono.id == id);
      if (index != -1) {
        clienteId = _abonos[index].clienteId;
        _abonos.removeAt(index);
      } else if (_abonos.isNotEmpty) {
        clienteId = _abonos.first.clienteId;
      }
      if (clienteId != null) {
        final abonosCliente =
            _abonos.where((abono) => abono.clienteId == clienteId).toList();
        await _ccCacheService.cacheAbonos(clienteId, abonosCliente);
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error en AbonosProvider.eliminarAbono: $_errorMessage');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearAbonos() {
    _abonos.clear();
    notifyListeners();
  }
}
