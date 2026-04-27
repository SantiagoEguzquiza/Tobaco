import 'package:flutter/material.dart';
import 'package:tobaco/Models/Tenant.dart';
import 'package:tobaco/Services/Tenant_Service/tenant_service.dart';

class TenantProvider extends ChangeNotifier {
  final TenantService _tenantService = TenantService();
  
  List<Tenant> _tenants = [];
  Tenant? _miTenant;
  bool _isLoading = false;
  bool _isUpdatingStockControl = false;
  String? _errorMessage;

  List<Tenant> get tenants => _tenants;
  Tenant? get miTenant => _miTenant;
  bool get isLoading => _isLoading;
  bool get isUpdatingStockControl => _isUpdatingStockControl;
  String? get errorMessage => _errorMessage;

  Future<void> cargarTenants() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tenants = await _tenantService.obtenerTenants();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _tenants = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Tenant> crearTenant(Tenant tenant) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nuevoTenant = await _tenantService.crearTenant(tenant);
      _tenants.add(nuevoTenant);
      _errorMessage = null;
      return nuevoTenant;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Tenant> actualizarTenant(int id, Tenant tenant) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tenantActualizado = await _tenantService.actualizarTenant(id, tenant);
      final index = _tenants.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tenants[index] = tenantActualizado;
      }
      _errorMessage = null;
      return tenantActualizado;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> eliminarTenant(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _tenantService.eliminarTenant(id);
      _tenants.removeWhere((t) => t.id == id);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga el tenant del usuario autenticado (admin u otro rol con acceso).
  Future<Tenant?> cargarMiTenant() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _miTenant = await _tenantService.obtenerMiTenant();
      _errorMessage = null;
      return _miTenant;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _miTenant = null;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza únicamente el flag de control de stock global del tenant del usuario.
  /// Hace optimistic update en memoria para que la UI responda inmediatamente.
  Future<bool> actualizarControlDeStockGlobal(bool nuevoValor) async {
    final actual = _miTenant;
    if (actual == null) {
      _errorMessage = 'No se pudo identificar el tenant del usuario.';
      notifyListeners();
      return false;
    }

    if (actual.stockControlEnabledByDefault == nuevoValor) {
      return true;
    }

    final previo = actual;
    _miTenant = actual.copyWith(stockControlEnabledByDefault: nuevoValor);
    _isUpdatingStockControl = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final actualizado = await _tenantService.actualizarControlDeStockGlobal(
        previo,
        nuevoValor,
      );
      _miTenant = actualizado;
      final idx = _tenants.indexWhere((t) => t.id == actualizado.id);
      if (idx != -1) {
        _tenants[idx] = actualizado;
      }
      return true;
    } catch (e) {
      _miTenant = previo;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isUpdatingStockControl = false;
      notifyListeners();
    }
  }

  void limpiarError() {
    _errorMessage = null;
    notifyListeners();
  }
}

