import 'package:flutter/foundation.dart';
import 'package:tobaco/Models/Cotizacion.dart';
import 'package:tobaco/Services/Cotizaciones_Service/cotizaciones_repo.dart';

class BcuProvider with ChangeNotifier {
  final BcuRepository repo;
  BcuProvider(this.repo);

  bool _loading = false;
  String? _error;
  List<Cotizacion> _items = [];
  DateTime? _lastFetchTime; // Timestamp del último fetch local

  bool get isLoading => _loading;
  String? get error => _error;
  List<Cotizacion> get items => _items;
  DateTime? get lastFetchTime => _lastFetchTime;

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
      final result = await repo.getCotizaciones(
        monedas: monedas, desde: desde, hasta: hasta, grupo: grupo,
      );
      _items = result.items;
      _lastFetchTime = DateTime.now(); // Timestamp del fetch local
    } catch (e) {
      _error = e.toString();
      _items = [];
      _lastFetchTime = DateTime.now(); // Guardar timestamp incluso en caso de error
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
