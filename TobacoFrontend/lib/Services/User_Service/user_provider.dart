import 'dart:async';
import 'package:flutter/material.dart';
import '../../Models/User.dart';
import 'user_service.dart';
import '../Auth_Service/auth_service.dart';

class UserProvider extends ChangeNotifier {
  List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Check if token is valid before operations
  Future<bool> _isTokenValid() async {
    // First check local validation
    if (!await AuthService.isAuthenticated()) {
      return false;
    }
    
    // Then validate with backend
    return await AuthService.validateToken();
  }

  // Handle token expiration
  Future<void> _handleTokenExpiration() async {
    await AuthService.logout();
    _errorMessage = 'Sesión expirada. Por favor, inicia sesión nuevamente.';
    notifyListeners();
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
        return;
      }

      _users = await UserService.getAllUsers();
      print('Loaded ${_users.length} users from backend'); // Debug log
      for (var user in _users) {
        print('User: ${user.userName}, Active: ${user.isActive}'); // Debug log
      }
      _errorMessage = null;
    } catch (e) {
      // Check if the error is related to token expiration
      if (e.toString().contains('Token inválido') || 
          e.toString().contains('Unauthorized') ||
          e.toString().contains('401')) {
        await _handleTokenExpiration();
      } else {
        _errorMessage = e.toString();
      }
    }

    _isLoading = false;
    notifyListeners();
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
        return {'success': false, 'currentUserAffected': false, 'error': e.toString()};
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
