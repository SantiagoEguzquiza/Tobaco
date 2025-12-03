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
      _admins = await _adminService.obtenerAdminsPorTenant(tenantId);
      _filteredAdmins = _admins;
      _errorMessage = null;
    } catch (e) {
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
                        value: _selectedTenant,
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
                            : Column(
                                children: [
                                  if (_selectedTenant != null) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _mostrarDialogoCrearAdmin(context),
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
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Expanded(
                                    child: admins.isEmpty
                                        ? Container(
                                            padding: const EdgeInsets.all(40),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.people_outline,
                                                  size: 80,
                                                  color: Colors.grey.shade400,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  _searchQuery.isNotEmpty
                                                      ? 'No se encontraron administradores'
                                                      : 'No hay administradores para este tenant',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  _searchQuery.isNotEmpty
                                                      ? 'Intenta con otros términos de búsqueda'
                                                      : 'Crea tu primer administrador para comenzar',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          )
                                        : ListView.builder(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            itemCount: admins.length,
                                            itemBuilder: (context, index) {
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
                                                    onTap: () {
                                                      // Opcional: navegar a detalle del admin
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(16),
                                                      child: Row(
                                                        children: [
                                                          // Indicador de estado del admin
                                                          Container(
                                                            width: 4,
                                                            height: 60,
                                                            decoration: BoxDecoration(
                                                              color: admin.isActive ? Colors.green : Colors.grey,
                                                              borderRadius: BorderRadius.circular(2),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 16),
                                                          
                                                          // Información del admin
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
                                                          
                                                          // Botón de menú
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
                                                                  () => _mostrarDialogoEditarAdmin(context, admin),
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

  void _mostrarDialogoCrearAdmin(BuildContext context) {
    final userNameController = TextEditingController();
    final passwordController = TextEditingController();
    final emailController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool _isLoading = false;
    bool _hasPasswordError = false;

    // Helper functions for password validation
    bool _hasUpperCase(String password) {
      return password.contains(RegExp(r'[A-Z]'));
    }

    bool _hasLowerCase(String password) {
      return password.contains(RegExp(r'[a-z]'));
    }

    bool _hasNumber(String password) {
      return password.contains(RegExp(r'[0-9]'));
    }

    bool _hasMinLength(String password) {
      return password.length >= 8;
    }

    Widget _buildPasswordRule(BuildContext context, String text, bool isValid) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isValid 
                ? Colors.green[700] 
                : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isValid
                    ? (isDark ? Colors.green[300] : Colors.green[700])
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                decoration: isValid ? null : TextDecoration.none,
              ),
            ),
          ),
        ],
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header con título
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? const Color(0xFF2A2A2A).withOpacity(0.5) 
                          : Colors.grey.shade50,
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
                            color: const Color(0xFF4CAF50).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person_add,
                            color: Color(0xFF4CAF50),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Crear Nuevo Administrador',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Contenido
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: userNameController,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFE0E0E0)
                                    : Colors.black,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Nombre de Usuario',
                                labelStyle: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF4CAF50),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF4CAF50),
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.person,
                                  color: Color(0xFF4CAF50),
                                ),
                                helperText: 'No se permiten espacios',
                                helperStyle: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El nombre de usuario es requerido';
                                }
                                if (value.contains(' ')) {
                                  return 'El nombre de usuario no puede contener espacios';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: emailController,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFE0E0E0)
                                    : Colors.black,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Email (Opcional)',
                                labelStyle: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF4CAF50),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF4CAF50),
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.email,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                  if (!emailRegex.hasMatch(value)) {
                                    return 'Ingrese un email válido';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            StatefulBuilder(
                              builder: (context, setState) {
                                return TextFormField(
                                  controller: passwordController,
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFFE0E0E0)
                                        : Colors.black,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _hasPasswordError = !_hasMinLength(value) ||
                                          !_hasUpperCase(value) ||
                                          !_hasLowerCase(value) ||
                                          !_hasNumber(value);
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    labelStyle: TextStyle(
                                      color: _hasPasswordError
                                          ? Colors.red
                                          : Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : const Color(0xFF4CAF50),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _hasPasswordError ? Colors.red : Colors.grey,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _hasPasswordError
                                            ? Colors.red
                                            : const Color(0xFF4CAF50),
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red, width: 2),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red, width: 2),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: _hasPasswordError
                                          ? Colors.red
                                          : const Color(0xFF4CAF50),
                                    ),
                                    helperText: 'Requisitos: mayúscula, minúscula, número y 8+ caracteres',
                                    helperStyle: TextStyle(
                                      color: _hasPasswordError
                                          ? Colors.red
                                          : const Color(0xFF4CAF50),
                                      fontSize: 12,
                                    ),
                                    helperMaxLines: 2,
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'La contraseña es requerida';
                                    }
                                    if (!_hasMinLength(value)) {
                                      return 'La contraseña debe tener al menos 8 caracteres';
                                    }
                                    if (!_hasUpperCase(value)) {
                                      return 'La contraseña debe contener al menos una letra mayúscula';
                                    }
                                    if (!_hasLowerCase(value)) {
                                      return 'La contraseña debe contener al menos una letra minúscula';
                                    }
                                    if (!_hasNumber(value)) {
                                      return 'La contraseña debe contener al menos un número';
                                    }
                                    return null;
                                  },
                                );
                              },
                            ),
                            // Indicadores de reglas de contraseña (solo si hay texto)
                            StatefulBuilder(
                              builder: (context, setState) {
                                if (passwordController.text.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.grey.shade900
                                            : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _hasPasswordError
                                              ? Colors.red.withOpacity(0.3)
                                              : Colors.grey.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Requisitos de contraseña:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.grey.shade300
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildPasswordRule(
                                            context,
                                            'Al menos 8 caracteres',
                                            _hasMinLength(passwordController.text),
                                          ),
                                          const SizedBox(height: 4),
                                          _buildPasswordRule(
                                            context,
                                            'Una letra mayúscula',
                                            _hasUpperCase(passwordController.text),
                                          ),
                                          const SizedBox(height: 4),
                                          _buildPasswordRule(
                                            context,
                                            'Una letra minúscula',
                                            _hasLowerCase(passwordController.text),
                                          ),
                                          const SizedBox(height: 4),
                                          _buildPasswordRule(
                                            context,
                                            'Un número',
                                            _hasNumber(passwordController.text),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Botones
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: isDark 
                                      ? const Color(0xFF2A2A2A) 
                                      : Colors.transparent,
                                  side: BorderSide(
                                    color: isDark 
                                        ? Colors.grey.shade700 
                                        : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          setState(() {
                                            _isLoading = true;
                                          });

                                          try {
                                            await _adminService.crearAdmin(
                                              _selectedTenant!.id,
                                              userName: userNameController.text,
                                              password: passwordController.text,
                                              email: emailController.text.isEmpty
                                                  ? null
                                                  : emailController.text,
                                            );
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              _cargarAdmins(_selectedTenant!.id);
                                              AppTheme.showSnackBar(
                                                context,
                                                AppTheme.successSnackBar('Administrador creado exitosamente'),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              setState(() {
                                                _isLoading = false;
                                              });
                                              AppTheme.showSnackBar(
                                                context,
                                                AppTheme.errorSnackBar('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
                                              );
                                            }
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Crear',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogoEditarAdmin(BuildContext context, User admin) {
    final userNameController = TextEditingController(text: admin.userName);
    final passwordController = TextEditingController();
    final emailController = TextEditingController(text: admin.email ?? '');
    final _formKey = GlobalKey<FormState>();
    bool _isLoading = false;
    bool _hasPasswordError = false;

    // Helper functions for password validation
    bool _hasUpperCase(String password) {
      return password.contains(RegExp(r'[A-Z]'));
    }

    bool _hasLowerCase(String password) {
      return password.contains(RegExp(r'[a-z]'));
    }

    bool _hasNumber(String password) {
      return password.contains(RegExp(r'[0-9]'));
    }

    bool _hasMinLength(String password) {
      return password.length >= 8;
    }

    Widget _buildPasswordRule(BuildContext context, String text, bool isValid) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isValid 
                ? Colors.green[700] 
                : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isValid
                    ? (isDark ? Colors.green[300] : Colors.green[700])
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                decoration: isValid ? null : TextDecoration.none,
              ),
            ),
          ),
        ],
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header con título
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? const Color(0xFF2A2A2A).withOpacity(0.5) 
                          : Colors.grey.shade50,
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
                            color: const Color(0xFF4CAF50).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Color(0xFF4CAF50),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Editar Administrador',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Contenido
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: userNameController,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFE0E0E0)
                                    : Colors.black,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Nombre de Usuario',
                                labelStyle: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF4CAF50),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF4CAF50),
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.person,
                                  color: Color(0xFF4CAF50),
                                ),
                                helperText: 'No se permiten espacios',
                                helperStyle: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El nombre de usuario es requerido';
                                }
                                if (value.contains(' ')) {
                                  return 'El nombre de usuario no puede contener espacios';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: emailController,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFE0E0E0)
                                    : Colors.black,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Email (Opcional)',
                                labelStyle: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF4CAF50),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF4CAF50),
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.email,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                  if (!emailRegex.hasMatch(value)) {
                                    return 'Ingrese un email válido';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            StatefulBuilder(
                              builder: (context, setState) {
                                return TextFormField(
                                  controller: passwordController,
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFFE0E0E0)
                                        : Colors.black,
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty) {
                                      setState(() {
                                        _hasPasswordError = !_hasMinLength(value) ||
                                            !_hasUpperCase(value) ||
                                            !_hasLowerCase(value) ||
                                            !_hasNumber(value);
                                      });
                                    } else {
                                      setState(() {
                                        _hasPasswordError = false;
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Nueva Contraseña (Opcional)',
                                    helperText: 'Dejar vacío para no cambiar la contraseña',
                                    labelStyle: TextStyle(
                                      color: _hasPasswordError && passwordController.text.isNotEmpty
                                          ? Colors.red
                                          : Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : const Color(0xFF4CAF50),
                                    ),
                                    helperStyle: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _hasPasswordError && passwordController.text.isNotEmpty
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _hasPasswordError && passwordController.text.isNotEmpty
                                            ? Colors.red
                                            : const Color(0xFF4CAF50),
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red, width: 2),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red, width: 2),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: _hasPasswordError && passwordController.text.isNotEmpty
                                          ? Colors.red
                                          : const Color(0xFF4CAF50),
                                    ),
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (!_hasMinLength(value)) {
                                        return 'La contraseña debe tener al menos 8 caracteres';
                                      }
                                      if (!_hasUpperCase(value)) {
                                        return 'La contraseña debe contener al menos una letra mayúscula';
                                      }
                                      if (!_hasLowerCase(value)) {
                                        return 'La contraseña debe contener al menos una letra minúscula';
                                      }
                                      if (!_hasNumber(value)) {
                                        return 'La contraseña debe contener al menos un número';
                                      }
                                    }
                                    return null;
                                  },
                                );
                              },
                            ),
                            // Indicadores de reglas de contraseña (solo si hay texto)
                            StatefulBuilder(
                              builder: (context, setState) {
                                if (passwordController.text.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.grey.shade900
                                            : Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _hasPasswordError
                                              ? Colors.red.withOpacity(0.3)
                                              : Colors.grey.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Requisitos de contraseña:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.grey.shade300
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildPasswordRule(
                                            context,
                                            'Al menos 8 caracteres',
                                            _hasMinLength(passwordController.text),
                                          ),
                                          const SizedBox(height: 4),
                                          _buildPasswordRule(
                                            context,
                                            'Una letra mayúscula',
                                            _hasUpperCase(passwordController.text),
                                          ),
                                          const SizedBox(height: 4),
                                          _buildPasswordRule(
                                            context,
                                            'Una letra minúscula',
                                            _hasLowerCase(passwordController.text),
                                          ),
                                          const SizedBox(height: 4),
                                          _buildPasswordRule(
                                            context,
                                            'Un número',
                                            _hasNumber(passwordController.text),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Botones
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: isDark 
                                      ? const Color(0xFF2A2A2A) 
                                      : Colors.transparent,
                                  side: BorderSide(
                                    color: isDark 
                                        ? Colors.grey.shade700 
                                        : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          setState(() {
                                            _isLoading = true;
                                          });

                                          try {
                                            await _adminService.actualizarAdmin(
                                              _selectedTenant!.id,
                                              admin.id,
                                              userName: userNameController.text,
                                              password: passwordController.text.isEmpty
                                                  ? null
                                                  : passwordController.text,
                                              email: emailController.text.isEmpty
                                                  ? null
                                                  : emailController.text,
                                            );
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              _cargarAdmins(_selectedTenant!.id);
                                              AppTheme.showSnackBar(
                                                context,
                                                AppTheme.successSnackBar('Administrador actualizado exitosamente'),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              setState(() {
                                                _isLoading = false;
                                              });
                                              AppTheme.showSnackBar(
                                                context,
                                                AppTheme.errorSnackBar('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
                                              );
                                            }
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Guardar',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

