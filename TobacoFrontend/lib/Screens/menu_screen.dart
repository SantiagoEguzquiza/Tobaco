import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Screens/Clientes/clientes_screen.dart';
import 'package:tobaco/Screens/Cotizaciones/cotizaciones_screen.dart';
import 'package:tobaco/Screens/Deudas/deudas_screen.dart';
import 'package:tobaco/Screens/Ventas/nuevaVenta_screen.dart';
import 'package:tobaco/Screens/Ventas/ventas_screen.dart';
import 'package:tobaco/Screens/Productos/productos_screen.dart';
import 'package:tobaco/Screens/Admin/user_management_screen.dart';
import 'package:tobaco/Screens/Admin/asignar_ventas_screen.dart';
import 'package:tobaco/Screens/Admin/recorridos_programados_screen.dart';
import 'package:tobaco/Screens/Auth/login_screen.dart';
import 'package:tobaco/Screens/Config/config_screen.dart';
import 'package:tobaco/Screens/Entregas/mapa_entregas_screen.dart';
import 'package:tobaco/Screens/Entregas/entregas_screen.dart';
import 'package:tobaco/Services/Auth_Service/auth_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Theme/theme_provider.dart';

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

    final themeProvider = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
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
                      // Toggle tema
                      Align(
                        alignment: Alignment.centerRight,
                        child: Consumer<ThemeProvider>(
                          builder: (context, theme, _) {
                            final isDark = theme.themeMode == ThemeMode.dark;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Switch(
                                  value: isDark,
                                  activeColor: AppTheme.primaryColor,
                                  onChanged: (val) {
                                    theme.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      // Welcome message with user info
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
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
                      
                      // Vendedor o Repartidor-Vendedor: acceso a Recorridos (si no es Admin)
                      if ((authProvider.currentUser?.esRepartidorVendedor == true ||
                           authProvider.currentUser?.esVendedor == true) &&
                          authProvider.currentUser?.isAdmin != true) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const RecorridosProgramadosScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.route, size: 18),
                                  label: const Text('Recorridos'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AsignarVentasScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.assignment_ind, size: 18),
                                  label: const Text('Asignar Ventas'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Admin Section (only for admins)
                      if (authProvider.currentUser?.isAdmin == true) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const UserManagementScreen(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.people, size: 18),
                                      label: const Text('Usuarios'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const AsignarVentasScreen(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.assignment_ind, size: 18),
                                      label: const Text('Asignar Ventas'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const RecorridosProgramadosScreen(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.route, size: 18),
                                      label: const Text('Recorridos'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                          SizedBox(width: spacing),
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
                      SizedBox(height: spacing),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                                      builder: (context) => DeudasScreen()),
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
                                    'Deudas',
                                    style: TextStyle(
                                      fontSize: fontSize,
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
                      SizedBox(height: spacing),
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
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

}