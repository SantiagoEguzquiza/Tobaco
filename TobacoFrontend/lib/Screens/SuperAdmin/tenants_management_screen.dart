import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Tenant.dart';
import 'package:tobaco/Services/Tenant_Service/tenant_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Theme/dialogs.dart';

class TenantsManagementScreen extends StatefulWidget {
  const TenantsManagementScreen({super.key});

  @override
  State<TenantsManagementScreen> createState() => _TenantsManagementScreenState();
}

class _TenantsManagementScreenState extends State<TenantsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Tenant> _filteredTenants = [];
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
      final provider = context.read<TenantProvider>();
      if (_searchQuery.isEmpty) {
        _filteredTenants = provider.tenants;
      } else {
        _filteredTenants = provider.tenants.where((tenant) {
          return tenant.nombre.toLowerCase().contains(_searchQuery) ||
              (tenant.email?.toLowerCase().contains(_searchQuery) ?? false) ||
              (tenant.descripcion?.toLowerCase().contains(_searchQuery) ?? false);
        }).toList();
      }
    });
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
          'Gestión de Tenants',
          style: AppTheme.appBarTitleStyle,
        ),
      ),
      body: Consumer<TenantProvider>(
        builder: (context, tenantProvider, child) {
          // Actualizar lista filtrada cuando cambian los tenants
          if (_filteredTenants.isEmpty && tenantProvider.tenants.isNotEmpty && _searchQuery.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _filteredTenants = tenantProvider.tenants;
              });
            });
          }

          final tenants = _searchQuery.isEmpty ? tenantProvider.tenants : _filteredTenants;
          final isLoading = tenantProvider.isLoading;
          final errorMessage = tenantProvider.errorMessage;

          if (isLoading && tenantProvider.tenants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando tenants...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          if (errorMessage != null && tenantProvider.tenants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => tenantProvider.cargarTenants(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header con buscador
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeaderConBuscador(
                      leadingIcon: Icons.business,
                      title: 'Gestión de Tenants',
                      subtitle: '${tenantProvider.tenants.length} tenants registrados',
                      controller: _searchController,
                      hintText: 'Buscar tenants...',
                      onChanged: (value) {
                        _onSearchChanged();
                      },
                      onClear: () {
                        _searchController.clear();
                        _onSearchChanged();
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Botón de crear tenant
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _mostrarDialogoCrearTenant(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text(
                          'Nuevo Tenant',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Lista scrolleable de tenants
              Expanded(
                child: tenants.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.business_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No se encontraron tenants'
                                  : 'No hay tenants registrados',
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
                                  : 'Crea tu primer tenant para comenzar',
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
                        itemCount: tenants.length,
                        itemBuilder: (context, index) {
                          final tenant = tenants[index];
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
                                  // Opcional: navegar a detalle del tenant
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Indicador de estado del tenant
                                      Container(
                                        width: 4,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: tenant.isActive ? Colors.green : Colors.grey,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Información del tenant
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tenant.nombre,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.white
                                                    : AppTheme.textColor,
                                                decoration: tenant.isActive 
                                                    ? null 
                                                    : TextDecoration.lineThrough,
                                              ),
                                            ),
                                            if (tenant.descripcion != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                tenant.descripcion!,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Theme.of(context).brightness == Brightness.dark
                                                      ? Colors.grey.shade400
                                                      : Colors.grey.shade600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            if (tenant.email != null) ...[
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
                                                      tenant.email!,
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
                                                color: tenant.isActive 
                                                    ? Colors.green.withOpacity(0.1) 
                                                    : Colors.red.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                tenant.isActive ? 'Activo' : 'Inactivo',
                                                style: TextStyle(
                                                  color: tenant.isActive ? Colors.green : Colors.red,
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
                                              () => _mostrarDialogoEditarTenant(context, tenant),
                                            ),
                                          ),
                                          PopupMenuItem(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  tenant.isActive ? Icons.block : Icons.check_circle,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(tenant.isActive ? 'Desactivar' : 'Activar'),
                                              ],
                                            ),
                                            onTap: () => Future.delayed(
                                              Duration.zero,
                                              () => _toggleTenant(context, tenant),
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
                                              () => _eliminarTenant(context, tenant),
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
          );
        },
      ),
    );
  }

  void _mostrarDialogoCrearTenant(BuildContext context) {
    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();
    final emailController = TextEditingController();
    final telefonoController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool _isLoading = false;

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
                            Icons.business,
                            color: Color(0xFF4CAF50),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Crear Nuevo Tenant',
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
                              controller: nombreController,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFE0E0E0)
                                    : Colors.black,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Nombre *',
                                labelStyle: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF4CAF50),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF4CAF50),
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.business,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El nombre es requerido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: descripcionController,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFE0E0E0)
                                    : Colors.black,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Descripción (Opcional)',
                                labelStyle: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF4CAF50),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF4CAF50),
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.description,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                              maxLines: 2,
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
                                  borderSide: BorderSide(color: Colors.grey),
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
                            TextFormField(
                              controller: telefonoController,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFE0E0E0)
                                    : Colors.black,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Teléfono (Opcional)',
                                labelStyle: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF4CAF50),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF4CAF50),
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.phone,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                              keyboardType: TextInputType.phone,
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

                                          final tenant = Tenant(
                                            id: 0,
                                            nombre: nombreController.text,
                                            descripcion: descripcionController.text.isEmpty 
                                                ? null 
                                                : descripcionController.text,
                                            email: emailController.text.isEmpty 
                                                ? null 
                                                : emailController.text,
                                            telefono: telefonoController.text.isEmpty 
                                                ? null 
                                                : telefonoController.text,
                                            isActive: true,
                                            createdAt: DateTime.now(),
                                          );

                                          try {
                                            await context.read<TenantProvider>().crearTenant(tenant);
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              AppTheme.showSnackBar(
                                                context,
                                                AppTheme.successSnackBar('Tenant creado exitosamente'),
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

  void _mostrarDialogoEditarTenant(BuildContext context, Tenant tenant) {
    final nombreController = TextEditingController(text: tenant.nombre);
    final descripcionController = TextEditingController(text: tenant.descripcion ?? '');
    final emailController = TextEditingController(text: tenant.email ?? '');
    final telefonoController = TextEditingController(text: tenant.telefono ?? '');
    final _formKey = GlobalKey<FormState>();
    bool _isLoading = false;

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
                            'Editar Tenant',
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
                              controller: nombreController,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFE0E0E0)
                                    : Colors.black,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Nombre *',
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
                                  Icons.business,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El nombre es requerido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: descripcionController,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFE0E0E0)
                                    : Colors.black,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Descripción (Opcional)',
                                labelStyle: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF4CAF50),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF4CAF50),
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.description,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                              maxLines: 2,
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
                                  borderSide: BorderSide(color: Colors.grey),
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
                            TextFormField(
                              controller: telefonoController,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFE0E0E0)
                                    : Colors.black,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Teléfono (Opcional)',
                                labelStyle: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF4CAF50),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF4CAF50),
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.phone,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                              keyboardType: TextInputType.phone,
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

                                          final tenantActualizado = Tenant(
                                            id: tenant.id,
                                            nombre: nombreController.text,
                                            descripcion: descripcionController.text.isEmpty 
                                                ? null 
                                                : descripcionController.text,
                                            email: emailController.text.isEmpty 
                                                ? null 
                                                : emailController.text,
                                            telefono: telefonoController.text.isEmpty 
                                                ? null 
                                                : telefonoController.text,
                                            isActive: tenant.isActive,
                                            createdAt: tenant.createdAt,
                                            updatedAt: DateTime.now(),
                                          );

                                          try {
                                            await context.read<TenantProvider>().actualizarTenant(
                                                  tenant.id,
                                                  tenantActualizado,
                                                );
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              AppTheme.showSnackBar(
                                                context,
                                                AppTheme.successSnackBar('Tenant actualizado exitosamente'),
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

  void _toggleTenant(BuildContext context, Tenant tenant) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tenant.isActive ? 'Desactivar Tenant' : 'Activar Tenant'),
        content: Text(
          tenant.isActive
              ? '¿Estás seguro de desactivar este tenant?'
              : '¿Estás seguro de activar este tenant?',
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
      final tenantActualizado = Tenant(
        id: tenant.id,
        nombre: tenant.nombre,
        descripcion: tenant.descripcion,
        email: tenant.email,
        telefono: tenant.telefono,
        isActive: !tenant.isActive,
        createdAt: tenant.createdAt,
        updatedAt: DateTime.now(),
      );

      try {
        await context.read<TenantProvider>().actualizarTenant(
              tenant.id,
              tenantActualizado,
            );
        if (context.mounted) {
          AppTheme.showSnackBar(
            context,
            AppTheme.successSnackBar(
              tenant.isActive
                  ? 'Tenant desactivado'
                  : 'Tenant activado',
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

  void _eliminarTenant(BuildContext context, Tenant tenant) async {
    final confirmado = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar Tenant',
      itemName: tenant.nombre,
      message: '¿Estás seguro de eliminar el tenant "${tenant.nombre}"?\n\nEsta acción no se puede deshacer.',
    );

    if (confirmado == true) {
      try {
        await context.read<TenantProvider>().eliminarTenant(tenant.id);
        if (context.mounted) {
          AppTheme.showSnackBar(
            context,
            AppTheme.successSnackBar('Tenant eliminado exitosamente'),
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

