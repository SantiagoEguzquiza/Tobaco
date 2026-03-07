import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../Services/User_Service/user_provider.dart';
import '../../Services/Auth_Service/auth_provider.dart';
import '../../Services/Auth_Service/auth_service.dart';
import '../../Models/User.dart';
import '../../Models/TipoVendedor.dart';
import '../../Theme/app_theme.dart';
import '../../Theme/dialogs.dart';
import '../../Theme/headers.dart';
import '../../Helpers/api_handler.dart';
import 'permisos_empleado_screen.dart';
import 'nuevo_usuario_screen.dart';
import 'editar_usuario_screen.dart';
import '../../Services/Categoria_Service/categoria_provider.dart';
import '../../Services/Clientes_Service/clientes_provider.dart';
import '../../Services/Permisos_Service/permisos_provider.dart';
import '../../Services/Productos_Service/productos_provider.dart';
import '../../Services/Ventas_Service/ventas_provider.dart';

// Helper function to check if a user is the last active admin
bool _isLastAdmin(User user, UserProvider userProvider) {
  if (!user.isAdmin || !user.isActive) return false;

  final activeAdmins = userProvider.users
      .where((u) => u.isAdmin && u.isActive && u.id != user.id)
      .length;

  return activeAdmins == 0;
}

// Helper function to get localized role name-
String _getRoleDisplayName(String role) {
  switch (role) {
    case 'Admin':
      return 'Administrador';
    case 'Employee':
      return 'Empleado';
    case 'SuperAdmin':
      return 'SuperAdmin';
    default:
      return role;
  }
}

// Show warning dialog for last admin role change
void _showLastAdminRoleChangeWarningDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No se puede cambiar el rol',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: const Text(
        'No puedes cambiar el rol del Ãºltimo administrador a empleado.\n\n'
        'Esto evitarÃ­a que cualquier persona pueda acceder a las funciones administrativas de la aplicaciÃ³n.\n\n'
        'Para realizar esta acciÃ³n, primero crea otro usuario administrador.',
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            'Entendido',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    ),
  );
}

// Show warning dialog for last admin deactivation
void _showLastAdminDeactivationWarningDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No se puede desactivar',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: const Text(
        'No puedes desactivar tu cuenta porque eres el Ãºltimo administrador activo en el sistema.\n\n'
        'Esto evitarÃ­a que cualquier persona pueda acceder a las funciones administrativas de la aplicaciÃ³n.\n\n'
        'Para realizar esta acciÃ³n, primero crea otro usuario administrador.',
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            'Entendido',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    ),
  );
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late BuildContext _safeContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUsers();
      }
    });
  }

  Future<void> _loadUsers() async {
    debugPrint('_loadUsers: Iniciando carga de usuarios...');
    try {
      await context.read<UserProvider>().loadUsers();
      debugPrint('_loadUsers: Carga completada exitosamente');
    } catch (e) {
      debugPrint('Error en _loadUsers: $e');
      debugPrint('Error tipo: ${e.runtimeType}');
      
      if (mounted && Apihandler.isConnectionError(e)) {
        debugPrint('Es un error de conexiÃ³n, mostrando diÃ¡logo de servidor no disponible');
        await Apihandler.handleConnectionError(context, e);
      } else if (mounted) {
        debugPrint('No es un error de conexiÃ³n, mostrando diÃ¡logo genÃ©rico');
        await AppDialogs.showErrorDialog(
          context: context,
          message: 'Error al cargar usuarios',
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _safeContext = context;
  }

  @override
  void dispose() {
    // Clear any pending operations to prevent context access after disposal
    super.dispose();
  }

  // Check if user is the last admin

  // Show warning dialog for last admin
  void _showLastAdminWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No se puede realizar esta acciÃ³n',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'No puedes desactivar o eliminar el Ãºltimo administrador del sistema.\n\n'
          'Esto evitarÃ­a que cualquier persona pueda acceder a las funciones administrativas de la aplicaciÃ³n.\n\n'
          'Para realizar esta acciÃ³n, primero crea otro usuario administrador.',
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Entendido',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Check if current user is admin
        if (authProvider.currentUser?.role != 'Admin') {
          // If user is not admin, show a message and redirect to login
          // This happens when user was deactivated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              }
            });
          });

    return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.logout,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SesiÃ³n Finalizada',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tu cuenta ha sido desactivada.\nSerÃ¡s redirigido al login.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ],
              ),
            ),
          );
        }

        return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: const Color(0xFF4CAF50),
                    secondary: const Color(0xFF66BB6A),
                    surface: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1A1A1A)
                        : Colors.white,
                  ),
              textSelectionTheme: TextSelectionThemeData(
                selectionColor: const Color(0xFF4CAF50).withOpacity(0.3),
                cursorColor: const Color(0xFF4CAF50),
                selectionHandleColor: const Color(0xFF4CAF50),
              ),
              inputDecorationTheme: InputDecorationTheme(
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF4CAF50), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF404040)
                        : Colors.grey,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF404040)
                        : Colors.grey,
                  ),
                ),
                focusColor: const Color(0xFF4CAF50),
                labelStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF808080)
                      : const Color(0xFF4CAF50),
                ),
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF606060)
                      : Colors.grey,
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF50),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
              ),
              switchTheme: SwitchThemeData(
                thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF4CAF50);
                  }
                  return Colors.grey;
                }),
                trackColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF4CAF50).withOpacity(0.5);
                  }
                  return Colors.grey.withOpacity(0.3);
                }),
              ),
              checkboxTheme: CheckboxThemeData(
                fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF4CAF50);
                  }
                  return Colors.grey;
                }),
              ),
              radioTheme: RadioThemeData(
                fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF4CAF50);
                  }
                  return Colors.grey;
                }),
              ),
              sliderTheme: SliderThemeData(
                activeTrackColor: const Color(0xFF4CAF50),
                thumbColor: const Color(0xFF4CAF50),
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
              ),
              progressIndicatorTheme: const ProgressIndicatorThemeData(
                color: Color(0xFF4CAF50),
              ),
              chipTheme: ChipThemeData(
                backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                labelStyle: const TextStyle(color: Color(0xFF4CAF50)),
                side:
                    BorderSide(color: const Color(0xFF4CAF50).withOpacity(0.3)),
              ),
            ),
            child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Gestión de usuarios',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
              body: Consumer2<UserProvider, AuthProvider>(
                builder: (context, userProvider, authProvider, child) {
                  if (userProvider.isLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF4CAF50)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Procesando...',
                            style: AppTheme.cardSubtitleStyle.copyWith(
                              color: const Color(0xFF4CAF50),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (userProvider.errorMessage != null) {
                    // Check if it's a token expiration error
                    final isTokenExpired =
                        userProvider.errorMessage!.contains('SesiÃ³n expirada');

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isTokenExpired
                                    ? Colors.orange[50]
                                    : Colors.red[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isTokenExpired
                                      ? Colors.orange[200]!
                                      : Colors.red[200]!,
                                ),
                              ),
                              child: Icon(
                                isTokenExpired
                                    ? Icons.access_time
                                    : Icons.error_outline,
                                size: 64,
                                color: isTokenExpired
                                    ? Colors.orange[400]
                                    : Colors.red[400],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              isTokenExpired
                                  ? 'SesiÃ³n Expirada'
                                  : 'Error al cargar usuarios',
                              style: AppTheme.appBarTitleStyle.copyWith(
                                color: isTokenExpired
                                    ? Colors.orange[700]
                                    : Colors.red[700],
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              userProvider.errorMessage!,
                              style: AppTheme.cardSubtitleStyle.copyWith(
                                color: isTokenExpired
                                    ? Colors.orange[600]
                                    : Colors.red[600],
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            if (isTokenExpired) ...[
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Navigate back to login screen
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/login',
                                    (route) => false,
                                  );
                                },
                                icon: const Icon(Icons.login),
                                label: const Text('Ir al Login'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ] else ...[
                              ElevatedButton.icon(
                                onPressed: () => userProvider.loadUsers(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reintentar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ),
                  );
                }

                  // Filter out superadmins if current user is not a superadmin
                  final currentUser = authProvider.currentUser;
                  final isCurrentUserSuperAdmin = currentUser?.isSuperAdmin ?? false;
                  final visibleUsers = isCurrentUserSuperAdmin
                      ? userProvider.users
                      : userProvider.users.where((u) => !u.isSuperAdmin).toList();

                  return Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: HeaderSimple(
                          leadingIcon: Icons.people,
                          title: 'Gestión de usuarios',
                          subtitle: '${visibleUsers.length} usuarios registrados',
                        ),
                      ),
                      
                      // Add user button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(builder: (context) => const NuevoUsuarioScreen()),
                              );
                              if (result == true && mounted) {
                                context.read<UserProvider>().loadUsers();
                              }
                            },
                            icon: const Icon(Icons.person_add, size: 20),
                            label: const Text(
                              'Nuevo Usuario',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24, 
                                vertical: 16,
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ),

                      // Users list
                      Expanded(
                        child: visibleUsers.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color: Colors.grey[200]!),
                                        ),
                                        child: Icon(
                                          Icons.people_outline,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'No hay usuarios registrados',
                                        style:
                                            AppTheme.appBarTitleStyle.copyWith(
                                          color: Colors.grey[600],
                                          fontSize: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Crea el primer usuario del sistema',
                                        style:
                                            AppTheme.cardSubtitleStyle.copyWith(
                                          color: Colors.grey[500],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                  itemCount: visibleUsers.length,
                  itemBuilder: (context, index) {
                    final user = visibleUsers[index];
                                  return _buildUserCard(
                                      context, user, userProvider, authProvider);
              },
            ),
          ),
        ],
                  );
                },
              ),
            ));
      },
    );
  }

  Widget _buildUserCard(
      BuildContext context, User user, UserProvider userProvider, AuthProvider authProvider) {
    final indicatorColor = user.isActive 
        ? (user.isAdmin ? const Color(0xFF4CAF50) : AppTheme.primaryColor)
        : Colors.red;
    
    final currentUser = authProvider.currentUser;
    final isCurrentUserSuperAdmin = currentUser?.isSuperAdmin ?? false;
    final isUserSuperAdmin = user.isSuperAdmin;
    final canModifySuperAdmin = isCurrentUserSuperAdmin || !isUserSuperAdmin;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Indicador lateral
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),

              // InformaciÃ³n del usuario
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.userName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.email != null) ...[
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
                              user.email!,
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
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                          size: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: user.isAdmin
                                ? const Color(0xFF4CAF50).withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: user.isAdmin
                                  ? const Color(0xFF4CAF50).withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _getRoleDisplayName(user.role),
                            style: TextStyle(
                              fontSize: 10,
                              color: user.isAdmin
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (_isLastAdmin(user, userProvider)) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'Ãšltimo Admin',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: user.isActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: user.isActive
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            user.isActive ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                              fontSize: 10,
                              color: user.isActive
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions - menú modernizado
              PopupMenuButton<String>(
              onSelected: (value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Future.delayed(const Duration(milliseconds: 100), () async {
                    if (mounted) {
                      await _handleUserAction(
                          _safeContext, value, user, userProvider);
                    }
                  });
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.15),
              padding: EdgeInsets.zero,
              offset: const Offset(0, 40),
              itemBuilder: (context) {
                final isLastAdmin = _isLastAdmin(user, userProvider);
                final shouldDisableToggle = isLastAdmin || (!canModifySuperAdmin && user.isActive);
                final canDelete = !isLastAdmin && canModifySuperAdmin;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final textColor = isDark ? Colors.white : Colors.black87;
                final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

                return [
                  PopupMenuItem(
                    value: 'edit',
                    enabled: canModifySuperAdmin,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (canModifySuperAdmin ? AppTheme.primaryColor : subColor).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            size: 20,
                            color: canModifySuperAdmin ? AppTheme.primaryColor : subColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Editar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: canModifySuperAdmin ? textColor : subColor,
                          ),
                        ),
                        if (!canModifySuperAdmin) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.lock_rounded, size: 16, color: subColor),
                        ],
                      ],
                    ),
                  ),
                  if (!user.isAdmin)
                    PopupMenuItem(
                      value: 'permisos',
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.security_rounded, size: 20, color: Color(0xFF2196F3)),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'Permisos',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: user.isActive ? 'deactivate' : 'activate',
                    enabled: !shouldDisableToggle,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (shouldDisableToggle ? subColor : (user.isActive ? Colors.orange : Colors.green)).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            user.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 20,
                            color: shouldDisableToggle ? subColor : (user.isActive ? Colors.orange : Colors.green),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          user.isActive ? 'Desactivar' : 'Activar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: shouldDisableToggle ? subColor : (user.isActive ? Colors.orange : Colors.green),
                          ),
                        ),
                        if (shouldDisableToggle) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.lock_rounded, size: 16, color: subColor),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    enabled: canDelete,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (canDelete ? Colors.red : subColor).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.delete_rounded,
                            size: 20,
                            color: canDelete ? Colors.red : subColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Eliminar permanentemente',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: canDelete ? Colors.red : subColor,
                          ),
                        ),
                        if (!canDelete) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.lock_rounded, size: 16, color: subColor),
                        ],
                      ],
                    ),
                  ),
                ];
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUserAction(BuildContext context, String action, User user,
      UserProvider userProvider) async {
    // Check if widget is still mounted before handling actions
    if (!mounted) return;

    switch (action) {
      case 'edit':
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => EditarUsuarioScreen(user: user),
          ),
        );
        if (result == true && mounted) {
          userProvider.loadUsers();
        }
        break;
      case 'permisos':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PermisosEmpleadoScreen(user: user),
          ),
        );
        break;
      case 'activate':
      case 'deactivate':
        _toggleUserStatus(context, user, userProvider);
        break;
      case 'delete':
        _showDeleteUserDialog(context, user, userProvider);
        break;
    }
  }

  void _toggleUserStatus(
      BuildContext context, User user, UserProvider userProvider) async {
    // Prevent deactivating superadmins (only superadmins can deactivate other superadmins)
    if (user.isSuperAdmin) {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      if (currentUser == null || !currentUser.isSuperAdmin) {
        await AppDialogs.showWarningDialog(
          context: context,
          title: 'No se puede desactivar',
          message: 'No se puede desactivar un usuario SuperAdmin. Los SuperAdmins tienen permisos especiales y solo pueden ser desactivados por otros SuperAdmins.',
        );
        return;
      }
    }

    // Check if trying to deactivate the last admin
    if (user.isActive && _isLastAdmin(user, userProvider)) {
      _showLastAdminWarningDialog(context);
      return;
    }

    // Inactive users can always be activated

    final result = await userProvider.updateUser(
        userId: user.id,
        isActive: !user.isActive,
      );

    // Check if widget is still mounted before accessing context
    if (!mounted) return;

    // Store context reference before using it
    final navigator = Navigator.of(context);

    if (result['success']) {
      // Check if current user was affected (deactivated themselves)
      if (result['currentUserAffected']) {
        await context.read<ClienteProvider>().clearForNewUser();
        await context.read<VentasProvider>().clearForNewUser();
        await context.read<ProductoProvider>().clearForNewUser();
        await context.read<CategoriasProvider>().clearForNewUser();
        context.read<PermisosProvider>().clearPermisos();
        await AuthService.logout();

        // Show message and redirect to login
        AppTheme.showSnackBar(
          context,
          SnackBar(
            content: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.logout, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      result['message'] ?? 'Tu cuenta ha sido desactivada',
                      style: const TextStyle(fontSize: 14),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Redirect to login after a short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
            navigator.pushNamedAndRemoveUntil('/login', (route) => false);
          }
        });
      } else {
        // Normal success message
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar(user.isActive
              ? 'Usuario desactivado exitosamente'
              : 'Usuario activado exitosamente'),
        );
      }
    } else {
      // Show error message if operation failed
      final errorMessage = result['error'] ??
          userProvider.errorMessage ??
          'Error al actualizar usuario';
      final isTokenExpired = errorMessage.contains('SesiÃ³n expirada');

      if (isTokenExpired) {
        await AppDialogs.showWarningDialog(
          context: context,
          title: 'SesiÃ³n Expirada',
          message: 'Por favor, inicia sesiÃ³n nuevamente.',
        );
        if (mounted) {
          navigator.pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } else {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar(errorMessage),
        );
      }

      // Clear the error from provider after showing snackbar
      userProvider.clearError();
    }
  }

  void _showDeleteUserDialog(
      BuildContext context, User user, UserProvider userProvider) async {
    // Prevent deleting superadmins
    if (user.isSuperAdmin) {
      await AppDialogs.showWarningDialog(
        context: context,
        title: 'No se puede eliminar',
        message: 'No se puede eliminar un usuario SuperAdmin. Los SuperAdmins tienen permisos especiales y no pueden ser eliminados por administradores normales.',
      );
      return;
    }

    // Check if trying to delete the last admin
    if (_isLastAdmin(user, userProvider)) {
      _showLastAdminWarningDialog(context);
      return;
    }

    final confirm = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar Usuario',
      message: 'Â¿EstÃ¡s seguro de que quieres eliminar permanentemente al usuario "${user.userName}"?\n\nEsta acciÃ³n no se puede deshacer. El usuario serÃ¡ eliminado permanentemente de la base de datos.',
      itemName: user.userName,
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
    );

    if (confirm == true) {
      await _deleteUser(context, user, userProvider);
    }
  }

  Future<void> _deleteUser(
      BuildContext context, User user, UserProvider userProvider) async {
    final result = await userProvider.deleteUser(user.id);

    // Check if widget is still mounted before accessing context
    if (!mounted) return;

    // Store context reference before using it
    final navigator = Navigator.of(context);

    if (result['success']) {
      // Check if current user was affected (deleted themselves)
      if (result['currentUserAffected']) {
        await context.read<ClienteProvider>().clearForNewUser();
        await context.read<VentasProvider>().clearForNewUser();
        await context.read<ProductoProvider>().clearForNewUser();
        await context.read<CategoriasProvider>().clearForNewUser();
        context.read<PermisosProvider>().clearPermisos();
        await AuthService.logout();

        // Show message and redirect to login
        AppTheme.showSnackBar(
          context,
          SnackBar(
            content: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.logout, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      result['message'] ?? 'Tu cuenta ha sido eliminada',
                      style: const TextStyle(fontSize: 14),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Redirect to login after a short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            navigator.pushNamedAndRemoveUntil('/login', (route) => false);
          }
        });
      } else {
        // Normal success message
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Usuario "${user.userName}" eliminado exitosamente'),
        );
      }
    } else {
      // Show error message if operation failed
      final errorMessage = result['error'] ??
          userProvider.errorMessage ??
          'Error al eliminar usuario';
      final isTokenExpired = errorMessage.contains('SesiÃ³n expirada');

      if (isTokenExpired) {
        await AppDialogs.showWarningDialog(
          context: context,
          title: 'SesiÃ³n Expirada',
          message: 'Por favor, inicia sesiÃ³n nuevamente.',
        );
        if (mounted) {
          navigator.pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } else {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar(errorMessage),
        );
      }

      // Clear the error from provider after showing snackbar
      userProvider.clearError();
    }
  }
}
