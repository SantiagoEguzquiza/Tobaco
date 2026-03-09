import 'dart:async';
import 'package:flutter/material.dart';
import '../../Models/PermisosEmpleado.dart';
import 'permisos_service.dart';
import '../Auth_Service/auth_provider.dart';

class PermisosProvider with ChangeNotifier {
  PermisosEmpleado? _permisos;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAdmin = false;
  bool _hasAttemptedLoad = false; // Bandera para evitar cargas repetidas
  int? _currentUserId; // Track current user ID to detect user changes

  PermisosEmpleado? get permisos => _permisos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _isAdmin;
  bool get hasAttemptedLoad => _hasAttemptedLoad;
  int? get currentUserId => _currentUserId;

  // Logs detallados de flujo de permisos (solo útiles al depurar ese módulo)
  static const bool _logVerbosePermisos = false;

  // Getters para verificar permisos específicos
  bool get canViewProductos => _isAdmin || (_permisos?.productosVisualizar ?? false);
  bool get canCreateProductos => _isAdmin || (_permisos?.productosCrear ?? false);
  bool get canEditProductos => _isAdmin || (_permisos?.productosEditar ?? false);
  bool get canDeleteProductos => _isAdmin || (_permisos?.productosEliminar ?? false);

  bool get canViewClientes => _isAdmin || (_permisos?.clientesVisualizar ?? false);
  bool get canCreateClientes => _isAdmin || (_permisos?.clientesCrear ?? false);
  bool get canEditClientes => _isAdmin || (_permisos?.clientesEditar ?? false);
  bool get canDeleteClientes => _isAdmin || (_permisos?.clientesEliminar ?? false);

  bool get canViewVentas => _isAdmin || (_permisos?.ventasVisualizar ?? false);
  bool get canCreateVentas => _isAdmin || (_permisos?.ventasCrear ?? false);
  bool get canEditVentas => _isAdmin || (_permisos?.ventasEditarBorrador ?? false);
  bool get canDeleteVentas => _isAdmin || (_permisos?.ventasEliminar ?? false);

  bool get canViewCuentaCorriente => _isAdmin || (_permisos?.cuentaCorrienteVisualizar ?? false);
  bool get canRegistrarAbonos => _isAdmin || (_permisos?.cuentaCorrienteRegistrarAbonos ?? false);

  bool get canViewEntregas => _isAdmin || (_permisos?.entregasVisualizar ?? false);
  bool get canUpdateEstadoEntregas => _isAdmin || (_permisos?.entregasActualizarEstado ?? false);

  bool get canViewCompras => _isAdmin || (_permisos?.comprasVisualizar ?? false);
  bool get canCreateCompras => _isAdmin || (_permisos?.comprasCrear ?? false);
  bool get canEditCompras => _isAdmin || (_permisos?.comprasEditar ?? false);
  bool get canDeleteCompras => _isAdmin || (_permisos?.comprasEliminar ?? false);

  Future<void> loadPermisos(AuthProvider authProvider, {bool forceReload = false}) async {
    if (_logVerbosePermisos) {
      debugPrint('PermisosProvider.loadPermisos: Iniciando carga. forceReload: $forceReload');
    }
    
    if (authProvider.currentUser == null) {
      if (_logVerbosePermisos) {
        debugPrint('PermisosProvider.loadPermisos: Usuario es null, retornando');
      }
      _permisos = null;
      _isAdmin = false;
      _currentUserId = null;
      _hasAttemptedLoad = true;
      notifyListeners();
      return;
    }

    final newUserId = authProvider.currentUser!.id;
    if (_logVerbosePermisos) {
      debugPrint('PermisosProvider.loadPermisos: UserId actual: $_currentUserId, nuevo: $newUserId');
    }
    
    // Detectar si el usuario cambió
    final userChanged = _currentUserId != null && _currentUserId != newUserId;
    if (_logVerbosePermisos) {
      debugPrint('PermisosProvider.loadPermisos: Usuario cambió: $userChanged');
    }
    
    // Si el usuario cambió o se fuerza recarga, resetear el estado primero
    if (forceReload || userChanged) {
      if (_logVerbosePermisos) {
        debugPrint('PermisosProvider.loadPermisos: Reseteando estado (forceReload: $forceReload, userChanged: $userChanged)');
      }
      _permisos = null;
      _isAdmin = false;
      _hasAttemptedLoad = false;
      _isLoading = false; // Asegurar que no esté en estado de carga
    }

    // Verificar si ya está cargando (evitar cargas múltiples simultáneas)
    if (_isLoading) {
      if (_logVerbosePermisos) {
        debugPrint('PermisosProvider.loadPermisos: Ya está cargando, retornando');
      }
      return;
    }

    // Si ya se intentó cargar y no se fuerza recarga ni cambió el usuario, no cargar de nuevo
    if (_hasAttemptedLoad && !forceReload && !userChanged) {
      if (_logVerbosePermisos) {
        debugPrint('PermisosProvider.loadPermisos: Ya se intentó cargar y no hay cambios, retornando');
      }
      return;
    }

    _isAdmin = authProvider.currentUser!.role == 'Admin';
    _currentUserId = newUserId;
    if (_logVerbosePermisos) {
      debugPrint('PermisosProvider.loadPermisos: Es admin: $_isAdmin');
    }

    // Si es admin, no necesita cargar permisos (tiene todos)
    if (_isAdmin) {
      if (_logVerbosePermisos) {
        debugPrint('PermisosProvider.loadPermisos: Usuario es admin, no carga permisos');
      }
      _permisos = null; // Admins no tienen restricciones
      _isLoading = false;
      _hasAttemptedLoad = true;
      notifyListeners();
      return;
    }

    if (_logVerbosePermisos) {
      debugPrint('PermisosProvider.loadPermisos: Llamando al endpoint mis-permisos');
    }
    _isLoading = true;
    _errorMessage = null;
    _hasAttemptedLoad = true;
    notifyListeners();

    try {
      // Timeout 10s (incluye getToken + request) para no quedar colgado
      final permisosResult = await PermisosService.getMisPermisos()
          .timeout(const Duration(seconds: 10));
      _permisos = permisosResult;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      if (_logVerbosePermisos) {
        debugPrint('PermisosProvider.loadPermisos: Permisos cargados correctamente');
      }
    } catch (e) {
      if (_logVerbosePermisos) {
        debugPrint('PermisosProvider.loadPermisos: Error al cargar permisos: $e');
      }
      _permisos = null;
      _isLoading = false;
      if (e is TimeoutException) {
        _errorMessage = 'La carga tardó demasiado. Comprueba la conexión y toca Reintentar.';
        _hasAttemptedLoad = true;
      } else {
        final msg = e.toString().replaceAll('Exception: ', '');
        if (msg.contains('quota exceeded') || msg.contains('Demasiadas solicitudes')) {
          _permisos = _permisosPorDefecto(authProvider);
          _errorMessage = null;
        } else {
          _errorMessage = msg.isEmpty ? 'Error al cargar permisos.' : msg;
        }
      }
      notifyListeners();
    }
  }

  /// Para mostrar pantalla de error con Reintentar: permite volver a intentar la carga.
  Future<void> reintentarPermisos(AuthProvider authProvider) async {
    _errorMessage = null;
    _hasAttemptedLoad = false;
    _isLoading = false;
    notifyListeners();
    await loadPermisos(authProvider, forceReload: true);
  }

  /// Si la carga se quedó colgada (ej. 12s), marcar como error para mostrar Reintentar.
  void marcarTimeoutPermisos() {
    if (_isLoading) {
      if (_logVerbosePermisos) {
        debugPrint('PermisosProvider.marcarTimeoutPermisos: Carga colgada, mostrando Reintentar');
      }
      _isLoading = false;
      _errorMessage = 'La carga tardó demasiado. Toca Reintentar.';
      notifyListeners();
    }
  }

  /// Tras timeout, permitir entrar al menú con permisos por defecto (sin bloquear la app).
  void marcarTimeoutYPermitirEntrada(AuthProvider authProvider) {
    if (_logVerbosePermisos) {
      debugPrint('PermisosProvider.marcarTimeoutYPermitirEntrada: Timeout, entrando con permisos por defecto');
    }
    _isLoading = false;
    _hasAttemptedLoad = true;
    _errorMessage = null;
    if (_permisos == null) {
      _permisos = _permisosPorDefecto(authProvider);
    }
    notifyListeners();
  }

  static PermisosEmpleado _permisosPorDefecto(AuthProvider authProvider) {
    return PermisosEmpleado(
      id: 0,
      userId: authProvider.currentUser?.id ?? 0,
      productosVisualizar: false,
      productosCrear: false,
      productosEditar: false,
      productosEliminar: false,
      clientesVisualizar: false,
      clientesCrear: false,
      clientesEditar: false,
      clientesEliminar: false,
      ventasVisualizar: false,
      ventasCrear: false,
      ventasEditarBorrador: false,
      ventasEliminar: false,
      cuentaCorrienteVisualizar: false,
      cuentaCorrienteRegistrarAbonos: false,
      entregasVisualizar: false,
      entregasActualizarEstado: false,
      comprasVisualizar: false,
      comprasCrear: false,
      comprasEditar: false,
      comprasEliminar: false,
    );
  }

  void clearPermisos() {
    _permisos = null;
    _isAdmin = false;
    _isLoading = false;
    _errorMessage = null;
    _hasAttemptedLoad = false; // Resetear para permitir nueva carga
    _currentUserId = null; // Limpiar userId al limpiar permisos
    notifyListeners();
  }
}

