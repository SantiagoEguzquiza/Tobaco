import 'dart:async';
import 'package:flutter/material.dart';
import '../../Models/User.dart';
import 'user_service.dart';
import '../Auth_Service/auth_service.dart';
import '../../Helpers/api_handler.dart';

class UserProvider extends ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Check if token is valid before operations
  Future<bool> _isTokenValid() async {
    print('UserProvider: Checking token validity...');
    // First check local validation
    if (!await AuthService.isAuthenticated()) {
      print('UserProvider: Not authenticated locally');
      return false;
    }
    
    print('UserProvider: Authenticated locally, validating with backend...');
    // Then validate with backend
    final isValid = await AuthService.validateToken();
    print('UserProvider: Token validation result: $isValid');
    return isValid;
  }

  // Handle token expiration
  Future<void> _handleTokenExpiration() async {
    print('UserProvider: Handling token expiration...');
    await AuthService.logout();
    // No establecer errorMessage aquí, dejar que la UI maneje el error
    print('UserProvider: Token expiration handled');
  }

  // Get all users
  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if token is valid before making the request
      if (!await _isTokenValid()) {
        await _handleTokenExpiration();
        // Esperar 10 segundos antes de lanzar el error, igual que las demás pantallas
        await Future.delayed(Duration(seconds: 10));
        // Limpiar la lista de usuarios para errores de conexión
        _users = [];
        _isLoading = false;
        notifyListeners();
        // Lanzar un error de conexión para que se detecte como servidor no disponible
        throw TimeoutException('Servidor no disponible', Duration(seconds: 10));
      }

      _users = await UserService.getAllUsers();
      print('UserProvider: Loaded ${_users.length} users from backend'); // Debug log
      for (var user in _users) {
        print('UserProvider: User ${user.userName}, Active: ${user.isActive}'); // Debug log
      }
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      print('UserProvider: loadUsers completado exitosamente');
    } catch (e) {
      print('UserProvider: Error en loadUsers: $e');
      print('UserProvider: Error tipo: ${e.runtimeType}');
      
      _isLoading = false;
      
      // Si es un error de conexión, limpiar la lista de usuarios
      if (Apihandler.isConnectionError(e)) {
        _users = [];
        _errorMessage = null;
      } else {
        // Solo establecer errorMessage para errores que NO son de conexión
        _errorMessage = e.toString();
      }
      
      notifyListeners();
      
      // Relanzar TODAS las excepciones para que la UI las maneje
      rethrow;
    }
  }

  // Create a new user
  Future<bool> createUser({
    required String userName,
    required String password,
    required String role,
    String? email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if token is valid before making the request
      if (!await _isTokenValid()) {
        await _handleTokenExpiration();
        return false;
      }

      final newUser = await UserService.createUser(
        userName: userName,
        password: password,
        role: role,
        email: email,
      );
      _users.add(newUser);
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Check if the error is related to token expiration
      if (e.toString().contains('Token inválido') || 
          e.toString().contains('Unauthorized') ||
          e.toString().contains('401')) {
        await _handleTokenExpiration();
        return false;
      } else {
        _errorMessage = e.toString();
        print('UserProvider createUser error message: $_errorMessage'); // Debug log
        _isLoading = false;
        notifyListeners();
        // No relanzar la excepción, dejar que la UI maneje el mensaje de error
        return false;
      }
    }
  }

  // Update a user
  Future<Map<String, dynamic>> updateUser({
    required int userId,
    String? userName,
    String? password,
    String? role,
    String? email,
    bool? isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if token is valid before making the request
      if (!await _isTokenValid()) {
        await _handleTokenExpiration();
        return {'success': false, 'currentUserAffected': false};
      }

      final result = await UserService.updateUser(
        userId: userId,
        userName: userName,
        password: password,
        role: role,
        email: email,
        isActive: isActive,
      );
      
      // Update the user in the local list instead of reloading all users
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _users[index] = result['user'];
      }
      
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return {'success': true, 'currentUserAffected': result['currentUserAffected'], 'message': result['message']};
    } catch (e) {
      // Check if the error is related to token expiration
      if (e.toString().contains('Token inválido') || 
          e.toString().contains('Unauthorized') ||
          e.toString().contains('401')) {
        await _handleTokenExpiration();
        return {'success': false, 'currentUserAffected': false};
      } else {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
        // No relanzar la excepción, dejar que la UI maneje el mensaje de error
        return {'success': false, 'currentUserAffected': false, 'message': e.toString()};
      }
    }
  }

  // Delete a user
  Future<Map<String, dynamic>> deleteUser(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Add timeout to prevent infinite loading
      final result = await Future.any([
        _performDelete(userId),
        Future.delayed(const Duration(seconds: 30), () => throw TimeoutException('Operation timed out', const Duration(seconds: 30))),
      ]);
      
      return result;
    } catch (e) {
      _isLoading = false;
      if (e is TimeoutException) {
        _errorMessage = 'La operación tardó demasiado. Por favor, intenta nuevamente.';
      } else {
        _errorMessage = e.toString();
      }
      notifyListeners();
      return {'success': false, 'currentUserAffected': false, 'error': e.toString()};
    }
  }

  // Perform the actual delete operation
  Future<Map<String, dynamic>> _performDelete(int userId) async {
    // Check if token is valid before making the request
    if (!await _isTokenValid()) {
      await _handleTokenExpiration();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'currentUserAffected': false};
    }

    final result = await UserService.deleteUser(userId);
    _users.removeWhere((user) => user.id == userId);
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
    return {'success': true, 'currentUserAffected': result['currentUserAffected'], 'message': result['message']};
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear loading state (emergency method)
  void clearLoading() {
    _isLoading = false;
    notifyListeners();
  }

  // Get users by role
  List<User> getUsersByRole(String role) {
    return _users.where((user) => user.role == role).toList();
  }

  // Get active users
  List<User> getActiveUsers() {
    return _users.where((user) => user.isActive).toList();
  }

  // Get inactive users
  List<User> getInactiveUsers() {
    return _users.where((user) => !user.isActive).toList();
  }
}
