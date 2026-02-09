import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tobaco/Screens/menu_screen.dart';
import 'package:tobaco/Screens/Auth/login_screen.dart';
import 'package:tobaco/Screens/SuperAdmin/super_admin_menu_screen.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Services/Auth_Service/auth_service.dart';
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
import 'package:tobaco/Helpers/app_lifecycle_observer.dart';

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      locale: const Locale('es', 'ES'),
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

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  final AppLifecycleObserver _lifecycleObserver = AppLifecycleObserver();
  bool _isInitializing = false;
  bool _permisosLoadTriggered = false;
  bool _permisosTimeoutFired = false;

  @override
  void initState() {
    super.initState();
    // Registrar observer del lifecycle
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    // Cuando la sesión se invalida (ej. refresh falla al volver del background),
    // AuthService limpia tokens y llama este callback para que la UI vuelva al login.
    AuthService.onSessionInvalidated = () {
      if (mounted) {
        context.read<ClienteProvider>().clearForNewUser();
        context.read<VentasProvider>().clearForNewUser();
        unawaited(context.read<ProductoProvider>().clearForNewUser());
        context.read<CategoriasProvider>().clearForNewUser();
        context.read<AuthProvider>().clearSession(
          sessionExpiredMessage: 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
        );
      }
    };
    // Initialize authentication state después del primer frame (evita setState durante build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  Future<void> _initializeAuth() async {
    if (_isInitializing || !mounted) return;
    _isInitializing = true;

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.initializeAuth();
      
      // Validar y refrescar token al iniciar (solo si hay token y está autenticado)
      if (mounted && authProvider.isAuthenticated) {
        try {
          await AuthService.validateAndRefreshToken();
        } catch (e) {
          // Si falla el refresh, no hacer nada - el usuario seguirá autenticado
          debugPrint('AuthWrapper: Error al validar token: $e');
        }
        
        // Si el usuario está autenticado y NO es SuperAdmin, cargar permisos
        if (mounted) {
          final user = authProvider.currentUser;
          if (user != null && !user.isSuperAdmin) {
            final permisosProvider = context.read<PermisosProvider>();
            await permisosProvider.loadPermisos(authProvider, forceReload: true);
          }
        }
      }
    } catch (e) {
      debugPrint('AuthWrapper: Error en inicialización: $e');
    } finally {
      if (mounted) {
        _isInitializing = false;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    AuthService.onSessionInvalidated = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PermisosProvider>(
      builder: (context, authProvider, permisosProvider, child) {
        if (authProvider.isInitializing) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (user.isSuperAdmin) {
            return const SuperAdminMenuScreen();
          }

          final esperandoPermisos = permisosProvider.isLoading ||
              (!permisosProvider.isAdmin &&
                  permisosProvider.permisos == null &&
                  !permisosProvider.hasAttemptedLoad);
          final errorPermisos = !permisosProvider.isAdmin &&
              permisosProvider.permisos == null &&
              permisosProvider.hasAttemptedLoad &&
              !permisosProvider.isLoading;

          if (esperandoPermisos) {
            // Disparar carga desde aquí por si login_screen se desmontó (primera vez tras instalar)
            if (!_permisosLoadTriggered) {
              _permisosLoadTriggered = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                context.read<PermisosProvider>().loadPermisos(authProvider, forceReload: true);
              });
            }
            // Si tras 15s sigue cargando, mostrar Reintentar (no menú con permisos por defecto)
            if (!_permisosTimeoutFired) {
              _permisosTimeoutFired = true;
              Future.delayed(const Duration(seconds: 15), () {
                if (!mounted) return;
                context.read<PermisosProvider>().marcarTimeoutPermisos();
              });
            }
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando permisos...', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            );
          }

          if (errorPermisos) {
            final mensaje = permisosProvider.errorMessage ?? 'No se pudieron cargar los permisos.';
            return Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 56, color: Colors.orange.shade700),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar permisos',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          mensaje,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await context.read<PermisosProvider>().reintentarPermisos(authProvider);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          _permisosLoadTriggered = false;
          _permisosTimeoutFired = false;
          return const MenuScreen();
        }

        return const LoginScreen();
      },
    );
  }
}


 