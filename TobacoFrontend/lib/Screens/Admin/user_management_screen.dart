import 'package:flutter/material.dart';
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
import '../../Services/Permisos_Service/permisos_provider.dart';

// Helper function to check if a user is the last active admin
bool _isLastAdmin(User user, UserProvider userProvider) {
  if (!user.isAdmin || !user.isActive) return false;

  final activeAdmins = userProvider.users
      .where((u) => u.isAdmin && u.isActive && u.id != user.id)
      .length;

  return activeAdmins == 0;
}

// Helper function to get localized role name
String _getRoleDisplayName(String role) {
  switch (role) {
    case 'Admin':
      return 'Administrador';
    case 'Employee':
      return 'Empleado';
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
        'No puedes cambiar el rol del último administrador a empleado.\n\n'
        'Esto evitaría que cualquier persona pueda acceder a las funciones administrativas de la aplicación.\n\n'
        'Para realizar esta acción, primero crea otro usuario administrador.',
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
        'No puedes desactivar tu cuenta porque eres el último administrador activo en el sistema.\n\n'
        'Esto evitaría que cualquier persona pueda acceder a las funciones administrativas de la aplicación.\n\n'
        'Para realizar esta acción, primero crea otro usuario administrador.',
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
        debugPrint('Es un error de conexión, mostrando diálogo de servidor no disponible');
        await Apihandler.handleConnectionError(context, e);
      } else if (mounted) {
        debugPrint('No es un error de conexión, mostrando diálogo genérico');
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
                'No se puede realizar esta acción',
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
          'No puedes desactivar o eliminar el último administrador del sistema.\n\n'
          'Esto evitaría que cualquier persona pueda acceder a las funciones administrativas de la aplicación.\n\n'
          'Para realizar esta acción, primero crea otro usuario administrador.',
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
                    'Sesión Finalizada',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tu cuenta ha sido desactivada.\nSerás redirigido al login.',
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
          'Gestión de Usuarios',
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
                        userProvider.errorMessage!.contains('Sesión expirada');

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
                                  ? 'Sesión Expirada'
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

                  return Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: HeaderSimple(
                          leadingIcon: Icons.people,
                          title: 'Usuarios del Sistema',
                          subtitle: '${userProvider.users.length} usuarios registrados',
                        ),
                      ),
                      
                      // Add user button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showCreateUserDialog(context),
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
                        child: userProvider.users.isEmpty
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
                  itemCount: userProvider.users.length,
                  itemBuilder: (context, index) {
                    final user = userProvider.users[index];
                                  return _buildUserCard(
                                      context, user, userProvider);
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
      BuildContext context, User user, UserProvider userProvider) {
    final indicatorColor = user.isActive 
        ? (user.isAdmin ? const Color(0xFF4CAF50) : AppTheme.primaryColor)
        : Colors.red;
    
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

              // Información del usuario
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
                              'Último Admin',
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

              // Actions
              PopupMenuButton<String>(
              onSelected: (value) {
                // Use a post-frame callback with a small delay to ensure the popup is fully dismissed
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      _handleUserAction(
                          _safeContext, value, user, userProvider);
                    }
                  });
                });
              },
              itemBuilder: (context) {
                final isLastAdmin = _isLastAdmin(user, userProvider);
                // Only disable if it's the last active admin (can't deactivate)
                // Inactive users can always be activated
                final shouldDisableToggle = isLastAdmin;

                return [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: Color(0xFF4CAF50)),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  // Solo mostrar permisos para empleados (no admins)
                  if (!user.isAdmin)
                    const PopupMenuItem(
                      value: 'permisos',
                      child: Row(
                        children: [
                          Icon(Icons.security, size: 20, color: Color(0xFF2196F3)),
                          SizedBox(width: 8),
                          Text('Permisos'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: user.isActive ? 'deactivate' : 'activate',
                    enabled: !shouldDisableToggle,
                    child: Row(
                      children: [
                        Icon(
                          user.isActive ? Icons.pause : Icons.play_arrow,
                          size: 20,
                          color: shouldDisableToggle
                              ? Colors.grey
                              : (user.isActive ? Colors.orange : Colors.green),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.isActive ? 'Desactivar' : 'Activar',
                          style: TextStyle(
                            color: shouldDisableToggle
                                ? Colors.grey
                                : (user.isActive
                                    ? Colors.orange
                                    : Colors.green),
                          ),
                        ),
                        if (shouldDisableToggle) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.lock,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    enabled: !isLastAdmin,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_forever,
                          size: 20,
                          color: isLastAdmin ? Colors.grey : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Eliminar Permanentemente',
                          style: TextStyle(
                            color: isLastAdmin ? Colors.grey : Colors.red,
                          ),
                        ),
                        if (isLastAdmin) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.lock,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                      ],
                    ),
                  ),
                ];
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleUserAction(BuildContext context, String action, User user,
      UserProvider userProvider) {
    // Check if widget is still mounted before handling actions
    if (!mounted) return;

    switch (action) {
      case 'edit':
        _showEditUserDialog(context, user, userProvider);
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

  void _showCreateUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Theme(
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
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
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
        ),
        child: _CreateUserDialog(),
      ),
    );
  }

  void _showEditUserDialog(
      BuildContext context, User user, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => Theme(
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
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
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
        ),
        child: _EditUserDialog(user: user),
      ),
    );
  }

  void _toggleUserStatus(
      BuildContext context, User user, UserProvider userProvider) async {
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
        // Limpiar permisos antes de hacer logout
        context.read<PermisosProvider>().clearPermisos();
        // Clear the session first
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
      final isTokenExpired = errorMessage.contains('Sesión expirada');

      if (isTokenExpired) {
        await AppDialogs.showWarningDialog(
          context: context,
          title: 'Sesión Expirada',
          message: 'Por favor, inicia sesión nuevamente.',
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
      BuildContext context, User user, UserProvider userProvider) {
    // Check if trying to delete the last admin
    if (_isLastAdmin(user, userProvider)) {
      _showLastAdminWarningDialog(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[400], size: 24),
            const SizedBox(width: 8),
            const Text(
              'Eliminar Usuario',
              style: TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que quieres eliminar permanentemente al usuario "${user.userName}"?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer. El usuario será eliminado permanentemente de la base de datos.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey.shade300 
                    : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteUser(context, user, userProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
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
        // Limpiar permisos antes de hacer logout
        context.read<PermisosProvider>().clearPermisos();
        // Clear the session first
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
      final isTokenExpired = errorMessage.contains('Sesión expirada');

      if (isTokenExpired) {
        await AppDialogs.showWarningDialog(
          context: context,
          title: 'Sesión Expirada',
          message: 'Por favor, inicia sesión nuevamente.',
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
  return password.length >= 6;
}

bool _isPasswordValid(String password) {
  return _hasUpperCase(password) && 
         _hasLowerCase(password) && 
         _hasNumber(password) && 
         _hasMinLength(password);
}

class _CreateUserDialog extends StatefulWidget {
  @override
  _CreateUserDialogState createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _zonaController = TextEditingController();
  String _selectedRole = 'Employee';
  TipoVendedor _selectedTipoVendedor = TipoVendedor.repartidor;

  // Error states for each field
  bool _hasUserNameError = false;
  bool _hasEmailError = false;
  bool _hasPasswordError = false;

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _zonaController.dispose();
    super.dispose();
  }

  // Clear error states when user starts typing
  void _clearFieldErrors() {
    setState(() {
      _hasUserNameError = false;
      _hasEmailError = false;
      _hasPasswordError = false;
    });
  }

  // Build password rule indicator
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

  @override
  Widget build(BuildContext context) {
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
                        'Crear Nuevo Usuario',
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
                              controller: _userNameController,
                              style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFE0E0E0)
                          : Colors.black,
                    ),
                              onChanged: (value) => _clearFieldErrors(),
                              decoration: InputDecoration(
                                labelText: 'Nombre de Usuario',
                                labelStyle: TextStyle(
                                  color: _hasUserNameError
                                      ? Colors.red
                                : Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF4CAF50),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                              color:
                                  _hasUserNameError ? Colors.red : Colors.grey,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _hasUserNameError
                                        ? Colors.red
                                  : const Color(0xFF4CAF50),
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.red, width: 2),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.red, width: 2),
                                ),
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: _hasUserNameError
                                      ? Colors.red
                                : const Color(0xFF4CAF50),
                                ),
                              ),
                              selectionControls: MaterialTextSelectionControls(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El nombre de usuario es requerido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFE0E0E0)
                              : Colors.black,
                        ),
                              onChanged: (value) => _clearFieldErrors(),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  // Validar formato de email solo si hay contenido
                                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                  if (!emailRegex.hasMatch(value)) {
                                    return 'Ingrese un email válido';
                                  }
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Email (Opcional)',
                                labelStyle: TextStyle(
                                  color: _hasEmailError
                                      ? Colors.red
                                : Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF4CAF50),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _hasEmailError ? Colors.red : Colors.grey,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                              color: _hasEmailError
                                  ? Colors.red
                                  : const Color(0xFF4CAF50),
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.red, width: 2),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.red, width: 2),
                                ),
                                prefixIcon: Icon(
                                  Icons.email,
                            color: _hasEmailError
                                ? Colors.red
                                : const Color(0xFF4CAF50),
                                ),
                              ),
                              selectionControls: MaterialTextSelectionControls(),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFE0E0E0)
                              : Colors.black,
                        ),
                              onChanged: (value) {
                                setState(() {}); // para actualizar requisitos
                                _clearFieldErrors();
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
                              color:
                                  _hasPasswordError ? Colors.red : Colors.grey,
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
                            borderSide:
                                const BorderSide(color: Colors.red, width: 2),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.red, width: 2),
                                ),
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: _hasPasswordError
                                      ? Colors.red
                                : const Color(0xFF4CAF50),
                                ),
                                helperText: 'Requisitos: mayúscula, minúscula, número y 6+ caracteres',
                                helperStyle: TextStyle(
                                  color: _hasPasswordError
                                      ? Colors.red
                                : const Color(0xFF4CAF50),
                                  fontSize: 12,
                                ),
                                helperMaxLines: 2,
                              ),
                              selectionControls: MaterialTextSelectionControls(),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'La contraseña es requerida';
                                }
                                if (!_hasMinLength(value)) {
                                  return 'La contraseña debe tener al menos 6 caracteres';
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
                            ),
                            // Indicadores de reglas de contraseña (solo si hay texto)
                            if (_passwordController.text.isNotEmpty) ...[
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
                                      'Al menos 6 caracteres',
                                      _hasMinLength(_passwordController.text),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildPasswordRule(
                                      context,
                                      'Una letra mayúscula',
                                      _hasUpperCase(_passwordController.text),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildPasswordRule(
                                      context,
                                      'Una letra minúscula',
                                      _hasLowerCase(_passwordController.text),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildPasswordRule(
                                      context,
                                      'Un número',
                                      _hasNumber(_passwordController.text),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                        dropdownColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1A1A1A)
                                : Colors.white,
                              style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFE0E0E0)
                              : Colors.black,
                        ),
                              decoration: InputDecoration(
                                labelText: 'Rol',
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
                                  Icons.admin_panel_settings,
                            color: Color(0xFF4CAF50),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'Employee',
                                  child: Text(
                                    'Empleado',
                                    style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 14,
                              ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Admin',
                                  child: Text(
                                    'Administrador',
                                    style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 14,
                              ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value!;
                                });
                              },
                            ),
                            // Mostrar selector de TipoVendedor solo si es Employee
                            if (_selectedRole == 'Employee') ...[
                              const SizedBox(height: 16),
                              DropdownButtonFormField<TipoVendedor>(
                                value: _selectedTipoVendedor,
                                dropdownColor:
                                    Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFF1A1A1A)
                                        : Colors.white,
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFFE0E0E0)
                                      : Colors.black,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Tipo de Usuario',
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
                                    Icons.badge,
                                    color: Color(0xFF4CAF50),
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: TipoVendedor.values.map((tipo) {
                                  return DropdownMenuItem(
                                    value: tipo,
                                    child: Text(
                                      tipo.displayName,
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedTipoVendedor = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedTipoVendedor.description,
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _zonaController,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFE0E0E0)
                                    : Colors.black,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Zona (opcional)',
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
                                  Icons.location_on,
                                  color: Color(0xFF4CAF50),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 16,
                                ),
                                helperText: 'Ej: Zona Norte, Zona Sur, Centro',
                                helperStyle: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[500]
                                      : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            ],
                          ),
                        ),
                      ),
                    ),
              // Botones
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
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
                        child: Consumer<UserProvider>(
                          builder: (context, userProvider, child) {
                            return ElevatedButton(
                              onPressed: userProvider.isLoading
                                  ? null
                                  : () => _createUser(context, userProvider),
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
                              child: userProvider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white),
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
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Future<void> _createUser(
      BuildContext context, UserProvider userProvider) async {
    if (_formKey.currentState!.validate()) {
      final success = await userProvider.createUser(
        userName: _userNameController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        tipoVendedor: _selectedRole == 'Employee' ? _selectedTipoVendedor : null,
        zona: _zonaController.text.trim().isEmpty 
            ? null 
            : _zonaController.text.trim(),
      );

      // Check if widget is still mounted before accessing context
      if (!mounted) return;

      // Store context reference before using it
      final navigator = Navigator.of(context);

        if (success) {
        navigator.pop();
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Usuario "${_userNameController.text.trim()}" creado exitosamente'),
        );
      } else {
        // Get the error message and make it more user-friendly
        String errorMessage =
            userProvider.errorMessage ?? 'Error al crear usuario';
        String errorTitle = 'Error al Crear Usuario';

        // Clear all error states first
        setState(() {
          _hasUserNameError = false;
          _hasEmailError = false;
          _hasPasswordError = false;
        });

        // Check if it's a duplicate username error
        if (errorMessage.toLowerCase().contains('duplicate') ||
            errorMessage.toLowerCase().contains('username') ||
            errorMessage.toLowerCase().contains('ya existe') ||
            errorMessage.toLowerCase().contains('duplicado')) {
          errorTitle = 'Nombre de Usuario No Disponible';
          errorMessage =
              'El nombre de usuario "${_userNameController.text.trim()}" ya está en uso.\n\nPor favor, elige un nombre diferente.';
          setState(() {
            _hasUserNameError = true;
          });
        } else if (errorMessage.toLowerCase().contains('email') ||
            errorMessage.toLowerCase().contains('correo')) {
          errorTitle = 'Email No Válido';
          errorMessage =
              'El email ingresado no es válido o ya está en uso.\n\nPor favor, verifica el email e intenta nuevamente.';
          setState(() {
            _hasEmailError = true;
          });
        } else if (errorMessage.toLowerCase().contains('password') ||
            errorMessage.toLowerCase().contains('contraseña')) {
          errorTitle = 'Contraseña No Válida';
          errorMessage =
              'La contraseña no cumple con los requisitos.\n\nPor favor, asegúrate de que tenga al menos 6 caracteres.';
          setState(() {
            _hasPasswordError = true;
          });
        } else {
          errorMessage =
              'No se pudo crear el usuario.\n\nPor favor, verifica los datos e intenta nuevamente.';
        }

        // Show error dialog instead of SnackBar
        AppDialogs.showErrorDialog(
          context: context,
          title: errorTitle,
          message: errorMessage,
        );

        // Clear the error from provider after showing dialog
        userProvider.clearError();
      }
    }
  }
}

class _EditUserDialog extends StatefulWidget {
  final User user;

  const _EditUserDialog({required this.user});

  @override
  _EditUserDialogState createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _userNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _zonaController;
  late String _selectedRole;
  late TipoVendedor _selectedTipoVendedor;
  late bool _isActive;

  // Error states for each field
  bool _hasUserNameError = false;
  bool _hasEmailError = false;
  bool _hasPasswordError = false;

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController(text: widget.user.userName);
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _passwordController = TextEditingController();
    _zonaController = TextEditingController(text: widget.user.zona ?? '');
    _selectedRole = widget.user.role;
    _selectedTipoVendedor = widget.user.tipoVendedor;
    _isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _zonaController.dispose();
    super.dispose();
  }

  // Clear error states when user starts typing
  void _clearFieldErrors() {
    setState(() {
      _hasUserNameError = false;
      _hasEmailError = false;
      _hasPasswordError = false;
    });
  }

  // Build password rule indicator
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

  @override
  Widget build(BuildContext context) {
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
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
                          'Editar Usuario',
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
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                            TextFormField(
                              controller: _userNameController,
                              style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFE0E0E0)
                              : Colors.black,
                        ),
                              onChanged: (value) => _clearFieldErrors(),
                              decoration: InputDecoration(
                                labelText: 'Nombre de Usuario',
                                labelStyle: TextStyle(
                                  color: _hasUserNameError
                                      ? Colors.red
                                : Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF4CAF50),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                              color:
                                  _hasUserNameError ? Colors.red : Colors.grey,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _hasUserNameError
                                        ? Colors.red
                                  : const Color(0xFF2E7D32),
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.red, width: 2),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.red, width: 2),
                                ),
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: _hasUserNameError
                                      ? Colors.red
                                : const Color(0xFF2E7D32),
                                ),
                                ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El nombre de usuario es requerido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFE0E0E0)
                              : Colors.black,
                        ),
                              onChanged: (value) => _clearFieldErrors(),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  // Validar formato de email solo si hay contenido
                                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                  if (!emailRegex.hasMatch(value)) {
                                    return 'Ingrese un email válido';
                                  }
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                          labelText: 'Email',
                                labelStyle: TextStyle(
                                  color: _hasEmailError
                                      ? Colors.red
                                : Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF4CAF50),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _hasEmailError ? Colors.red : Colors.grey,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                              color: _hasEmailError
                                  ? Colors.red
                                  : const Color(0xFF2E7D32),
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.red, width: 2),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.red, width: 2),
                                ),
                                prefixIcon: Icon(
                                  Icons.email,
                            color: _hasEmailError
                                ? Colors.red
                                : const Color(0xFF2E7D32),
                                ),
                                ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFE0E0E0)
                              : Colors.black,
                        ),
                              onChanged: (value) {
                          setState(
                              () {}); // Trigger rebuild to update password requirements
                                _clearFieldErrors();
                              },
                              decoration: InputDecoration(
                          labelText: 'Nueva Contraseña (Opcional)',
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
                              color:
                                  _hasPasswordError ? Colors.red : Colors.grey,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _hasPasswordError
                                        ? Colors.red
                                  : const Color(0xFF2E7D32),
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.red, width: 2),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.red, width: 2),
                                ),
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: _hasPasswordError
                                      ? Colors.red
                                : const Color(0xFF2E7D32),
                          ),
                          helperText:
                              'Requisitos: mayúscula, minúscula, número y 6+ caracteres (vacío = mantener actual)',
                                helperStyle: TextStyle(
                                  color: _hasPasswordError
                                      ? Colors.red
                                : const Color(0xFF2E7D32),
                            fontSize: 11,
                                ),
                          helperMaxLines: 2,
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (!_hasMinLength(value)) {
                                    return 'La contraseña debe tener al menos 6 caracteres';
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
                            ),
                            // Indicadores de reglas de contraseña (solo si hay texto)
                            if (_passwordController.text.isNotEmpty) ...[
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
                                      'Al menos 6 caracteres',
                                      _hasMinLength(_passwordController.text),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildPasswordRule(
                                      context,
                                      'Una letra mayúscula',
                                      _hasUpperCase(_passwordController.text),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildPasswordRule(
                                      context,
                                      'Una letra minúscula',
                                      _hasLowerCase(_passwordController.text),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildPasswordRule(
                                      context,
                                      'Un número',
                                      _hasNumber(_passwordController.text),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFE0E0E0)
                              : Colors.black,
                        ),
                              decoration: InputDecoration(
                                labelText: 'Rol',
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
                                color: Color(0xFF2E7D32), width: 2),
                                ),
                                prefixIcon: const Icon(Icons.admin_panel_settings,
                              color: Color(0xFF2E7D32)),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'Employee',
                                  enabled: !_isLastAdmin(
                                      widget.user, context.read<UserProvider>()),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Empleado',
                                        style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black, 
                                            fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (_isLastAdmin(widget.user,
                                          context.read<UserProvider>())) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.lock,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Admin',
                                  child: Text(
                                    'Administrador',
                                    style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black, 
                                        fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                              )),
                              ],
                              onChanged: (value) {
                                // Prevent changing to Employee if this is the last admin
                                if (value == 'Employee' &&
                                    _isLastAdmin(
                                        widget.user, context.read<UserProvider>())) {
                                  _showLastAdminRoleChangeWarningDialog(context);
                                  return;
                                }

                                setState(() {
                                  _selectedRole = value!;
                                });
                              },
                      ),
                      // Mostrar selector de TipoVendedor solo si es Employee
                      if (_selectedRole == 'Employee') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<TipoVendedor>(
                          value: _selectedTipoVendedor,
                          dropdownColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF1A1A1A)
                                  : Colors.white,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFFE0E0E0)
                                : Colors.black,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Tipo de Usuario',
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
                              Icons.badge,
                              color: Color(0xFF4CAF50),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: TipoVendedor.values.map((tipo) {
                            return DropdownMenuItem(
                              value: tipo,
                              child: Text(
                                tipo.displayName,
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTipoVendedor = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedTipoVendedor.description,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[700],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _zonaController,
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFFE0E0E0)
                                : Colors.black,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Zona (opcional)',
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
                              Icons.location_on,
                              color: Color(0xFF4CAF50),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            helperText: 'Ej: Zona Norte, Zona Sur, Centro',
                            helperStyle: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isActive
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            'Usuario Activo',
                            style: TextStyle(
                              color: _isActive
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: _isLastAdmin(widget.user,
                                      context.read<UserProvider>()) &&
                                  _isActive
                              ? const Text(
                                  'No puedes desactivarte (eres el último administrador)',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : null,
                          value: _isActive,
                          onChanged: (value) {
                            // Prevent deactivating if this is the last admin
                            if (!value &&
                                _isLastAdmin(widget.user,
                                    context.read<UserProvider>())) {
                              _showLastAdminDeactivationWarningDialog(context);
                              return;
                            }

                            setState(() {
                              _isActive = value;
                            });
                          },
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Botones dentro del scroll
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
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
                              child: Consumer<UserProvider>(
                                builder: (context, userProvider, child) {
                                  return ElevatedButton(
                                    onPressed: userProvider.isLoading
                                        ? null
                                        : () => _updateUser(context, userProvider),
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
                                    child: userProvider.isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                            ),
                                          )
                                        : const Text(
                                            'Actualizar',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              letterSpacing: 0.2,
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
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateUser(
      BuildContext context, UserProvider userProvider) async {
    if (_formKey.currentState!.validate()) {
      // Check if trying to change last admin role to employee
      if (widget.user.isAdmin &&
          widget.user.role == 'Admin' &&
          _selectedRole == 'Employee' &&
          _isLastAdmin(widget.user, userProvider)) {
        _showLastAdminRoleChangeWarningDialog(context);
        return;
      }

      Map<String, dynamic> result;
      try {
        result = await userProvider.updateUser(
          userId: widget.user.id,
          userName: _userNameController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          password:
              _passwordController.text.isEmpty ? null : _passwordController.text,
          role: _selectedRole,
          isActive: _isActive,
          tipoVendedor: _selectedRole == 'Employee' ? _selectedTipoVendedor : null,
          zona: _zonaController.text.trim().isEmpty 
              ? null 
              : _zonaController.text.trim(),
        );
      } catch (e) {
        if (mounted && Apihandler.isConnectionError(e)) {
          await Apihandler.handleConnectionError(context, e);
          return;
        } else {
          // Para otros errores, mostrar el diálogo de error genérico
          AppDialogs.showErrorDialog(
            context: context,
            title: 'Error al Actualizar Usuario',
            message: 'No se pudo actualizar el usuario. Por favor, intente más tarde.',
          );
          return;
        }
      }

      // Check if widget is still mounted before accessing context
      if (!mounted) return;

      // Store context reference before using it
      final navigator = Navigator.of(context);

      if (result['success']) {
        // Check if current user was affected (deactivated themselves)
        if (result['currentUserAffected']) {
          // Limpiar permisos antes de hacer logout
          context.read<PermisosProvider>().clearPermisos();
          // Clear the session first
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

          // Close dialog first
          navigator.pop();

          // Redirect to login after a short delay
          Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
              navigator.pushNamedAndRemoveUntil('/login', (route) => false);
            }
          });
        } else {
          // Check if the current user changed their role from Admin to Employee
          final authProvider = context.read<AuthProvider>();
          if (widget.user.id == authProvider.currentUser?.id &&
              widget.user.role == 'Admin' &&
              _selectedRole == 'Employee') {
            // Show success message
            navigator.pop();
            AppTheme.showSnackBar(
              context,
              AppTheme.successSnackBar('Usuario "${_userNameController.text.trim()}" actualizado exitosamente'),
            );
            // Then redirect to home
            if (mounted) {
              navigator.pushNamedAndRemoveUntil('/menu', (route) => false);
            }
        } else {
            navigator.pop();
            AppTheme.showSnackBar(
              context,
              AppTheme.successSnackBar('Usuario "${_userNameController.text.trim()}" actualizado exitosamente'),
            );
        }
      }
      } else {
        // Get the error message and make it more user-friendly
        String errorMessage =
            userProvider.errorMessage ?? 'Error al actualizar usuario';
        String errorTitle = 'Error al Actualizar Usuario';

        // Clear all error states first
        setState(() {
          _hasUserNameError = false;
          _hasEmailError = false;
          _hasPasswordError = false;
        });

        // Check if it's a duplicate username error
        if (errorMessage.toLowerCase().contains('duplicate') ||
            errorMessage.toLowerCase().contains('username') ||
            errorMessage.toLowerCase().contains('ya existe') ||
            errorMessage.toLowerCase().contains('duplicado')) {
          errorTitle = 'Nombre de Usuario No Disponible';
          errorMessage =
              'El nombre de usuario "${_userNameController.text.trim()}" ya está en uso.\n\nPor favor, elige un nombre diferente.';
          setState(() {
            _hasUserNameError = true;
          });
        } else if (errorMessage.toLowerCase().contains('email') ||
            errorMessage.toLowerCase().contains('correo')) {
          errorTitle = 'Email No Válido';
          errorMessage =
              'El email ingresado no es válido o ya está en uso.\n\nPor favor, verifica el email e intenta nuevamente.';
          setState(() {
            _hasEmailError = true;
          });
        } else if (errorMessage.toLowerCase().contains('password') ||
            errorMessage.toLowerCase().contains('contraseña')) {
          errorTitle = 'Contraseña No Válida';
          errorMessage =
              'La contraseña no cumple con los requisitos.\n\nPor favor, asegúrate de que tenga al menos 6 caracteres.';
          setState(() {
            _hasPasswordError = true;
          });
        } else {
          errorMessage =
              'No se pudo actualizar el usuario.\n\nPor favor, verifica los datos e intenta nuevamente.';
        }

        // Show error dialog instead of SnackBar
        AppDialogs.showErrorDialog(
          context: context,
          title: errorTitle,
          message: errorMessage,
        );

        // Clear the error from provider after showing dialog
        userProvider.clearError();
      }
    }
  }
}
