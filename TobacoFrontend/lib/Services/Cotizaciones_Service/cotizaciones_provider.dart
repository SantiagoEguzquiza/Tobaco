import 'package:flutter/foundation.dart';
import 'package:tobaco/Models/Cotizacion.dart';
import 'package:tobaco/Services/Cotizaciones_Service/cotizaciones_repo.dart';

class BcuProvider with ChangeNotifier {
  final BcuRepository repo;
  BcuProvider(this.repo);

  bool _loading = false;
  String? _error;
  List<Cotizacion> _items = [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<Cotizacion> get items => _items;

  Future<void> loadCotizaciones({
    required List<int> monedas,
    required DateTime desde,
    required DateTime hasta,
    required int grupo,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await repo.getCotizaciones(
        monedas: monedas, desde: desde, hasta: hasta, grupo: grupo,
      );
    } catch (e) {
      _error = e.toString();
      _items = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
