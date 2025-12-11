import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Helpers/api_handler.dart';
import '../../Models/LoginRequest.dart';
import '../../Models/LoginResponse.dart';
import '../../Models/User.dart';

class AuthService {
  static const String _loginEndpoint = '/api/User/login';
  static const String _refreshEndpoint = '/api/User/refresh';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userKey = 'user_data';
  static const Duration _timeoutDuration = Duration(seconds: 10);
  
  // Secure storage para tokens sensibles
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

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
        
        // Save token and user data to secure storage
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

  // Save authentication data to secure storage
  static Future<void> _saveAuthData(LoginResponse loginResponse) async {
    debugPrint('AuthService._saveAuthData: Guardando tokens');
    debugPrint('AuthService._saveAuthData: Token expira en: ${loginResponse.expiresAt}');
    
    // Guardar tokens en secure storage
    await _secureStorage.write(key: _tokenKey, value: loginResponse.token);
    await _secureStorage.write(key: _refreshTokenKey, value: loginResponse.refreshToken);
    
    // Guardar expiración y datos de usuario en SharedPreferences (no son sensibles)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenExpiryKey, loginResponse.expiresAt.toIso8601String());
    await prefs.setString(_userKey, jsonEncode(loginResponse.user.toJson()));
    
    debugPrint('AuthService._saveAuthData: Tokens guardados correctamente');
  }

  // Get stored access token
  static Future<String?> getToken() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      // Solo imprimir si hay token (evitar spam en login)
      if (token != null) {
        debugPrint('AuthService.getToken: Token encontrado');
      }
      return token;
    } catch (e) {
      debugPrint('AuthService.getToken: Error al leer token: $e');
      return null;
    }
  }

  // Get stored refresh token
  static Future<String?> getRefreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      return refreshToken;
    } catch (e) {
      debugPrint('AuthService.getRefreshToken: Error al leer refresh token: $e');
      return null;
    }
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
    final token = await getToken();
    final prefs = await SharedPreferences.getInstance();
    final tokenExpiryStr = prefs.getString(_tokenExpiryKey);

    if (token == null || tokenExpiryStr == null) {
      return false;
    }

    try {
      final tokenExpiry = DateTime.parse(tokenExpiryStr);
      // Verificar si el token está expirado o expira en menos de 1 minuto
      final now = DateTime.now();
      final timeUntilExpiry = tokenExpiry.difference(now);
      return timeUntilExpiry.inSeconds > 60; // Al menos 1 minuto de validez
    } catch (e) {
      return false;
    }
  }

  // Check if token is expired or about to expire
  static Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenExpiryStr = prefs.getString(_tokenExpiryKey);

    if (tokenExpiryStr == null) {
      return true;
    }

    try {
      final tokenExpiry = DateTime.parse(tokenExpiryStr);
      return DateTime.now().isAfter(tokenExpiry);
    } catch (e) {
      return true;
    }
  }

  // Get token expiration from JWT
  static DateTime? getTokenExpirationFromJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      // Agregar padding si es necesario
      String normalized = payload;
      switch (normalized.length % 4) {
        case 1:
          normalized += '===';
          break;
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
      }
      
      final decoded = utf8.decode(base64.decode(normalized));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;
      
      if (payloadMap.containsKey('exp')) {
        final exp = payloadMap['exp'] as int;
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      }
      return null;
    } catch (e) {
      debugPrint('AuthService.getTokenExpirationFromJWT: Error: $e');
      return null;
    }
  }

  // Refresh access token using refresh token
  static Future<String?> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        debugPrint('AuthService.refreshToken: No hay refresh token disponible');
        return null;
      }

      final response = await Apihandler.client.post(
        Apihandler.baseUrl.resolve(_refreshEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'] as String;
        final expiresIn = data['expiresIn'] as int;
        final newRefreshToken = data['refreshToken'] as String?;
        
        // Actualizar access token y expiración
        await _secureStorage.write(key: _tokenKey, value: newAccessToken);
        
        // Si se devolvió un nuevo refresh token, actualizarlo también
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await _secureStorage.write(key: _refreshTokenKey, value: newRefreshToken);
          debugPrint('AuthService.refreshToken: Refresh token rotado');
        }
        
        // Calcular nueva expiración
        final newExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenExpiryKey, newExpiry.toIso8601String());
        
        debugPrint('AuthService.refreshToken: Token renovado exitosamente');
        return newAccessToken;
      } else if (response.statusCode == 401) {
        // Refresh token inválido o expirado
        debugPrint('AuthService.refreshToken: Refresh token inválido, haciendo logout');
        await logout();
        return null;
      } else {
        debugPrint('AuthService.refreshToken: Error del servidor: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('AuthService.refreshToken: Error: $e');
      if (Apihandler.isConnectionError(e)) {
        rethrow;
      }
      return null;
    }
  }

  // Validate and refresh token if needed
  static Future<bool> validateAndRefreshToken() async {
    try {
      final token = await getToken();
      if (token == null) {
        // No hay token, esto es normal si el usuario no está autenticado
        return false;
      }

      // Verificar expiración del token desde SharedPreferences primero
      final prefs = await SharedPreferences.getInstance();
      final tokenExpiryStr = prefs.getString(_tokenExpiryKey);
      
      if (tokenExpiryStr != null) {
        try {
          final tokenExpiry = DateTime.parse(tokenExpiryStr);
          final now = DateTime.now();
          
          // Si el token ya expiró, intentar refrescar
          if (now.isAfter(tokenExpiry)) {
            debugPrint('AuthService.validateAndRefreshToken: Token expirado, intentando refrescar');
            final newToken = await refreshToken();
            return newToken != null;
          }
          
          // Si el token expira en menos de 1 minuto, refrescar preventivamente
          final timeUntilExpiry = tokenExpiry.difference(now);
          if (timeUntilExpiry.inSeconds < 60) {
            debugPrint('AuthService.validateAndRefreshToken: Token por expirar, refrescando preventivamente');
            final newToken = await refreshToken();
            return newToken != null;
          }
        } catch (e) {
          debugPrint('AuthService.validateAndRefreshToken: Error al parsear expiración: $e');
        }
      }

      // Verificar expiración desde el JWT mismo como respaldo
      final jwtExpiry = getTokenExpirationFromJWT(token);
      if (jwtExpiry != null) {
        final now = DateTime.now();
        if (now.isAfter(jwtExpiry.subtract(Duration(minutes: 1)))) {
          debugPrint('AuthService.validateAndRefreshToken: Token por expirar (JWT), refrescando');
          final newToken = await refreshToken();
          return newToken != null;
        }
      }

      return true;
    } catch (e) {
      debugPrint('AuthService.validateAndRefreshToken: Error: $e');
      // No relanzar la excepción para evitar bucles
      return false;
    }
  }

  // Logout user
  static Future<void> logout() async {
    try {
      // Eliminar tokens de secure storage
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      
      // Eliminar datos de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenExpiryKey);
      await prefs.remove(_userKey);
      
      debugPrint('AuthService.logout: Logout completado');
    } catch (e) {
      debugPrint('AuthService.logout: Error al hacer logout: $e');
    }
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

  // Get headers with authorization token
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    
    if (token == null) {
      // No lanzar excepción inmediatamente, permitir que el código que llama maneje el caso
      // Esto es útil cuando se está en login y aún no hay token
      debugPrint('AuthService.getAuthHeaders: No hay token disponible');
      throw Exception('No hay token de autenticación. Por favor, inicia sesión nuevamente.');
    }
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
