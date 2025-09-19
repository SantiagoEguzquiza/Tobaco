import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Services/User_Service/user_provider.dart';
import '../../Services/Auth_Service/auth_provider.dart';
import '../../Services/Auth_Service/auth_service.dart';
import '../../Models/User.dart';
import '../../Theme/app_theme.dart';

// Helper function to check if a user is the last active admin
bool _isLastAdmin(User user, UserProvider userProvider) {
  if (!user.isAdmin || !user.isActive) return false;
  
  final activeAdmins = userProvider.users
      .where((u) => u.isAdmin && u.isActive && u.id != user.id)
      .length;
  
  return activeAdmins == 0;
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
        context.read<UserProvider>().loadUsers();
      }
    });
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
          // Redirect to home if not admin
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil('/menu', (route) => false);
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF2E7D32),
          surface: Colors.white,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          selectionColor: Color(0xFF2E7D32),
          cursorColor: Color(0xFF2E7D32),
          selectionHandleColor: Color(0xFF2E7D32),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          focusColor: const Color(0xFF2E7D32),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2E7D32),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF2E7D32);
            }
            return Colors.grey;
          }),
          trackColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF2E7D32).withOpacity(0.5);
            }
            return Colors.grey.withOpacity(0.3);
          }),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF2E7D32);
            }
            return Colors.grey;
          }),
        ),
        radioTheme: RadioThemeData(
          fillColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF2E7D32);
            }
            return Colors.grey;
          }),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: const Color(0xFF2E7D32),
          thumbColor: const Color(0xFF2E7D32),
          inactiveTrackColor: Colors.grey.withOpacity(0.3),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF2E7D32),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
          labelStyle: const TextStyle(color: Color(0xFF2E7D32)),
          side: BorderSide(color: const Color(0xFF2E7D32).withOpacity(0.3)),
        ),
      ),
      child: Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Gestión de Usuarios',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32), // Dark green
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Procesando...',
                    style: AppTheme.cardSubtitleStyle.copyWith(
                      color: const Color(0xFF2E7D32),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          if (userProvider.errorMessage != null) {
            // Check if it's a token expiration error
            final isTokenExpired = userProvider.errorMessage!.contains('Sesión expirada');
            
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isTokenExpired ? Colors.orange[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isTokenExpired ? Colors.orange[200]! : Colors.red[200]!,
                        ),
                      ),
                      child: Icon(
                        isTokenExpired ? Icons.access_time : Icons.error_outline,
                        size: 64,
                        color: isTokenExpired ? Colors.orange[400] : Colors.red[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isTokenExpired ? 'Sesión Expirada' : 'Error al cargar usuarios',
                      style: AppTheme.appBarTitleStyle.copyWith(
                        color: isTokenExpired ? Colors.orange[700] : Colors.red[700],
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userProvider.errorMessage!,
                      style: AppTheme.cardSubtitleStyle.copyWith(
                        color: isTokenExpired ? Colors.orange[600] : Colors.red[600],
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              // Header with add button
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.people,
                                  color: Color(0xFF2E7D32),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Usuarios del Sistema',
                                      style: AppTheme.appBarTitleStyle.copyWith(
                                        color: const Color(0xFF1B5E20),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${userProvider.users.length} usuarios registrados',
                                      style: AppTheme.cardSubtitleStyle.copyWith(
                                        color: const Color(0xFF4CAF50),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateUserDialog(context),
                      icon: const Icon(Icons.person_add, size: 20),
                      label: const Text('Nuevo Usuario'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
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
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
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
                                style: AppTheme.appBarTitleStyle.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Crea el primer usuario del sistema',
                                style: AppTheme.cardSubtitleStyle.copyWith(
                                  color: Colors.grey[500],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: userProvider.users.length,
                        itemBuilder: (context, index) {
                          final user = userProvider.users[index];
                          return _buildUserCard(context, user, userProvider);
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

  Widget _buildUserCard(BuildContext context, User user, UserProvider userProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: user.isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // User avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: user.isAdmin 
                    ? const Color(0xFF2E7D32).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: user.isAdmin 
                      ? const Color(0xFF2E7D32).withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: user.isAdmin ? const Color(0xFF2E7D32) : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.userName,
                    style: AppTheme.appBarTitleStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B5E20),
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.email!,
                      style: AppTheme.cardSubtitleStyle.copyWith(
                        color: const Color(0xFF4CAF50),
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: user.isAdmin 
                              ? const Color(0xFF2E7D32).withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: user.isAdmin 
                                ? const Color(0xFF2E7D32).withOpacity(0.3)
                                : Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                              size: 14,
                              color: user.isAdmin 
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.role,
                              style: AppTheme.cardSubtitleStyle.copyWith(
                                color: user.isAdmin 
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Show "Último Admin" badge if this is the last admin
                      if (_isLastAdmin(user, userProvider)) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.security,
                                size: 14,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Último Admin',
                                style: AppTheme.cardSubtitleStyle.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: user.isActive 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: user.isActive 
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              user.isActive ? Icons.check_circle : Icons.cancel,
                              size: 14,
                              color: user.isActive 
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.isActive ? 'Activo' : 'Inactivo',
                              style: AppTheme.cardSubtitleStyle.copyWith(
                                color: user.isActive 
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
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
                      _handleUserAction(_safeContext, value, user, userProvider);
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
                        Icon(Icons.edit, size: 20, color: Color(0xFF2E7D32)),
                        SizedBox(width: 8),
                        Text('Editar'),
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
                                : (user.isActive ? Colors.orange : Colors.green),
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
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUserAction(BuildContext context, String action, User user, UserProvider userProvider) {
    // Check if widget is still mounted before handling actions
    if (!mounted) return;
    
    switch (action) {
      case 'edit':
        _showEditUserDialog(context, user, userProvider);
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
            primary: const Color(0xFF2E7D32),
            secondary: const Color(0xFF2E7D32),
          ),
          textSelectionTheme: const TextSelectionThemeData(
            selectionColor: Color(0xFF2E7D32),
            cursorColor: Color(0xFF2E7D32),
            selectionHandleColor: Color(0xFF2E7D32),
          ),
        ),
        child: _CreateUserDialog(),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, User user, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: const Color(0xFF2E7D32),
            secondary: const Color(0xFF2E7D32),
          ),
          textSelectionTheme: const TextSelectionThemeData(
            selectionColor: Color(0xFF2E7D32),
            cursorColor: Color(0xFF2E7D32),
            selectionHandleColor: Color(0xFF2E7D32),
          ),
        ),
        child: _EditUserDialog(user: user),
      ),
    );
  }

  void _toggleUserStatus(BuildContext context, User user, UserProvider userProvider) async {
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    if (result['success']) {
      // Check if current user was affected (deactivated themselves)
      if (result['currentUserAffected']) {
        // Clear the session first
        await AuthService.logout();
        
        // Show message and redirect to login
        scaffoldMessenger.showSnackBar(
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
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  user.isActive ? Icons.pause_circle : Icons.play_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  user.isActive 
                      ? 'Usuario desactivado exitosamente' 
                      : 'Usuario activado exitosamente'
                ),
              ],
            ),
            backgroundColor: user.isActive ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Show error message if operation failed
      final errorMessage = result['error'] ?? userProvider.errorMessage ?? 'Error al actualizar usuario';
      final isTokenExpired = errorMessage.contains('Sesión expirada');
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isTokenExpired ? Icons.access_time : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isTokenExpired 
                      ? 'Sesión expirada. Por favor, inicia sesión nuevamente.'
                      : errorMessage,
                ),
              ),
            ],
          ),
          backgroundColor: isTokenExpired ? Colors.orange : Colors.red,
          duration: const Duration(seconds: 4),
          action: isTokenExpired ? SnackBarAction(
            label: 'Ir al Login',
            textColor: Colors.white,
            onPressed: () {
              if (mounted) {
                navigator.pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
          ) : null,
        ),
      );
      
      // Clear the error from provider after showing snackbar
      userProvider.clearError();
    }
  }

  void _showDeleteUserDialog(BuildContext context, User user, UserProvider userProvider) {
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Cancelar'),
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

  Future<void> _deleteUser(BuildContext context, User user, UserProvider userProvider) async {
    final result = await userProvider.deleteUser(user.id);
    
    // Check if widget is still mounted before accessing context
    if (!mounted) return;
    
    // Store context reference before using it
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    if (result['success']) {
      // Check if current user was affected (deleted themselves)
      if (result['currentUserAffected']) {
        // Clear the session first
        await AuthService.logout();
        
        // Show message and redirect to login
        scaffoldMessenger.showSnackBar(
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
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Usuario "${user.userName}" eliminado exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Show error message if operation failed
      final errorMessage = result['error'] ?? userProvider.errorMessage ?? 'Error al eliminar usuario';
      final isTokenExpired = errorMessage.contains('Sesión expirada');
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isTokenExpired ? Icons.access_time : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isTokenExpired 
                      ? 'Sesión expirada. Por favor, inicia sesión nuevamente.'
                      : errorMessage,
                ),
              ),
            ],
          ),
          backgroundColor: isTokenExpired ? Colors.orange : Colors.red,
          duration: const Duration(seconds: 4),
          action: isTokenExpired ? SnackBarAction(
            label: 'Ir al Login',
            textColor: Colors.white,
            onPressed: () {
              if (mounted) {
                navigator.pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
          ) : null,
        ),
      );
      
      // Clear the error from provider after showing snackbar
      userProvider.clearError();
    }
  }
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
  String _selectedRole = 'Employee';
  
  // Error states for each field
  bool _hasUserNameError = false;
  bool _hasEmailError = false;
  bool _hasPasswordError = false;

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  @override
  Widget build(BuildContext context) {
  return AlertDialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    title: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.person_add,
            color: Color(0xFF2E7D32),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Crear Nuevo Usuario',
          style: TextStyle(
            color: Color(0xFF1B5E20),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    ),
    content: SingleChildScrollView(
      child: TextSelectionTheme(
        data: const TextSelectionThemeData(
          selectionColor: Color(0xFF2E7D32),
          cursorColor: Color(0xFF2E7D32),
          selectionHandleColor: Color(0xFF2E7D32),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _userNameController,
                cursorColor: const Color(0xFF2E7D32),
                style: const TextStyle(color: Colors.black),
                onChanged: (value) => _clearFieldErrors(),
                decoration: InputDecoration(
                  labelText: 'Nombre de Usuario',
                  labelStyle: TextStyle(
                    color: _hasUserNameError ? Colors.red : const Color(0xFF2E7D32),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _hasUserNameError ? Colors.red : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _hasUserNameError ? Colors.red : const Color(0xFF2E7D32),
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
                    Icons.person, 
                    color: _hasUserNameError ? Colors.red : const Color(0xFF2E7D32),
                  ),
                  focusColor: const Color(0xFF2E7D32),
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
                cursorColor: const Color(0xFF2E7D32),
                style: const TextStyle(color: Colors.black),
                onChanged: (value) => _clearFieldErrors(),
                decoration: InputDecoration(
                  labelText: 'Email (Opcional)',
                  labelStyle: TextStyle(
                    color: _hasEmailError ? Colors.red : const Color(0xFF2E7D32),
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
                      color: _hasEmailError ? Colors.red : const Color(0xFF2E7D32),
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
                    Icons.email, 
                    color: _hasEmailError ? Colors.red : const Color(0xFF2E7D32),
                  ),
                  focusColor: const Color(0xFF2E7D32),
                ),
                selectionControls: MaterialTextSelectionControls(),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                cursorColor: const Color(0xFF2E7D32),
                controller: _passwordController,
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  setState(() {}); // para actualizar requisitos
                  _clearFieldErrors();
                },
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: TextStyle(
                    color: _hasPasswordError ? Colors.red : const Color(0xFF2E7D32),
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
                      color: _hasPasswordError ? Colors.red : const Color(0xFF2E7D32),
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
                    color: _hasPasswordError ? Colors.red : const Color(0xFF2E7D32),
                  ),
                  focusColor: const Color(0xFF2E7D32),
                  helperText: 'Mínimo 6 caracteres',
                  helperStyle: TextStyle(
                    color: _hasPasswordError ? Colors.red : const Color(0xFF2E7D32),
                    fontSize: 12,
                  ),
                ),
                selectionControls: MaterialTextSelectionControls(),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La contraseña es requerida';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _passwordController.text.length >= 6
                          ? Icons.check_circle
                          : Icons.info,
                      color: _passwordController.text.length >= 6
                          ? Colors.green[700]
                          : Colors.orange[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _passwordController.text.length >= 6
                          ? 'Válida'
                          : 'Faltan ${6 - _passwordController.text.length}',
                      style: TextStyle(
                        color: _passwordController.text.length >= 6
                            ? Colors.green[700]
                            : Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Rol',
                  labelStyle: const TextStyle(color: Color(0xFF2E7D32)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2E7D32),
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(
                    Icons.admin_panel_settings,
                    color: Color(0xFF2E7D32),
                  ),
                  focusColor: const Color(0xFF2E7D32),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Employee',
                    child: Text(
                      'Empleado',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'Admin',
                    child: Text(
                      'Administrador',
                      style: TextStyle(color: Colors.black, fontSize: 14),
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
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey[600],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text('Cancelar'),
      ),
      Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return ElevatedButton(
            onPressed: userProvider.isLoading
                ? null
                : () => _createUser(context, userProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: userProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Crear'),
          );
        },
      ),
    ],
  );
}

  Future<void> _createUser(BuildContext context, UserProvider userProvider) async {
    if (_formKey.currentState!.validate()) {
      final success = await userProvider.createUser(
        userName: _userNameController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      );

      // Check if widget is still mounted before accessing context
      if (!mounted) return;

      // Store context reference before using it
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      if (success) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Usuario "${_userNameController.text.trim()}" creado exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Get the error message and make it more user-friendly
        String errorMessage = userProvider.errorMessage ?? 'Error al crear usuario';
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
          errorMessage = 'El nombre de usuario "${_userNameController.text.trim()}" ya está en uso.\n\nPor favor, elige un nombre diferente.';
          setState(() {
            _hasUserNameError = true;
          });
        } else if (errorMessage.toLowerCase().contains('email') || 
                   errorMessage.toLowerCase().contains('correo')) {
          errorTitle = 'Email No Válido';
          errorMessage = 'El email ingresado no es válido o ya está en uso.\n\nPor favor, verifica el email e intenta nuevamente.';
          setState(() {
            _hasEmailError = true;
          });
        } else if (errorMessage.toLowerCase().contains('password') || 
                   errorMessage.toLowerCase().contains('contraseña')) {
          errorTitle = 'Contraseña No Válida';
          errorMessage = 'La contraseña no cumple con los requisitos.\n\nPor favor, asegúrate de que tenga al menos 6 caracteres.';
          setState(() {
            _hasPasswordError = true;
          });
        } else {
          errorMessage = 'No se pudo crear el usuario.\n\nPor favor, verifica los datos e intenta nuevamente.';
        }
        
        // Show error dialog instead of SnackBar
        _showErrorDialog(context, errorTitle, errorMessage);
        
        // Clear the error from provider after showing dialog
        userProvider.clearError();
      }
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
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
  late String _selectedRole;
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
    _selectedRole = widget.user.role;
    _isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF2E7D32),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Editar Usuario',
                  style: TextStyle(
                    color: Color(0xFF1B5E20),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
            TextFormField(
              controller: _userNameController,
              style: const TextStyle(color: Colors.black),
              onChanged: (value) => _clearFieldErrors(),
              decoration: InputDecoration(
                labelText: 'Nombre de Usuario',
                labelStyle: TextStyle(
                  color: _hasUserNameError ? Colors.red : const Color(0xFF2E7D32),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _hasUserNameError ? Colors.red : Colors.grey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _hasUserNameError ? Colors.red : const Color(0xFF2E7D32),
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
                  Icons.person, 
                  color: _hasUserNameError ? Colors.red : const Color(0xFF2E7D32),
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
              style: const TextStyle(color: Colors.black),
              onChanged: (value) => _clearFieldErrors(),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(
                  color: _hasEmailError ? Colors.red : const Color(0xFF2E7D32),
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
                    color: _hasEmailError ? Colors.red : const Color(0xFF2E7D32),
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
                  Icons.email, 
                  color: _hasEmailError ? Colors.red : const Color(0xFF2E7D32),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.black),
              onChanged: (value) {
                setState(() {}); // Trigger rebuild to update password requirements
                _clearFieldErrors();
              },
              decoration: InputDecoration(
                labelText: 'Nueva Contraseña (Opcional)',
                labelStyle: TextStyle(
                  color: _hasPasswordError ? Colors.red : const Color(0xFF2E7D32),
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
                    color: _hasPasswordError ? Colors.red : const Color(0xFF2E7D32),
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
                  color: _hasPasswordError ? Colors.red : const Color(0xFF2E7D32),
                ),
                helperText: 'Mín. 6 caracteres (vacío = mantener actual)',
                helperStyle: TextStyle(
                  color: _hasPasswordError ? Colors.red : const Color(0xFF2E7D32),
                  fontSize: 11,
                ),
                helperMaxLines: 2,
              ),
              obscureText: true,
              validator: (value) {
                if (value != null && value.isNotEmpty && value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            // Password requirements indicator
            if (_passwordController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _passwordController.text.length >= 6 
                        ? Icons.check_circle 
                        : Icons.info,
                    color: _passwordController.text.length >= 6 
                        ? Colors.green[700]
                        : Colors.orange[700],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _passwordController.text.length >= 6
                        ? 'Válida'
                        : 'Faltan ${6 - _passwordController.text.length}',
                    style: TextStyle(
                      color: _passwordController.text.length >= 6 
                          ? Colors.green[700]
                          : Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Rol',
                labelStyle: const TextStyle(color: Color(0xFF2E7D32)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                ),
                prefixIcon: const Icon(Icons.admin_panel_settings, color: Color(0xFF2E7D32)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                DropdownMenuItem(
                  value: 'Employee',
                  enabled: !_isLastAdmin(widget.user, context.read<UserProvider>()),
                  child: Row(
                    children: [
                      const Text(
                        'Empleado', 
                        style: TextStyle(color: Colors.black, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_isLastAdmin(widget.user, context.read<UserProvider>())) ...[
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
                const DropdownMenuItem(
                  value: 'Admin', 
                  child: Text(
                    'Administrador', 
                    style: TextStyle(color: Colors.black, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  )
                ),
              ],
              onChanged: (value) {
                // Prevent changing to Employee if this is the last admin
                if (value == 'Employee' && _isLastAdmin(widget.user, context.read<UserProvider>())) {
                  _showLastAdminRoleChangeWarningDialog(context);
                  return;
                }
                
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isActive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: SwitchListTile(
                title: Text(
                  'Usuario Activo',
                  style: TextStyle(
                    color: _isActive ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: _isLastAdmin(widget.user, context.read<UserProvider>()) && _isActive
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
                  if (!value && _isLastAdmin(widget.user, context.read<UserProvider>())) {
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
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancelar'),
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
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: userProvider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Actualizar'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUser(BuildContext context, UserProvider userProvider) async {
    if (_formKey.currentState!.validate()) {
      // Check if trying to change last admin role to employee
      if (widget.user.isAdmin && 
          widget.user.role == 'Admin' && 
          _selectedRole == 'Employee' && 
          _isLastAdmin(widget.user, userProvider)) {
        _showLastAdminRoleChangeWarningDialog(context);
        return;
      }

      final result = await userProvider.updateUser(
        userId: widget.user.id,
        userName: _userNameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        password: _passwordController.text.isEmpty ? null : _passwordController.text,
        role: _selectedRole,
        isActive: _isActive,
      );

      // Check if widget is still mounted before accessing context
      if (!mounted) return;

      // Store context reference before using it
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      if (result['success']) {
        // Check if current user was affected (deactivated themselves)
        if (result['currentUserAffected']) {
          // Clear the session first
          await AuthService.logout();
          
          // Show message and redirect to login
          scaffoldMessenger.showSnackBar(
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
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Usuario "${_userNameController.text.trim()}" actualizado exitosamente. Redirigiendo al inicio...'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            // Close dialog first
            navigator.pop();
            // Then redirect to home after a short delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                navigator.pushNamedAndRemoveUntil('/menu', (route) => false);
              }
            });
          } else {
            navigator.pop();
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Usuario "${_userNameController.text.trim()}" actualizado exitosamente'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // Get the error message and make it more user-friendly
        String errorMessage = userProvider.errorMessage ?? 'Error al actualizar usuario';
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
          errorMessage = 'El nombre de usuario "${_userNameController.text.trim()}" ya está en uso.\n\nPor favor, elige un nombre diferente.';
          setState(() {
            _hasUserNameError = true;
          });
        } else if (errorMessage.toLowerCase().contains('email') || 
                   errorMessage.toLowerCase().contains('correo')) {
          errorTitle = 'Email No Válido';
          errorMessage = 'El email ingresado no es válido o ya está en uso.\n\nPor favor, verifica el email e intenta nuevamente.';
          setState(() {
            _hasEmailError = true;
          });
        } else if (errorMessage.toLowerCase().contains('password') || 
                   errorMessage.toLowerCase().contains('contraseña')) {
          errorTitle = 'Contraseña No Válida';
          errorMessage = 'La contraseña no cumple con los requisitos.\n\nPor favor, asegúrate de que tenga al menos 6 caracteres.';
          setState(() {
            _hasPasswordError = true;
          });
        } else {
          errorMessage = 'No se pudo actualizar el usuario.\n\nPor favor, verifica los datos e intenta nuevamente.';
        }
        
        // Show error dialog instead of SnackBar
        _showErrorDialog(context, errorTitle, errorMessage);
        
        // Clear the error from provider after showing dialog
        userProvider.clearError();
      }
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
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
}
