import 'package:flutter/material.dart';
import '../../Models/User.dart';
import '../../Models/PermisosEmpleado.dart';
import '../../Services/Permisos_Service/permisos_service.dart';
import '../../Theme/app_theme.dart';

class PermisosEmpleadoScreen extends StatefulWidget {
  final User user;

  const PermisosEmpleadoScreen({super.key, required this.user});

  @override
  State<PermisosEmpleadoScreen> createState() => _PermisosEmpleadoScreenState();
}

class _PermisosEmpleadoScreenState extends State<PermisosEmpleadoScreen> {
  PermisosEmpleado? _permisos;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPermisos();
  }

  Future<void> _loadPermisos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final permisos = await PermisosService.getPermisosByUserId(widget.user.id);
      setState(() {
        _permisos = permisos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _savePermisos() async {
    if (_permisos == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updatedPermisos = await PermisosService.updatePermisos(
        widget.user.id,
        _permisos!,
      );
      setState(() {
        _permisos = updatedPermisos;
        _isSaving = false;
      });

      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Permisos actualizados exitosamente'),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSaving = false;
      });

      if (mounted) {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al guardar: ${e.toString().replaceAll('Exception: ', '')}'),
        );
      }
    }
  }

  Widget _buildPermissionSection({
    required String title,
    required IconData icon,
    required List<PermissionItem> permissions,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF2A2A2A).withOpacity(0.5) 
                  : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark 
                      ? Colors.grey.shade800 
                      : Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Permissions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: permissions.map((permission) {
                return _buildPermissionSwitch(permission);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSwitch(PermissionItem permission) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SwitchListTile(
      value: permission.value,
      onChanged: _isSaving ? null : (value) {
        setState(() {
          permission.value = value;
          permission.onChanged(value);
        });
      },
      title: Text(
        permission.label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        permission.description,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
      activeColor: AppTheme.primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: null, // Usar el tema
          title: const Text('Permisos del Empleado', style: AppTheme.appBarTitleStyle),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );
    }

    if (_errorMessage != null && _permisos == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: null, // Usar el tema
          title: const Text('Permisos del Empleado', style: AppTheme.appBarTitleStyle),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar permisos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadPermisos,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_permisos == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: null, // Usar el tema
          title: const Text('Permisos del Empleado', style: AppTheme.appBarTitleStyle),
        ),
        body: const Center(
          child: Text('No se encontraron permisos'),
        ),
      );
    }

    // Create permission items
    final productosPermissions = [
      PermissionItem(
        label: 'Visualizar',
        description: 'Puede ver la lista de productos',
        value: _permisos!.productosVisualizar,
        onChanged: (value) => setState(() => _permisos = _permisos!.copyWith(productosVisualizar: value)),
      ),
      PermissionItem(
        label: 'Crear',
        description: 'Puede crear nuevos productos',
        value: _permisos!.productosCrear,
        onChanged: (value) => setState(() => _permisos = _permisos!.copyWith(productosCrear: value)),
      ),
      PermissionItem(
        label: 'Editar',
        description: 'Puede modificar productos existentes',
        value: _permisos!.productosEditar,
        onChanged: (value) => setState(() => _permisos = _permisos!.copyWith(productosEditar: value)),
      ),
      PermissionItem(
        label: 'Eliminar',
        description: 'Puede eliminar productos',
        value: _permisos!.productosEliminar,
        onChanged: (value) => setState(() => _permisos = _permisos!.copyWith(productosEliminar: value)),
      ),
    ];

    final clientesPermissions = [
      PermissionItem(
        label: 'Visualizar',
        description: 'Puede ver la lista de clientes',
        value: _permisos!.clientesVisualizar,
        onChanged: (value) => setState(() => _permisos = _permisos!.copyWith(clientesVisualizar: value)),
      ),
      PermissionItem(
        label: 'Crear',
        description: 'Puede crear nuevos clientes',
        value: _permisos!.clientesCrear,
        onChanged: (value) => setState(() => _permisos = _permisos!.copyWith(clientesCrear: value)),
      ),
      PermissionItem(
        label: 'Editar',
        description: 'Puede modificar clientes existentes',
        value: _permisos!.clientesEditar,
        onChanged: (value) => setState(() => _permisos = _permisos!.copyWith(clientesEditar: value)),
      ),
      PermissionItem(
        label: 'Eliminar',
        description: 'Puede eliminar clientes',
        value: _permisos!.clientesEliminar,
        onChanged: (value) => setState(() => _permisos = _permisos!.copyWith(clientesEliminar: value)),
      ),
    ];

    final ventasPermissions = [
      PermissionItem(
        label: 'Visualizar',
        description: 'Puede ver el historial de ventas',
        value: _permisos!.ventasVisualizar,
        onChanged: (value) => setState(() => _permisos = _permisos!.copyWith(ventasVisualizar: value)),
      ),
      PermissionItem(
        label: 'Crear',
        description: 'Puede crear nuevas ventas',
        value: _permisos!.ventasCrear,
        onChanged: (value) => setState(() => _permisos = _permisos!.copyWith(ventasCrear: value)),
      ),
      PermissionItem(
        label: 'Editar Borrador',
        description: 'Puede modificar ventas en borrador',
        value: _permisos!.ventasEditarBorrador,
        onChanged: (value) => setState(() => _permisos = _permisos!.copyWith(ventasEditarBorrador: value)),
      ),
      PermissionItem(
        label: 'Eliminar',
        description: 'Puede eliminar ventas',
        value: _permisos!.ventasEliminar,
        onChanged: (value) => setState(() => _permisos = _permisos!.copyWith(ventasEliminar: value)),
      ),
    ];

    final cuentaCorrientePermissions = [
      PermissionItem(
        label: 'Visualizar',
        description: 'Puede ver la cuenta corriente de clientes',
        value: _permisos!.cuentaCorrienteVisualizar,
        onChanged: (value) => setState(() => _permisos = _permisos!.copyWith(cuentaCorrienteVisualizar: value)),
      ),
      PermissionItem(
        label: 'Registrar Abonos',
        description: 'Puede registrar abonos en cuenta corriente',
        value: _permisos!.cuentaCorrienteRegistrarAbonos,
        onChanged: (value) => setState(() => _permisos = _permisos!.copyWith(cuentaCorrienteRegistrarAbonos: value)),
      ),
    ];

    final entregasPermissions = [
      PermissionItem(
        label: 'Visualizar',
        description: 'Puede ver las entregas y el mapa de entregas',
        value: _permisos!.entregasVisualizar,
        onChanged: (value) => setState(() => _permisos = _permisos!.copyWith(entregasVisualizar: value)),
      ),
      PermissionItem(
        label: 'Actualizar Estado',
        description: 'Puede actualizar el estado de las entregas',
        value: _permisos!.entregasActualizarEstado,
        onChanged: (value) => setState(() => _permisos = _permisos!.copyWith(entregasActualizarEstado: value)),
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: null, // Usar el tema
        title: Text('Permisos: ${widget.user.userName}', style: AppTheme.appBarTitleStyle),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info card
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person,
                            color: AppTheme.primaryColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user.userName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.user.role == 'Admin' ? 'Administrador' : 'Empleado',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Permission sections
                  _buildPermissionSection(
                    title: 'PRODUCTOS',
                    icon: Icons.inventory_2,
                    permissions: productosPermissions,
                  ),
                  _buildPermissionSection(
                    title: 'CLIENTES',
                    icon: Icons.people,
                    permissions: clientesPermissions,
                  ),
                  _buildPermissionSection(
                    title: 'VENTAS',
                    icon: Icons.shopping_cart,
                    permissions: ventasPermissions,
                  ),
                  _buildPermissionSection(
                    title: 'CUENTA CORRIENTE',
                    icon: Icons.account_balance_wallet,
                    permissions: cuentaCorrientePermissions,
                  ),
                  _buildPermissionSection(
                    title: 'ENTREGAS',
                    icon: Icons.local_shipping,
                    permissions: entregasPermissions,
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Save button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _savePermisos,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving ? 'Guardando...' : 'Guardar Cambios',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PermissionItem {
  final String label;
  final String description;
  bool value;
  final Function(bool) onChanged;

  PermissionItem({
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });
}

