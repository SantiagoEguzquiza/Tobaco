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
      final hasToken = await AuthService.getToken() != null;
      if (!hasToken) return;

      // Un solo camino: validar y refrescar si hace falta. Si el refresh falla (401/400),
      // AuthService.refreshToken() hace logout y dispara onSessionInvalidated → vuelta al login.
      await AuthService.validateAndRefreshToken();
    } catch (e) {
      debugPrint('AppLifecycleObserver: Error al validar token: $e');
      // No hacer nada si hay error de conexión, la app seguirá funcionando
    }
  }
}
