import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Services/Auth_Service/auth_service.dart';
import 'api_handler.dart';

class HttpInterceptor {
  static bool _isRefreshing = false;
  static final List<Completer<http.Response>> _pendingRequests = [];

  /// Intercepta una petición HTTP y maneja automáticamente el refresh de token
  static Future<http.Response> interceptRequest(
    Future<http.Response> Function() request,
  ) async {
    // Validar y refrescar token si es necesario antes de la petición
    // Solo si hay token disponible
    final token = await AuthService.getToken();
    if (token != null) {
      debugPrint('HttpInterceptor: Validando token antes de la petición...');
      final isValid = await AuthService.validateAndRefreshToken();
      debugPrint('HttpInterceptor: Token válido: $isValid');
    } else {
      debugPrint('HttpInterceptor: No hay token disponible');
    }

    try {
      debugPrint('HttpInterceptor: Ejecutando petición...');
      final response = await request();
      debugPrint('HttpInterceptor: Respuesta recibida con statusCode: ${response.statusCode}');

      // Si recibimos un 401 o 403, intentar refrescar el token y reintentar
      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('HttpInterceptor: Recibido ${response.statusCode}, intentando refrescar token');
        
        // Si ya estamos refrescando, esperar a que termine
        if (_isRefreshing) {
          return await _waitForRefreshAndRetry(request);
        }

        // Intentar refrescar el token
        _isRefreshing = true;
        try {
          final newToken = await AuthService.refreshToken();
          
          if (newToken != null) {
            debugPrint('HttpInterceptor: Token refrescado exitosamente, reintentando petición');
            // Reintentar la petición original con el nuevo token
            final retryResponse = await request();
            
            // Resolver todas las peticiones pendientes
            _resolvePendingRequests(retryResponse);
            
            return retryResponse;
          } else {
            debugPrint('HttpInterceptor: No se pudo refrescar el token, haciendo logout');
            // No se pudo refrescar, hacer logout
            await AuthService.logout();
            throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
          }
        } finally {
          _isRefreshing = false;
          _pendingRequests.clear();
        }
      }

      return response;
    } catch (e) {
      // Si hay un error de conexión, no intentar refresh
      if (Apihandler.isConnectionError(e)) {
        rethrow;
      }
      
      // Si es un error 401 o 403 (en el mensaje o en la excepción), intentar refresh
      final errorString = e.toString().toLowerCase();
      debugPrint('HttpInterceptor: Excepción capturada: $errorString');
      
      if (errorString.contains('401') || errorString.contains('403') || 
          errorString.contains('unauthorized') || errorString.contains('forbidden') ||
          errorString.contains('código de estado: 401') || errorString.contains('código de estado: 403')) {
        if (!_isRefreshing) {
          debugPrint('HttpInterceptor: Error 401/403 detectado en excepción, intentando refrescar token');
          _isRefreshing = true;
          try {
            final newToken = await AuthService.refreshToken();
            if (newToken != null) {
              debugPrint('HttpInterceptor: Token refrescado exitosamente, reintentando petición');
              // Reintentar la petición con el nuevo token
              final retryResponse = await request();
              debugPrint('HttpInterceptor: Petición reintentada exitosamente con statusCode: ${retryResponse.statusCode}');
              return retryResponse;
            } else {
              debugPrint('HttpInterceptor: No se pudo refrescar el token, haciendo logout');
              await AuthService.logout();
              throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
            }
          } finally {
            _isRefreshing = false;
          }
        } else {
          debugPrint('HttpInterceptor: Ya se está refrescando el token, esperando...');
          return await _waitForRefreshAndRetry(request);
        }
      }
      
      rethrow;
    }
  }

  /// Espera a que termine el refresh y reintenta la petición
  static Future<http.Response> _waitForRefreshAndRetry(
    Future<http.Response> Function() request,
  ) async {
    final completer = Completer<http.Response>();
    _pendingRequests.add(completer);
    
    // Esperar hasta 10 segundos
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Timeout esperando refresh de token');
      },
    );
  }

  /// Resuelve todas las peticiones pendientes con la misma respuesta
  static void _resolvePendingRequests(http.Response response) {
    for (var completer in _pendingRequests) {
      if (!completer.isCompleted) {
        completer.complete(response);
      }
    }
    _pendingRequests.clear();
  }

  /// Wrapper para peticiones GET
  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    return interceptRequest(() async {
      try {
        final authHeaders = await AuthService.getAuthHeaders();
        final finalHeaders = {...?headers, ...authHeaders};
        return await Apihandler.client.get(url, headers: finalHeaders);
      } catch (e) {
        // Si no hay token, hacer la petición sin headers de auth
        // Esto es útil para endpoints públicos
        return await Apihandler.client.get(url, headers: headers);
      }
    });
  }

  /// Wrapper para peticiones POST
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return interceptRequest(() async {
      try {
        final authHeaders = await AuthService.getAuthHeaders();
        final finalHeaders = {...?headers, ...authHeaders};
        return await Apihandler.client.post(url, headers: finalHeaders, body: body);
      } catch (e) {
        // Si no hay token, hacer la petición sin headers de auth
        // Esto es útil para endpoints públicos como login
        return await Apihandler.client.post(url, headers: headers, body: body);
      }
    });
  }

  /// Wrapper para peticiones PUT
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return interceptRequest(() async {
      try {
        final authHeaders = await AuthService.getAuthHeaders();
        final finalHeaders = {...?headers, ...authHeaders};
        return await Apihandler.client.put(url, headers: finalHeaders, body: body);
      } catch (e) {
        return await Apihandler.client.put(url, headers: headers, body: body);
      }
    });
  }

  /// Wrapper para peticiones DELETE
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    return interceptRequest(() async {
      try {
        final authHeaders = await AuthService.getAuthHeaders();
        final finalHeaders = {...?headers, ...authHeaders};
        return await Apihandler.client.delete(url, headers: finalHeaders);
      } catch (e) {
        return await Apihandler.client.delete(url, headers: headers);
      }
    });
  }
}
