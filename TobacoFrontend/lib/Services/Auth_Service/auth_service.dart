import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Helpers/api_handler.dart';
import '../../Models/LoginRequest.dart';
import '../../Models/LoginResponse.dart';
import '../../Models/User.dart';

class AuthService {
  static const String _loginEndpoint = '/api/User/login';
  static const String _tokenKey = 'auth_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userKey = 'user_data';
  static const Duration _timeoutDuration = Duration(seconds: 10);

  // Login user
  static Future<LoginResponse?> login(LoginRequest loginRequest) async {
    try {
      final response = await Apihandler.client.post(
        Apihandler.baseUrl.resolve(_loginEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(loginRequest.toJson()),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
        
        // Save token and user data to SharedPreferences
        await _saveAuthData(loginResponse);
        
        return loginResponse;
      } else if (response.statusCode == 401) {
        // Unauthorized - invalid credentials
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Usuario o contraseña incorrectos');
      } else if (response.statusCode == 400) {
        // Bad request - validation errors
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Datos de login inválidos');
      } else {
        throw Exception('Error del servidor. Intenta nuevamente más tarde.');
      }
    } catch (e) {
      // Clean up the error message to remove "Exception" prefix
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      throw Exception(errorMessage);
    }
  }

  // Save authentication data to SharedPreferences
  static Future<void> _saveAuthData(LoginResponse loginResponse) async {
    final prefs = await SharedPreferences.getInstance();
    
    debugPrint('AuthService._saveAuthData: Guardando token (${loginResponse.token.length} chars)');
    debugPrint('AuthService._saveAuthData: Token expira en: ${loginResponse.expiresAt}');
    
    await prefs.setString(_tokenKey, loginResponse.token);
    await prefs.setString(_tokenExpiryKey, loginResponse.expiresAt.toIso8601String());
    await prefs.setString(_userKey, jsonEncode(loginResponse.user.toJson()));
    
    // Verificar que se guardó correctamente
    final savedToken = prefs.getString(_tokenKey);
    debugPrint('AuthService._saveAuthData: Token guardado correctamente: ${savedToken != null}');
  }

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    debugPrint('AuthService.getToken: Token ${token != null ? "encontrado (${token.length} chars)" : "NO ENCONTRADO"}');
    return token;
  }

  // Get stored user data
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  // Check if user is authenticated and token is valid
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final tokenExpiryStr = prefs.getString(_tokenExpiryKey);

    if (token == null || tokenExpiryStr == null) {
      return false;
    }

    try {
      final tokenExpiry = DateTime.parse(tokenExpiryStr);
      return DateTime.now().isBefore(tokenExpiry);
    } catch (e) {
      return false;
    }
  }

  // Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenExpiryKey);
    await prefs.remove(_userKey);
  }

  // Validate token with backend
  static Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await Apihandler.client.post(
        Apihandler.baseUrl.resolve('/api/User/validate-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'token': token}),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isValid'] == true;
      }
      return false;
    } catch (e) {
      // Si hay un error de conexión, relanzar la excepción para que se maneje como servidor no disponible
      if (Apihandler.isConnectionError(e)) {
        rethrow;
      }
      return false;
    }
  }

  // Refresh token by re-login (since there's no refresh endpoint)
  static Future<bool> refreshToken() async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return false;

      // For now, we'll just validate the existing token
      // In a real app, you'd have a refresh token endpoint
      return await validateToken();
    } catch (e) {
      return false;
    }
  }

  // Get headers with authorization token
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    
    if (token == null) {
      debugPrint('AuthService.getAuthHeaders: ERROR - Token es NULL');
      throw Exception('No hay token de autenticación. Por favor, inicia sesión nuevamente.');
    }
    
    debugPrint('AuthService.getAuthHeaders: Token presente, agregando a headers');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
