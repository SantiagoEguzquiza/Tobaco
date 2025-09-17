import 'package:flutter/material.dart';
import 'package:tobaco/Screens/Clientes/clientes_screen.dart';
import 'package:tobaco/Screens/Cotizaciones/cotizaciones_screen.dart';
import 'package:tobaco/Screens/Deudas/deudas_screen.dart';
import 'package:tobaco/Screens/Ventas/nuevaVenta_screen.dart';
import 'package:tobaco/Screens/Ventas/ventas_screen.dart';
import 'package:tobaco/Screens/Productos/productos_screen.dart';
import 'package:tobaco/Theme/app_theme.dart';

// Note: PruebaBcuPage needs to be imported when available

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 800 : double.infinity,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
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
                                builder: (context) => const PruebaBcuPage(),
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
                          onPressed: () {},
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
