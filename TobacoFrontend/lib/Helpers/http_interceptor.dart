import 'dart:async';
import 'package:http/http.dart' as http;
import '../Services/Auth_Service/auth_service.dart';
import 'api_handler.dart';

class HttpInterceptor {
  // Completer actúa como mutex: no-null significa que ya hay un refresh en curso.
  // Completa con el nuevo token (o null si falló) para desbloquear requests en espera.
  static Completer<String?>? _refreshCompleter;

  static Future<http.Response> interceptRequest(
    Future<http.Response> Function() request,
  ) async {
    final token = await AuthService.getToken();
    if (token != null) {
      await AuthService.validateAndRefreshToken();
    }

    try {
      final response = await request();
      if (response.statusCode == 401 || response.statusCode == 403) {
        return await _handleUnauthorized(request);
      }
      return response;
    } catch (e) {
      if (Apihandler.isConnectionError(e)) rethrow;
      final s = e.toString().toLowerCase();
      if (s.contains('401') || s.contains('403') ||
          s.contains('unauthorized') || s.contains('forbidden')) {
        return await _handleUnauthorized(request);
      }
      rethrow;
    }
  }

  /// Maneja 401/403: refresca el token una sola vez y reintenta.
  /// Requests concurrentes esperan al mismo refresh en lugar de iniciar el suyo.
  static Future<http.Response> _handleUnauthorized(
    Future<http.Response> Function() request,
  ) async {
    // Refresh ya en curso: esperar resultado y reintentar
    if (_refreshCompleter != null) {
      final newToken = await _refreshCompleter!.future;
      if (newToken != null) return await request();
      throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
    }

    // Somos el primero en detectar el 401 — iniciar refresh
    final completer = Completer<String?>();
    _refreshCompleter = completer;
    try {
      final newToken = await AuthService.refreshToken();
      completer.complete(newToken);
      if (newToken != null) return await request();
      await AuthService.logout();
      throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
    } catch (e) {
      if (!completer.isCompleted) completer.complete(null);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    return interceptRequest(() async {
      final authHeaders = await AuthService.getAuthHeaders();
      return await Apihandler.client.get(url, headers: {...?headers, ...authHeaders});
    });
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return interceptRequest(() async {
      final authHeaders = await AuthService.getAuthHeaders();
      return await Apihandler.client.post(url, headers: {...?headers, ...authHeaders}, body: body);
    });
  }

  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return interceptRequest(() async {
      final authHeaders = await AuthService.getAuthHeaders();
      return await Apihandler.client.put(url, headers: {...?headers, ...authHeaders}, body: body);
    });
  }

  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    return interceptRequest(() async {
      final authHeaders = await AuthService.getAuthHeaders();
      return await Apihandler.client.delete(url, headers: {...?headers, ...authHeaders});
    });
  }
}
