import 'package:flutter/foundation.dart';
import 'package:tobaco/Helpers/api_handler.dart';
import 'package:tobaco/Models/Compra.dart';
import 'package:tobaco/Services/Compras_Service/compras_service.dart';

class ComprasProvider with ChangeNotifier {
  final ComprasService _service = ComprasService();

  List<Compra> _compras = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isConnectionError = false;

  List<Compra> get compras => _compras;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isConnectionError => _isConnectionError;

  Future<void> cargarCompras({DateTime? desde, DateTime? hasta}) async {
    _isLoading = true;
    _errorMessage = null;
    _isConnectionError = false;
    notifyListeners();

    try {
      _compras = await _service.getCompras(desde: desde, hasta: hasta);
    } catch (e) {
      if (Apihandler.isConnectionError(e)) {
        _isConnectionError = true;
        _errorMessage = null;
      } else {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Compra?> obtenerCompra(int id) async {
    try {
      return await _service.getCompraById(id);
    } catch (_) {
      return null;
    }
  }

  Future<void> eliminarCompra(int id) async {
    await _service.eliminarCompra(id);
  }

  void clearError() {
    _errorMessage = null;
    _isConnectionError = false;
    notifyListeners();
  }
}
