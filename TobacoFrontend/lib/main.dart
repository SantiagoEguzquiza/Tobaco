import 'package:flutter/material.dart';
import 'package:tobaco/Screens/menu_screen.dart';
import 'package:tobaco/Screens/Auth/login_screen.dart';
import 'package:tobaco/Screens/SuperAdmin/super_admin_menu_screen.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Services/Cotizaciones_Service/cotizaciones_provider.dart';
import 'package:tobaco/Services/Cotizaciones_Service/cotizaciones_repo.dart';
import 'package:tobaco/Services/Auth_Service/auth_provider.dart';
import 'package:tobaco/Services/User_Service/user_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/theme_provider.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';
import 'package:tobaco/Services/VentaBorrador_Service/venta_borrador_provider.dart';
import 'package:tobaco/Services/Entregas_Service/entregas_provider.dart';
import 'package:tobaco/Services/Entregas_Service/entregas_service.dart';
import 'package:tobaco/Services/Entregas_Service/ubicacion_service.dart';
import 'package:tobaco/Services/Cache/database_helper.dart';
import 'package:tobaco/Services/Connectivity/connectivity_service.dart';
import 'package:tobaco/Services/RecorridosProgramados_Service/recorridos_programados_provider.dart';
import 'package:tobaco/Services/Permisos_Service/permisos_provider.dart';
import 'package:tobaco/Services/Tenant_Service/tenant_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 🌐 Inicializar conectividad para habilitar llamadas online
  await ConnectivityService().initialize();
  // Sincronización automática deshabilitada: solo manual desde listado de ventas

  final themeProvider = ThemeProvider();
  await themeProvider.loadThemeMode();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PermisosProvider()),
        ChangeNotifierProvider(create: (_) => ClienteProvider()),
        ChangeNotifierProvider(create: (_) => ProductoProvider()),
        ChangeNotifierProvider(create: (_) => CategoriasProvider()),
        ChangeNotifierProvider(create: (_) => VentasProvider()),
        ChangeNotifierProvider(create: (_) => VentaBorradorProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
        // 1) Repo primero
        Provider(create: (_) => BcuRepository()),
        // 2) Provider que depende del repo
        ChangeNotifierProvider(
          create: (ctx) => BcuProvider(ctx.read<BcuRepository>()),
        ),
        // 🗺️ Provider de Entregas y Mapas
        ChangeNotifierProvider(
          create: (ctx) => EntregasProvider(
            entregasService: EntregasService(),
            ubicacionService: UbicacionService(),
            databaseHelper: DatabaseHelper(),
            connectivityService: ConnectivityService(),
          ),
        ),
        // 🛣️ Provider de Recorridos Programados
        ChangeNotifierProvider(create: (_) => RecorridosProgramadosProvider()),
        // 🏢 Provider de Tenants (para SuperAdmin)
        ChangeNotifierProvider(create: (_) => TenantProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const AuthWrapper(),
      routes: {
        '/menu': (context) => const MenuScreen(),
        '/superadmin': (context) => const SuperAdminMenuScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize authentication state
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      await authProvider.initializeAuth();
      
      // Si el usuario está autenticado y NO es SuperAdmin, cargar permisos
      // El SuperAdmin no necesita permisos de empleado porque no gestiona datos de clientes
      if (authProvider.isAuthenticated && mounted) {
        final user = authProvider.currentUser;
        if (user != null && !user.isSuperAdmin) {
          final permisosProvider = context.read<PermisosProvider>();
          await permisosProvider.loadPermisos(authProvider, forceReload: true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Si está cargando, mostrar pantalla de carga
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Si está autenticado, verificar el rol
        if (authProvider.isAuthenticated) {
          final user = authProvider.currentUser;
          
          // Si el usuario aún no está cargado, mostrar pantalla de carga
          if (user == null) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // Si es SuperAdmin, mostrar su menú especial
          if (user.isSuperAdmin) {
            return const SuperAdminMenuScreen();
          }
          
          // Si es Admin o Employee, mostrar el menú normal
          return const MenuScreen();
        } else {
          // Si no está autenticado, mostrar login
          return const LoginScreen();
        }
      },
    );
  }
}


 