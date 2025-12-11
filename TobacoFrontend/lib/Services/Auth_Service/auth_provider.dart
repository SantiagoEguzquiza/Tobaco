import 'package:flutter/material.dart';
import '../../Models/User.dart';
import '../../Models/LoginRequest.dart';
import '../../Helpers/api_handler.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  // Initialize authentication state
  Future<void> initializeAuth() async {
    // Evitar múltiples inicializaciones simultáneas
    if (_isLoading) return;
    
    _isLoading = true;
    // No notificar inmediatamente - esperar hasta que termine la operación

    try {
      final isAuth = await AuthService.isAuthenticated();
      if (isAuth) {
        _currentUser = await AuthService.getCurrentUser();
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
        _currentUser = null;
      }
    } catch (e) {
      _isAuthenticated = false;
      _currentUser = null;
      
      // Solo establecer errorMessage para errores que NO son de conexión
      if (!Apihandler.isConnectionError(e)) {
        _errorMessage = 'Error initializing authentication: $e';
      }
      
      // No relanzar la excepción para evitar bucles - solo loguear
      debugPrint('AuthProvider.initializeAuth: Error: $e');
    } finally {
      _isLoading = false;
      // Usar Future.microtask para asegurar que notifyListeners se llame después del build actual
      Future.microtask(() {
        notifyListeners();
      });
    }
  }

  // Login user
  Future<bool> login(String userName, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loginRequest = LoginRequest(
        userName: userName,
        password: password,
      );

      final loginResponse = await AuthService.login(loginRequest);
      
      if (loginResponse != null) {
        _currentUser = loginResponse.user;
        _isAuthenticated = true;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'No se pudo iniciar sesión. Verifica tus datos e intenta nuevamente.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _isAuthenticated = false;
      _currentUser = null;
      
      // Solo establecer errorMessage para errores que NO son de conexión
      if (!Apihandler.isConnectionError(e)) {
        // Extract the actual error message from the exception
        String errorMsg = e.toString();
        if (errorMsg.contains('Exception: ')) {
          errorMsg = errorMsg.replaceFirst('Exception: ', '');
        }
        if (errorMsg.contains('Login error: ')) {
          errorMsg = errorMsg.replaceFirst('Login error: ', '');
        }
        
        _errorMessage = errorMsg.isNotEmpty ? errorMsg : 'Error al iniciar sesión. Intenta nuevamente.';
      }
      
      notifyListeners();
      
      // Relanzar la excepción para que la UI la maneje
      rethrow;
    }
  }

  // Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.logout();
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Logout error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Update current user data
  void updateCurrentUser(User updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }
}
