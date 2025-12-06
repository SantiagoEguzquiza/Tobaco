import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Screens/Clientes/clientes_screen.dart';
import 'package:tobaco/Screens/Cotizaciones/cotizaciones_screen.dart';
import 'package:tobaco/Screens/CuentaCorriente/cuenta_corriente_screen.dart';
import 'package:tobaco/Screens/Ventas/nuevaVenta_screen.dart';
import 'package:tobaco/Screens/Ventas/ventas_screen.dart';
import 'package:tobaco/Screens/Productos/productos_screen.dart';
import 'package:tobaco/Screens/Auth/login_screen.dart';
import 'package:tobaco/Screens/Config/config_screen.dart';
import 'package:tobaco/Screens/Entregas/mapa_entregas_screen.dart';
import 'package:tobaco/Screens/Entregas/entregas_screen.dart';
import 'package:tobaco/Services/Auth_Service/auth_provider.dart';
import 'package:tobaco/Services/Permisos_Service/permisos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MenuScreen(),
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;

    // Responsive dimensions
    final buttonSize =
        isTablet ? 180.0 : (screenWidth * 0.35).clamp(120.0, 160.0);
    final iconSize = isTablet ? 90.0 : (buttonSize * 0.5).clamp(60.0, 80.0);
    final fontSize = isTablet ? 22.0 : (screenWidth * 0.04).clamp(16.0, 20.0);
    final spacing = isTablet ? 30.0 : 20.0;
    final horizontalPadding = isTablet ? 40.0 : 20.0;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer2<AuthProvider, PermisosProvider>(
          builder: (context, authProvider, permisosProvider, child) {
            // Si el usuario es SuperAdmin, no mostrar este menú (debería estar en SuperAdminMenuScreen)
            final user = authProvider.currentUser;
            if (user != null && user.isSuperAdmin) {
              // Redirigir al menú de SuperAdmin
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacementNamed('/superadmin');
              });
              return const Center(child: CircularProgressIndicator());
            }
            
            // Debug logs
            debugPrint('MenuScreen: isAuthenticated: ${authProvider.isAuthenticated}, isLoading: ${permisosProvider.isLoading}, permisos: ${permisosProvider.permisos != null}, isAdmin: ${permisosProvider.isAdmin}');
            debugPrint('MenuScreen: canViewProductos: ${permisosProvider.canViewProductos}');
            if (permisosProvider.permisos != null) {
              debugPrint('MenuScreen: productosVisualizar: ${permisosProvider.permisos!.productosVisualizar}');
            }
            
            // Cargar permisos cuando el usuario está autenticado y aún no se han cargado
            // El loadPermisos detectará automáticamente cambios de usuario
            if (authProvider.isAuthenticated && 
                !permisosProvider.isLoading && 
                permisosProvider.permisos == null && 
                !permisosProvider.isAdmin &&
                !permisosProvider.hasAttemptedLoad) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                permisosProvider.loadPermisos(authProvider);
              });
            } else if (authProvider.isAuthenticated && 
                       !permisosProvider.isLoading &&
                       authProvider.currentUser?.id != null &&
                       permisosProvider.currentUserId != null &&
                       authProvider.currentUser!.id != permisosProvider.currentUserId) {
              // Si el usuario cambió, forzar recarga de permisos
              WidgetsBinding.instance.addPostFrameCallback((_) {
                permisosProvider.loadPermisos(authProvider, forceReload: true);
              });
            }
            
            return Center(
              
              child: SingleChildScrollView(             
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 800 : double.infinity,
                  ),
                  child: Column(                    
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // Welcome message with user info
                      Container(                                              
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16, top: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              authProvider.currentUser?.isAdmin == true 
                                  ? Icons.admin_panel_settings 
                                  : Icons.person,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Bienvenido, ${authProvider.currentUser?.userName ?? 'Usuario'}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            if (authProvider.currentUser?.isAdmin == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                                ),
                                child: const Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Row para Clientes y Productos - Mostrar solo los botones con permisos
                      if ((permisosProvider.canViewClientes || permisosProvider.isAdmin) ||
                          (permisosProvider.canViewProductos || permisosProvider.isAdmin))
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Clientes - Solo mostrar si tiene permiso de visualizar
                            if (permisosProvider.canViewClientes || permisosProvider.isAdmin)
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6), // Modern blue
                                    foregroundColor: Colors.white, // text color
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    minimumSize: Size(buttonSize, buttonSize),
                                    elevation: 10,
                                    shadowColor: Colors.black,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const ClientesScreen()),
                                    );
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: iconSize,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(),
                                      Text(
                                        'Clientes',
                                        style: TextStyle(
                                          fontSize: fontSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Espaciador solo si ambos botones están visibles
                            if ((permisosProvider.canViewClientes || permisosProvider.isAdmin) &&
                                (permisosProvider.canViewProductos || permisosProvider.isAdmin))
                              SizedBox(width: spacing),
                            // Productos - Solo mostrar si tiene permiso de visualizar
                            if (permisosProvider.canViewProductos || permisosProvider.isAdmin)
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B), // Modern amber
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    minimumSize: Size(buttonSize, buttonSize),
                                    elevation: 10,
                                    shadowColor: Colors.black,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const ProductosScreen()),
                                    );
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.inventory_2,
                                        size: iconSize,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        'Productos',
                                        style: TextStyle(
                                          fontSize: fontSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      // Agregar espacio solo si se mostró la fila anterior
                      if ((permisosProvider.canViewClientes || permisosProvider.isAdmin) ||
                          (permisosProvider.canViewProductos || permisosProvider.isAdmin))
                        SizedBox(height: spacing),
                      // Cuenta Corriente y Ventas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Cuenta Corriente - Solo mostrar si tiene permiso de visualizar
                          if (permisosProvider.canViewCuentaCorriente || permisosProvider.isAdmin)
                            Expanded(
                               child: ElevatedButton(
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: const Color(0xFFEF4444), // Modern red
                                   foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  minimumSize: Size(buttonSize, buttonSize),
                                  elevation: 10,
                                  shadowColor: Colors.black,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => CuentaCorrienteScreen()),
                                  );
                                },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.money_off,
                                    size: iconSize,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Cuenta Corriente',
                                    style: TextStyle(
                                      fontSize: fontSize,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Espaciador solo si ambos botones están visibles
                          if ((permisosProvider.canViewCuentaCorriente || permisosProvider.isAdmin) &&
                              (permisosProvider.canViewVentas || permisosProvider.isAdmin))
                            SizedBox(width: spacing),
                          // Ventas - Solo mostrar si tiene permiso de visualizar
                          if (permisosProvider.canViewVentas || permisosProvider.isAdmin)
                            Expanded(
                               child: ElevatedButton(
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: const Color(0xFF8B5CF6), // Modern purple
                                   foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  minimumSize: Size(buttonSize, buttonSize),
                                  elevation: 10,
                                  shadowColor: Colors.black,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => VentasScreen()),
                                  );
                                },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: iconSize,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Ventas',
                                    style: TextStyle(
                                      fontSize: fontSize,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Agregar espacio solo si se mostró la fila anterior
                      if ((permisosProvider.canViewCuentaCorriente || permisosProvider.isAdmin) ||
                          (permisosProvider.canViewVentas || permisosProvider.isAdmin))
                        SizedBox(height: spacing),
                      // Crear nueva venta - Solo mostrar si tiene permiso de crear
                      if (permisosProvider.canCreateVentas || permisosProvider.isAdmin) ...[
                        SizedBox(
                          width: isTablet ? 400 : double.infinity,
                          height: buttonSize,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981), // Modern emerald
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 10,
                              shadowColor: Colors.black,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const NuevaVentaScreen()),
                              );
                            },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_shopping_cart,
                                size: iconSize,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  'Crear nueva venta',
                                  style: TextStyle(
                                    fontSize: fontSize,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ),
                        SizedBox(height: spacing),
                      ],
                      if (permisosProvider.canViewEntregas || permisosProvider.isAdmin)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB), // Blue
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  minimumSize: Size(buttonSize, buttonSize),
                                  elevation: 10,
                                  shadowColor: Colors.black,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const MapaEntregasScreen(),
                                    ),
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.map,
                                      size: iconSize,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Mapa entregas',
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: spacing),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF34D399), // Teal
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  minimumSize: Size(buttonSize, buttonSize),
                                  elevation: 10,
                                  shadowColor: Colors.black,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const EntregasScreen(),
                                    ),
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.local_shipping,
                                      size: iconSize,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Entregas',
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      // Agregar espacio solo si se mostró la fila anterior
                      if (permisosProvider.canViewEntregas || permisosProvider.isAdmin)
                        SizedBox(height: spacing),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                             child: ElevatedButton(
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: const Color(0xFF059669), // Dark emerald
                                 foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                minimumSize: Size(buttonSize, buttonSize),
                                elevation: 10,
                                shadowColor: Colors.black,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CotizacionesScreen(),
                                  ),
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    size: iconSize,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Monedas',
                                    style: TextStyle(
                                      fontSize: fontSize, 
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: spacing),
                          Expanded(
                             child: ElevatedButton(
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: const Color(0xFF6B7280), // Modern gray
                                 foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                minimumSize: Size(buttonSize, buttonSize),
                                elevation: 10,
                                shadowColor: Colors.black,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ConfigScreen(),
                                  ),
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.settings,
                                    size: iconSize,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Configuración',
                                    style: TextStyle(
                                      fontSize: isTablet ? 18 : 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Espacio adicional al final para evitar que se corten los últimos botones
                      SizedBox(height: spacing * 2),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) async {
    final confirmado = await AppDialogs. showLogoutConfirmationDialog(
      context: context,
    );

    if (confirmado) {
      // Limpiar permisos antes de hacer logout
      context.read<PermisosProvider>().clearPermisos();
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }
}
