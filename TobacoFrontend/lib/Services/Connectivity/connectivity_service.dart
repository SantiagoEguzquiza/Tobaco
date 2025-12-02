import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../Auth_Service/auth_service.dart';
import '../../Helpers/api_handler.dart';

/// Servicio para manejar el estado de conectividad de la aplicación
/// Monitorea tanto la conexión a internet como la disponibilidad del backend
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _connectivityController;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  bool _hasInternetConnection = false;
  bool _isBackendAvailable = false;
  DateTime? _lastBackendCheck;
  
  static const Duration _backendCheckInterval = Duration(seconds: 30);
  static const Duration _backendCheckTimeout = Duration(seconds: 2);

  /// Stream que emite true cuando hay conexión completa (internet + backend)
  Stream<bool> get onConnectivityChanged {
    _connectivityController ??= StreamController<bool>.broadcast();
    return _connectivityController!.stream;
  }

  /// Indica si hay conexión a internet
  bool get hasInternetConnection => _hasInternetConnection;
  
  /// Indica si el backend está disponible
  bool get isBackendAvailable => _isBackendAvailable;
  
  /// Indica si hay conexión completa (internet + backend disponible)
  bool get isFullyConnected => _hasInternetConnection && _isBackendAvailable;

  /// Inicializa el servicio de conectividad
  Future<void> initialize() async {
    
    
    // Verificar estado inicial
    await _checkConnectivity();
    
    // Escuchar cambios en la conectividad
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) async {
          
        await _checkConnectivity();
      },
    );
    
    // Verificar backend periódicamente si hay internet
    Timer.periodic(_backendCheckInterval, (timer) async {
      if (_hasInternetConnection) {
        await _checkBackendAvailability();
      }
    });
    
    
  }

  /// Verifica el estado de conectividad actual
  Future<void> _checkConnectivity() async {
    try {
      final ConnectivityResult result = await _connectivity.checkConnectivity();
      
      // Verificar si hay alguna conexión activa
      _hasInternetConnection = result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet;
      
      
      
      if (_hasInternetConnection) {
        await _checkBackendAvailability();
      } else {
        _isBackendAvailable = false;
        _notifyListeners();
      }
    } catch (e) {
      
      _hasInternetConnection = false;
      _isBackendAvailable = false;
      _notifyListeners();
    }
  }

  /// Verifica si el backend está disponible
  Future<bool> _checkBackendAvailability() async {
    // Evitar verificaciones muy frecuentes
    if (_lastBackendCheck != null &&
        DateTime.now().difference(_lastBackendCheck!) < Duration(seconds: 5)) {
      return _isBackendAvailable;
    }
    
    _lastBackendCheck = DateTime.now();
    
    try {
    
      
      final headers = await AuthService.getAuthHeaders();
      final response = await Apihandler.client.get(
        Apihandler.baseUrl.resolve('/api/health'),
        headers: headers,
      ).timeout(_backendCheckTimeout);
      
      _isBackendAvailable = response.statusCode == 200;
      
    } catch (e) {
      // Ignorar errores de SSL/certificado y asumir que el backend está disponible
      // El verdadero test es si las APIs de ventas funcionan
      if (e.toString().contains('CERTIFICATE_VERIFY_FAILED') || 
          e.toString().contains('HandshakeException')) {
        
        _isBackendAvailable = true; // Asumir disponible, las APIs reales dirán si funciona
      } else {
        
        _isBackendAvailable = false;
      }
    }
    
    _notifyListeners();
    return _isBackendAvailable;
  }

  /// Verifica manualmente la conectividad completa
  Future<bool> checkFullConnectivity() async {
    await _checkConnectivity();
    return isFullyConnected;
  }

  /// Notifica a los listeners sobre cambios en la conectividad
  void _notifyListeners() {
    if (_connectivityController != null && !_connectivityController!.isClosed) {
      _connectivityController!.add(isFullyConnected);
    }
  }

  /// Libera los recursos del servicio
  void dispose() {
    
    _connectivitySubscription?.cancel();
    _connectivityController?.close();
  }
}

