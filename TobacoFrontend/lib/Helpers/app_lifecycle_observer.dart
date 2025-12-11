import 'package:flutter/material.dart';
import '../Services/Auth_Service/auth_service.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // La app volvió del background
      debugPrint('AppLifecycleObserver: App resumed, validando y refrescando token');
      _validateAndRefreshToken();
    }
  }

  Future<void> _validateAndRefreshToken() async {
    try {
      // Verificar si el token está expirado o por expirar
      final isExpired = await AuthService.isTokenExpired();
      
      if (isExpired) {
        debugPrint('AppLifecycleObserver: Token expirado, refrescando...');
        final newToken = await AuthService.refreshToken();
        
        if (newToken == null) {
          debugPrint('AppLifecycleObserver: No se pudo refrescar el token');
          // El logout se maneja dentro de refreshToken si falla
        } else {
          debugPrint('AppLifecycleObserver: Token refrescado exitosamente');
        }
      } else {
        // Verificar si el token está por expirar (menos de 5 minutos)
        final token = await AuthService.getToken();
        if (token != null) {
          final jwtExpiry = AuthService.getTokenExpirationFromJWT(token);
          if (jwtExpiry != null) {
            final timeUntilExpiry = jwtExpiry.difference(DateTime.now());
            if (timeUntilExpiry.inMinutes < 5) {
              debugPrint('AppLifecycleObserver: Token por expirar, refrescando preventivamente...');
              await AuthService.refreshToken();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('AppLifecycleObserver: Error al validar token: $e');
      // No hacer nada si hay error de conexión, la app seguirá funcionando
    }
  }
}
