import 'dart:async';
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
  static const Duration _refreshTimeoutDuration = Duration(seconds: 30);
  /// Solo refrescar cuando al token le queden menos de estos segundos (evita refrescos innecesarios y timeouts).
  static const int _refreshWhenSecondsLeft = 30;
  
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

  /// Si ya hay un refresh en curso, otros llamadores esperan al mismo resultado (evita race al volver de segundo plano).
  static Completer<String?>? _refreshCompleter;

  // Refresh access token using refresh token (serializado: solo uno a la vez)
  static Future<String?> refreshToken() async {
    if (_refreshCompleter != null) {
      debugPrint('AuthService.refreshToken: Refresh ya en curso, esperando resultado...');
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final refreshTokenValue = await getRefreshToken();
      if (refreshTokenValue == null) {
        debugPrint('AuthService.refreshToken: No hay refresh token disponible');
        _refreshCompleter!.complete(null);
        return null;
      }

      final response = await Apihandler.client.post(
        Apihandler.baseUrl.resolve(_refreshEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'refreshToken': refreshTokenValue}),
      ).timeout(_refreshTimeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'] as String;
        final expiresIn = data['expiresIn'] as int;
        final newRefreshToken = data['refreshToken'] as String?;

        await _secureStorage.write(key: _tokenKey, value: newAccessToken);
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await _secureStorage.write(key: _refreshTokenKey, value: newRefreshToken);
          debugPrint('AuthService.refreshToken: Refresh token rotado');
        }
        final newExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenExpiryKey, newExpiry.toIso8601String());

        debugPrint('AuthService.refreshToken: Token renovado exitosamente');
        _refreshCompleter!.complete(newAccessToken);
        return newAccessToken;
      } else if (response.statusCode == 401 || response.statusCode == 400) {
        final responseBody = response.body;
        debugPrint('AuthService.refreshToken: Refresh token inválido (${response.statusCode}), haciendo logout');
        debugPrint('AuthService.refreshToken: Respuesta del servidor: $responseBody');
        await logout();
        _refreshCompleter!.complete(null);
        return null;
      } else {
        debugPrint('AuthService.refreshToken: Error del servidor: ${response.statusCode}');
        debugPrint('AuthService.refreshToken: Respuesta: ${response.body}');
        _refreshCompleter!.complete(null);
        return null;
      }
    } catch (e) {
      debugPrint('AuthService.refreshToken: Error: $e');
      // Timeout/red: no hacer logout; el llamador puede seguir usando el token actual si aún es válido
      if (Apihandler.isConnectionError(e) || e is TimeoutException) {
        _refreshCompleter!.complete(null);
        return null;
      }
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  // Validate and refresh token if needed
  static Future<bool> validateAndRefreshToken() async {
    try {
      final token = await getToken();
      if (token == null) {
        // No hay token, esto es normal si el usuario no está autenticado
        debugPrint('AuthService.validateAndRefreshToken: No hay token disponible');
        return false;
      }

      // Verificar expiración desde el JWT primero (más confiable)
      final jwtExpiry = getTokenExpirationFromJWT(token);
      if (jwtExpiry != null) {
        final now = DateTime.now();
        final timeUntilExpiry = jwtExpiry.difference(now);
        
        debugPrint('AuthService.validateAndRefreshToken: Token expira en ${timeUntilExpiry.inSeconds} segundos');
        
        // Solo refrescar cuando falten _refreshWhenSecondsLeft segundos o menos (evita refrescos con red lenta)
        if (timeUntilExpiry.inSeconds < _refreshWhenSecondsLeft) {
          debugPrint('AuthService.validateAndRefreshToken: Token expirado o por expirar, refrescando');
          final newToken = await refreshToken();
          if (newToken != null) {
            debugPrint('AuthService.validateAndRefreshToken: Token refrescado exitosamente');
            return true;
          }
          // Refresh falló (timeout/red): si aún tenemos token, usarlo para esta petición
          if (await getToken() != null) {
            debugPrint('AuthService.validateAndRefreshToken: Refresh falló pero token actual aún disponible, usándolo');
            return true;
          }
          debugPrint('AuthService.validateAndRefreshToken: No se pudo refrescar el token');
          return false;
        }
        
        debugPrint('AuthService.validateAndRefreshToken: Token aún válido');
        return true;
      }

      // Si no se puede leer del JWT, usar SharedPreferences como respaldo
      final prefs = await SharedPreferences.getInstance();
      final tokenExpiryStr = prefs.getString(_tokenExpiryKey);
      
      if (tokenExpiryStr != null) {
        try {
          final tokenExpiry = DateTime.parse(tokenExpiryStr);
          final now = DateTime.now();
          final timeUntilExpiry = tokenExpiry.difference(now);
          
          debugPrint('AuthService.validateAndRefreshToken: Token expira en ${timeUntilExpiry.inSeconds} segundos (desde SharedPreferences)');
          
          if (now.isAfter(tokenExpiry)) {
            debugPrint('AuthService.validateAndRefreshToken: Token expirado, intentando refrescar');
            final newToken = await refreshToken();
            if (newToken != null) return true;
            if (await getToken() != null) return true;
            return false;
          }
          
          if (timeUntilExpiry.inSeconds < _refreshWhenSecondsLeft) {
            debugPrint('AuthService.validateAndRefreshToken: Token por expirar, refrescando preventivamente');
            final newToken = await refreshToken();
            if (newToken != null) return true;
            if (await getToken() != null) return true;
            return false;
          }
          
          return true;
        } catch (e) {
          debugPrint('AuthService.validateAndRefreshToken: Error al parsear expiración: $e');
        }
      }

      // Si no hay información de expiración, asumir que es válido
      debugPrint('AuthService.validateAndRefreshToken: No se pudo determinar expiración, asumiendo válido');
      return true;
    } catch (e) {
      debugPrint('AuthService.validateAndRefreshToken: Error: $e');
      // No relanzar la excepción para evitar bucles
      return false;
    }
  }

  /// Callback invoked whenever the session is invalidated (tokens cleared).
  /// Used so the UI (AuthProvider) can sync state and show login again when
  /// refresh fails on app resume or after 401/403.
  static void Function()? onSessionInvalidated;

  /// Detecta si la excepción es "sesión expirada". Usar en catch: si true, llamar logout() y no mostrar error en pantalla.
  static bool isSessionExpiredException(dynamic e) {
    final s = e.toString().toLowerCase();
    return s.contains('sesión') && (s.contains('expirad') || s.contains('inicia sesión'));
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
      // Notificar a la UI para que actualice (ej. volver a pantalla de login)
      onSessionInvalidated?.call();
    } catch (e) {
      debugPrint('AuthService.logout: Error al hacer logout: $e');
      onSessionInvalidated?.call();
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

  // Get headers with authorization token (validando/refrescando antes)
  static Future<Map<String, String>> getAuthHeaders() async {
    final hadToken = await getToken() != null;

    final isValid = await validateAndRefreshToken();
    if (!isValid) {
      debugPrint(
          'AuthService.getAuthHeaders: Token inválido o expirado. Se requiere login nuevamente.');
      // Solo hacer logout si había sesión (evita mensaje "sesión expirada" al escribir usuario sin haber entrado)
      if (hadToken) await logout();
      throw Exception(
          'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.');
    }

    final token = await getToken();
    if (token == null) {
      debugPrint('AuthService.getAuthHeaders: No hay token disponible');
      if (hadToken) await logout();
      throw Exception(
          'No hay token de autenticación. Por favor, inicia sesión nuevamente.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
