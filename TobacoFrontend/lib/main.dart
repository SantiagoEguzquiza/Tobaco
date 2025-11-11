import 'package:flutter/material.dart';
import 'package:tobaco/Screens/menu_screen.dart';
import 'package:tobaco/Screens/Auth/login_screen.dart';
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
import 'package:tobaco/Services/Sync/simple_sync_service.dart';
import 'package:tobaco/Services/Entregas_Service/entregas_provider.dart';
import 'package:tobaco/Services/Entregas_Service/entregas_service.dart';
import 'package:tobaco/Services/Entregas_Service/ubicacion_service.dart';
import 'package:tobaco/Services/Cache/database_helper.dart';
import 'package:tobaco/Services/Connectivity/connectivity_service.dart';
import 'package:tobaco/Services/RecorridosProgramados_Service/recorridos_programados_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initializeAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Sin pantalla de carga, va directo al resultado
        if (authProvider.isAuthenticated) {
          return const MenuScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}


 