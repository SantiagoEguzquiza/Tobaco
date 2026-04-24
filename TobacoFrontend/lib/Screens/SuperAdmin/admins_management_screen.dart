import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/User.dart';
import 'package:tobaco/Models/Tenant.dart';
import 'package:tobaco/Services/Tenant_Service/tenant_provider.dart';
import 'package:tobaco/Services/Admin_Service/admin_service.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Screens/SuperAdmin/nuevo_admin_screen.dart';
import 'package:tobaco/Screens/SuperAdmin/editar_admin_screen.dart';

class AdminsManagementScreen extends StatefulWidget {
  const AdminsManagementScreen({super.key});

  @override
  State<AdminsManagementScreen> createState() => _AdminsManagementScreenState();
}

class _AdminsManagementScreenState extends State<AdminsManagementScreen> {
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();
  List<User> _admins = [];
  List<User> _filteredAdmins = [];
  bool _isLoading = false;
  String? _errorMessage;
  Tenant? _selectedTenant;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenantProvider>().cargarTenants();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredAdmins = _admins;
      } else {
        _filteredAdmins = _admins.where((admin) {
          return admin.userName.toLowerCase().contains(_searchQuery) ||
              (admin.email?.toLowerCase().contains(_searchQuery) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _cargarAdmins(int tenantId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('AdminsManagementScreen: Cargando administradores para tenant $tenantId');
      _admins = await _adminService.obtenerAdminsPorTenant(tenantId);
      debugPrint('AdminsManagementScreen: Se obtuvieron ${_admins.length} administradores');
      _filteredAdmins = _admins;
      _errorMessage = null;
    } catch (e) {
      debugPrint('AdminsManagementScreen: Error al cargar administradores: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _admins = [];
      _filteredAdmins = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: null, // Usar el tema (negro)
        foregroundColor: Colors.white,
        title: const Text(
          'Gestión de Administradores',
          style: AppTheme.appBarTitleStyle,
        ),
      ),
      body: Consumer<TenantProvider>(
        builder: (context, tenantProvider, child) {
          final admins = _searchQuery.isEmpty ? _admins : _filteredAdmins;
          
          return Column(
            children: [
              // Header con selector de tenant y buscador
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selector de Tenant moderno
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1A1A1A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<Tenant>(
                        initialValue: _selectedTenant != null &&
                                tenantProvider.tenants.any((t) => t.id == _selectedTenant!.id)
                            ? tenantProvider.tenants.firstWhere((t) => t.id == _selectedTenant!.id)
                            : null,
                        decoration: InputDecoration(
                          labelText: 'Seleccionar Tenant',
                          labelStyle: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.business,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppTheme.textColor,
                        ),
                        dropdownColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1A1A1A)
                            : Colors.white,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          size: 28,
                        ),
                        items: tenantProvider.tenants.map((tenant) {
                          return DropdownMenuItem<Tenant>(
                            value: tenant,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        tenant.nombre,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      if (tenant.email != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          tenant.email!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (tenant.isActive) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Activo',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (tenant) {
                          setState(() {
                            _selectedTenant = tenant;
                            _searchController.clear();
                            _searchQuery = '';
                          });
                          if (tenant != null) {
                            _cargarAdmins(tenant.id);
                          }
                        },
                      ),
                    ),
                    
                    if (_selectedTenant != null) ...[
                      const SizedBox(height: 16),
                      // Header con buscador
                      HeaderConBuscador(
                        leadingIcon: Icons.admin_panel_settings,
                        title: 'Gestión de Administradores',
                        subtitle: '${_admins.length} administradores • Tenant: ${_selectedTenant!.nombre}',
                        controller: _searchController,
                        hintText: 'Buscar administradores...',
                        onChanged: (value) {
                          _onSearchChanged();
                        },
                        onClear: () {
                          _searchController.clear();
                          _onSearchChanged();
                        },
                      ),
                    ],
                  ],
                ),
              ),

              // Lista de Administradores
              Expanded(
                child: _selectedTenant == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Selecciona un tenant para ver sus administradores',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : _isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Cargando administradores...',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _errorMessage != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                                    const SizedBox(height: 16),
                                    Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () => _cargarAdmins(_selectedTenant!.id),
                                      child: const Text('Reintentar'),
                                    ),
                                  ],
                                ),
                              )
                            : CustomScrollView(
                                    slivers: [
                                      SliverToBoxAdapter(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton.icon(
                                                  onPressed: () async {
                                                    FocusScope.of(context).unfocus();
                                                    final result = await Navigator.push<bool>(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => NuevoAdminScreen(tenant: _selectedTenant!),
                                                      ),
                                                    );
                                                    if (result == true && mounted) {
                                                      _cargarAdmins(_selectedTenant!.id);
                                                    }
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.primaryColor,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                                                    ),
                                                    elevation: 2,
                                                  ),
                                                  icon: const Icon(Icons.person_add, size: 20),
                                                  label: const Text(
                                                    'Nuevo Administrador',
                                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (admins.isEmpty)
                                        SliverFillRemaining(
                                          hasScrollBody: false,
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.admin_panel_settings_outlined,
                                                  size: 64,
                                                  color: Colors.grey.shade400,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  _searchQuery.isNotEmpty
                                                      ? 'No se encontraron administradores'
                                                      : 'Sin administradores',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.grey.shade500,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      else
                                        SliverPadding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          sliver: SliverList(
                                            delegate: SliverChildBuilderDelegate(
                                            (context, index) {
                                              final admin = admins[index];
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 12),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).brightness == Brightness.dark
                                                      ? const Color(0xFF1A1A1A)
                                                      : Colors.white,
                                                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Theme.of(context).brightness == Brightness.dark
                                                          ? Colors.black.withOpacity(0.3)
                                                          : Colors.black.withOpacity(0.05),
                                                      blurRadius: 10,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
                                                    onTap: () {},
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(16),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            width: 4,
                                                            height: 60,
                                                            decoration: BoxDecoration(
                                                              color: admin.isActive ? Colors.green : Colors.grey,
                                                              borderRadius: BorderRadius.circular(2),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 16),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  admin.userName,
                                                                  style: TextStyle(
                                                                    fontSize: 18,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Theme.of(context).brightness == Brightness.dark
                                                                        ? Colors.white
                                                                        : AppTheme.textColor,
                                                                    decoration: admin.isActive
                                                                        ? null
                                                                        : TextDecoration.lineThrough,
                                                                  ),
                                                                ),
                                                                if (admin.email != null) ...[
                                                                  const SizedBox(height: 4),
                                                                  Row(
                                                                    children: [
                                                                      Icon(
                                                                        Icons.email_outlined,
                                                                        size: 16,
                                                                        color: Theme.of(context).brightness == Brightness.dark
                                                                            ? Colors.grey.shade400
                                                                            : Colors.grey.shade600,
                                                                      ),
                                                                      const SizedBox(width: 4),
                                                                      Expanded(
                                                                        child: Text(
                                                                          admin.email!,
                                                                          style: TextStyle(
                                                                            fontSize: 14,
                                                                            color: Theme.of(context).brightness == Brightness.dark
                                                                                ? Colors.grey.shade400
                                                                                : Colors.grey.shade600,
                                                                          ),
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                                const SizedBox(height: 4),
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                  decoration: BoxDecoration(
                                                                    color: admin.isActive
                                                                        ? Colors.green.withOpacity(0.1)
                                                                        : Colors.red.withOpacity(0.1),
                                                                    borderRadius: BorderRadius.circular(12),
                                                                  ),
                                                                  child: Text(
                                                                    admin.isActive ? 'Activo' : 'Inactivo',
                                                                    style: TextStyle(
                                                                      color: admin.isActive ? Colors.green : Colors.red,
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: 12,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          PopupMenuButton(
                                                            icon: Icon(
                                                              Icons.more_vert,
                                                              color: Theme.of(context).brightness == Brightness.dark
                                                                  ? Colors.grey.shade400
                                                                  : Colors.grey.shade600,
                                                            ),
                                                            itemBuilder: (context) => [
                                                              PopupMenuItem(
                                                                child: const Row(
                                                                  children: [
                                                                    Icon(Icons.edit, size: 20),
                                                                    SizedBox(width: 8),
                                                                    Text('Editar'),
                                                                  ],
                                                                ),
                                                                onTap: () => Future.delayed(
                                                                  Duration.zero,
                                                                  () async {
                                                                    FocusScope.of(context).unfocus();
                                                                    final result = await Navigator.push<bool>(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder: (context) => EditarAdminScreen(
                                                                          tenant: _selectedTenant!,
                                                                          admin: admin,
                                                                        ),
                                                                      ),
                                                                    );
                                                                    if (result == true && mounted) {
                                                                      _cargarAdmins(_selectedTenant!.id);
                                                                    }
                                                                  },
                                                                ),
                                                              ),
                                                              PopupMenuItem(
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      admin.isActive ? Icons.block : Icons.check_circle,
                                                                      size: 20,
                                                                    ),
                                                                    const SizedBox(width: 8),
                                                                    Text(admin.isActive ? 'Desactivar' : 'Activar'),
                                                                  ],
                                                                ),
                                                                onTap: () => Future.delayed(
                                                                  Duration.zero,
                                                                  () => _toggleAdmin(context, admin),
                                                                ),
                                                              ),
                                                              PopupMenuItem(
                                                                child: const Row(
                                                                  children: [
                                                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                                                    SizedBox(width: 8),
                                                                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                                                                  ],
                                                                ),
                                                                onTap: () => Future.delayed(
                                                                  Duration.zero,
                                                                  () => _eliminarAdmin(context, admin),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                            childCount: admins.length,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleAdmin(BuildContext context, User admin) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(admin.isActive ? 'Desactivar Admin' : 'Activar Admin'),
        content: Text(
          admin.isActive
              ? '¿Estás seguro de desactivar este administrador?'
              : '¿Estás seguro de activar este administrador?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await _adminService.actualizarAdmin(
          _selectedTenant!.id,
          admin.id,
          isActive: !admin.isActive,
        );
        if (context.mounted) {
          _cargarAdmins(_selectedTenant!.id);
          AppTheme.showSnackBar(
            context,
            AppTheme.successSnackBar(
              admin.isActive
                  ? 'Administrador desactivado'
                  : 'Administrador activado',
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppTheme.showSnackBar(
            context,
            AppTheme.errorSnackBar('Error: ${e.toString()}'),
          );
        }
      }
    }
  }

  void _eliminarAdmin(BuildContext context, User admin) async {
    final confirmado = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar Administrador',
      itemName: admin.userName,
      message: '¿Estás seguro de eliminar el administrador "${admin.userName}"?\n\nEsta acción no se puede deshacer.',
    );

    if (confirmado == true) {
      try {
        await _adminService.eliminarAdmin(_selectedTenant!.id, admin.id);
        if (context.mounted) {
          _cargarAdmins(_selectedTenant!.id);
          AppTheme.showSnackBar(
            context,
            AppTheme.successSnackBar('Administrador eliminado exitosamente'),
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppTheme.showSnackBar(
            context,
            AppTheme.errorSnackBar('Error: ${e.toString()}'),
          );
        }
      }
    }
  }
}

