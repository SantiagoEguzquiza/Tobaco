import 'package:flutter/material.dart';
import 'package:tobaco/Models/Tenant.dart';
import 'package:tobaco/Services/Tenant_Service/tenant_service.dart';

class TenantProvider extends ChangeNotifier {
  final TenantService _tenantService = TenantService();
  
  List<Tenant> _tenants = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Tenant> get tenants => _tenants;
  bool get isLoading => _isLoading;
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

  void limpiarError() {
    _errorMessage = null;
    notifyListeners();
  }
}

