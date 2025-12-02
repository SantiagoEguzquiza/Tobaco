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

  Future<void> loadPermisos(AuthProvider authProvider, {bool forceReload = false}) async {
    debugPrint('PermisosProvider.loadPermisos: Iniciando carga. forceReload: $forceReload');
    
    if (authProvider.currentUser == null) {
      debugPrint('PermisosProvider.loadPermisos: Usuario es null, retornando');
      _permisos = null;
      _isAdmin = false;
      _currentUserId = null;
      _hasAttemptedLoad = true;
      notifyListeners();
      return;
    }

    final newUserId = authProvider.currentUser!.id;
    debugPrint('PermisosProvider.loadPermisos: UserId actual: $_currentUserId, nuevo: $newUserId');
    
    // Detectar si el usuario cambió
    final userChanged = _currentUserId != null && _currentUserId != newUserId;
    debugPrint('PermisosProvider.loadPermisos: Usuario cambió: $userChanged');
    
    // Si el usuario cambió o se fuerza recarga, resetear el estado primero
    if (forceReload || userChanged) {
      debugPrint('PermisosProvider.loadPermisos: Reseteando estado (forceReload: $forceReload, userChanged: $userChanged)');
      _permisos = null;
      _isAdmin = false;
      _hasAttemptedLoad = false;
      _isLoading = false; // Asegurar que no esté en estado de carga
    }

    // Verificar si ya está cargando (evitar cargas múltiples simultáneas)
    if (_isLoading) {
      debugPrint('PermisosProvider.loadPermisos: Ya está cargando, retornando');
      return;
    }

    // Si ya se intentó cargar y no se fuerza recarga ni cambió el usuario, no cargar de nuevo
    if (_hasAttemptedLoad && !forceReload && !userChanged) {
      debugPrint('PermisosProvider.loadPermisos: Ya se intentó cargar y no hay cambios, retornando');
      return;
    }

    _isAdmin = authProvider.currentUser!.role == 'Admin';
    _currentUserId = newUserId;
    debugPrint('PermisosProvider.loadPermisos: Es admin: $_isAdmin');

    // Si es admin, no necesita cargar permisos (tiene todos)
    if (_isAdmin) {
      debugPrint('PermisosProvider.loadPermisos: Usuario es admin, no carga permisos');
      _permisos = null; // Admins no tienen restricciones
      _isLoading = false;
      _hasAttemptedLoad = true;
      notifyListeners();
      return;
    }

    debugPrint('PermisosProvider.loadPermisos: Llamando al endpoint mis-permisos');
    _isLoading = true;
    _errorMessage = null;
    _hasAttemptedLoad = true; // Marcar como intentado antes de la llamada
    notifyListeners();

    try {
      final permisos = await PermisosService.getMisPermisos();
      debugPrint('PermisosProvider.loadPermisos: Permisos recibidos correctamente');
      debugPrint('PermisosProvider.loadPermisos: productosVisualizar = ${permisos.productosVisualizar}');
      debugPrint('PermisosProvider.loadPermisos: canViewProductos = ${permisos.productosVisualizar || _isAdmin}');
      _permisos = permisos;
      _isLoading = false;
      notifyListeners();
      debugPrint('PermisosProvider.loadPermisos: Permisos cargados y notificados. canViewProductos getter = $canViewProductos');
    } catch (e) {
      debugPrint('PermisosProvider.loadPermisos: Error al cargar permisos: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      // No resetear _hasAttemptedLoad en caso de error para evitar bucles
      // Si es un error de rate limiting, crear permisos por defecto (todos false)
      if (_errorMessage != null && 
          (_errorMessage!.contains('quota exceeded') || _errorMessage!.contains('Demasiadas solicitudes'))) {
        debugPrint('PermisosService: Rate limit alcanzado, usando permisos por defecto');
        // Crear permisos por defecto (todos desactivados) para evitar que la app se rompa
        _permisos = PermisosEmpleado(
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
        );
        _errorMessage = null; // Limpiar el error ya que tenemos permisos por defecto
      }
      notifyListeners();
    }
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

