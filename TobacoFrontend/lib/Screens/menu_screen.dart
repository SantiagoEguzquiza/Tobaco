import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Screens/Clientes/clientes_screen.dart';
import 'package:tobaco/Screens/Cotizaciones/cotizaciones_screen.dart';
import 'package:tobaco/Screens/CuentaCorriente/cuenta_corriente_screen.dart';
import 'package:tobaco/Screens/Ventas/nuevaVenta_screen.dart';
import 'package:tobaco/Screens/Ventas/ventas_screen.dart';
import 'package:tobaco/Screens/Productos/productos_screen.dart';
import 'package:tobaco/Screens/Compras/compras_screen.dart';
import 'package:tobaco/Screens/Auth/login_screen.dart';
import 'package:tobaco/Screens/Entregas/mapa_entregas_screen.dart';
import 'package:tobaco/Screens/Entregas/entregas_screen.dart';
import 'package:tobaco/Services/Auth_Service/auth_provider.dart';
import 'package:tobaco/Services/Categoria_Service/categoria_provider.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Services/Permisos_Service/permisos_provider.dart';
import 'package:tobaco/Services/Productos_Service/productos_provider.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';
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

/// ÃƒÂndices del bottom navbar
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  /// Oculto para MVP. Cambiar a true para mostrar de nuevo el mapa de entregas.
  static const bool _showMapaEntregas = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _buildInicioContent(context),
      ),
    );
  }

  Widget _buildInicioContent(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardBackground = isDark ? const Color(0xFF1A1A1A) : colorScheme.surfaceContainerHighest;

    final buttonSize =
        isTablet ? 180.0 : (screenWidth * 0.35).clamp(120.0, 160.0);
    final iconSize = isTablet ? 90.0 : (buttonSize * 0.5).clamp(60.0, 80.0);
    final fontSize = isTablet ? 22.0 : (screenWidth * 0.04).clamp(16.0, 20.0);
    final spacing = isTablet ? 30.0 : 20.0;
    final horizontalPadding = isTablet ? 40.0 : 20.0;

    return Consumer2<AuthProvider, PermisosProvider>(
      builder: (context, authProvider, permisosProvider, child) {
        final user = authProvider.currentUser;
        if (user != null && user.isSuperAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/superadmin');
            }
          });
          return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
        }

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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            permisosProvider.loadPermisos(authProvider, forceReload: true);
          });
        }

        final userName = authProvider.currentUser?.userName ?? 'Usuario';

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 40),
                Text(
                  'Bienvenido,',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hola, $userName',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: spacing + 8),
                // Grid 2x3: Clientes, Productos, Cuenta Corriente, Ventas, Monedas, Ajustes
                if ((permisosProvider.canViewClientes || permisosProvider.isAdmin) ||
                    (permisosProvider.canViewProductos || permisosProvider.isAdmin))
                  Row(
                    children: [
                      if (permisosProvider.canViewClientes || permisosProvider.isAdmin)
                        Expanded(
                          child: _menuCard(
                            context,
                            color: const Color(0xFF3B82F6),
                            icon: Icons.people,
                            label: 'Clientes',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ClientesScreen()),
                            ),
                            iconSize: iconSize,
                            fontSize: fontSize,
                          ),
                        ),
                      if ((permisosProvider.canViewClientes || permisosProvider.isAdmin) &&
                          (permisosProvider.canViewProductos || permisosProvider.isAdmin))
                        SizedBox(width: spacing),
                      if (permisosProvider.canViewProductos || permisosProvider.isAdmin)
                        Expanded(
                          child: _menuCard(
                            context,
                            color: const Color(0xFFF59E0B),
                            icon: Icons.inventory_2,
                            label: 'Productos',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ProductosScreen()),
                            ),
                            iconSize: iconSize,
                            fontSize: fontSize,
                          ),
                        ),
                    ],
                  ),
                if ((permisosProvider.canViewClientes || permisosProvider.isAdmin) ||
                    (permisosProvider.canViewProductos || permisosProvider.isAdmin))
                  SizedBox(height: spacing),
                Row(
                  children: [
                    if (permisosProvider.canViewCuentaCorriente || permisosProvider.isAdmin)
                      Expanded(
                        child: _menuCard(
                          context,
                          color: const Color(0xFFEF4444),
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Cuenta Corriente',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CuentaCorrienteScreen()),
                          ),
                          iconSize: iconSize,
                          fontSize: fontSize,
                        ),
                      ),
                    if ((permisosProvider.canViewCuentaCorriente || permisosProvider.isAdmin) &&
                        (permisosProvider.canViewVentas || permisosProvider.isAdmin))
                      SizedBox(width: spacing),
                    if (permisosProvider.canViewVentas || permisosProvider.isAdmin)
                      Expanded(
                        child: _menuCard(
                          context,
                          color: const Color(0xFF8B5CF6),
                          icon: Icons.receipt_long_rounded,
                          label: 'Ventas',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => VentasScreen()),
                          ),
                          iconSize: iconSize,
                          fontSize: fontSize,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: spacing),
                Row(
                  children: [
                    Expanded(
                      child: _menuCard(
                        context,
                        color: const Color(0xFF0EA5E9),
                        icon: Icons.shopping_cart,
                        label: 'Compras',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ComprasScreen()),
                        ),
                        iconSize: iconSize,
                        fontSize: fontSize,
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: _menuCard(
                        context,
                        color: const Color(0xFF14B8A6),
                        icon: Icons.attach_money,
                        label: 'Monedas',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CotizacionesScreen()),
                        ),
                        iconSize: iconSize,
                        fontSize: fontSize,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                if (permisosProvider.canCreateVentas || permisosProvider.isAdmin) ...[
                  SizedBox(
                    width: isTablet ? 400 : double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF22C55E).withOpacity(0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white24,
                              ),
                              child: const Icon(
                                Icons.add_shopping_cart_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Crear nueva venta',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing),
                ],
                // Resumen mensual
                Consumer<VentasProvider>(
                  builder: (context, ventasProvider, _) {
                    final totalMensual = 0.0;
                    final percentVsAnterior = 0.0;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'RESUMEN MENSUAL',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Icon(Icons.bar_chart_rounded,
                                  color: colorScheme.onSurfaceVariant.withOpacity(0.7), size: 20),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '\$${(totalMensual).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.trending_up_rounded,
                                  size: 16, color: Colors.green.shade400),
                              const SizedBox(width: 4),
                              Text(
                                '${percentVsAnterior >= 0 ? '+' : ''}${percentVsAnterior.toStringAsFixed(1)}% vs mes anterior',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: spacing * 2),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double iconSize,
    required double fontSize,
  }) {
    final theme = Theme.of(context);
    final cardBg = theme.brightness == Brightness.dark
        ? const Color(0xFF1A1A1A)
        : theme.colorScheme.surfaceContainerHighest;
    final labelColor = theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: iconSize * 0.45,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
