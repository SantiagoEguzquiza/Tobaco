import 'package:flutter/foundation.dart';
import '../Services/api_service.dart';

class CurrencyProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  double _currentRate = 0.0;
  bool _isLoading = false;
  String _error = '';
  DateTime? _lastUpdate;

  // Getters
  double get currentRate => _currentRate;
  bool get isLoading => _isLoading;
  String get error => _error;
  DateTime? get lastUpdate => _lastUpdate;

  Future<void> fetchExchangeRate() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentRate = await _apiService.getUsdToUyuRate();
      _lastUpdate = DateTime.now();
      _error = '';
    } catch (e) {
      _error = e.toString();
      _currentRate = 0.0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
