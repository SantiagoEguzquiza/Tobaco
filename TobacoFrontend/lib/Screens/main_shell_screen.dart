import 'package:flutter/material.dart';
import 'package:tobaco/Screens/menu_screen.dart';
import 'package:tobaco/Screens/Config/config_screen.dart';
import 'package:tobaco/Theme/app_theme.dart';

/// Shell que muestra el navbar en todas las pantallas.
/// Tab 0 = Inicio (Navigator con MenuScreen y las pantallas que se abren desde él).
/// Tab 1 = Reportes, Tab 2 = Avisos (deshabilitados), Tab 3 = Perfil (Config).
/// Solo se marca la opción del navbar cuando estamos en Menu (Inicio) o en Perfil.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentTabIndex = 0;
  /// 0 = Inicio (Menu), 3 = Perfil, null = ninguna (p. ej. Clientes, Productos, etc.)
  int? _selectedNavIndex = 0;
  final GlobalKey<NavigatorState> _inicioNavigatorKey = GlobalKey<NavigatorState>();
  final RouteObserver<ModalRoute<void>> _routeObserver = RouteObserver<ModalRoute<void>>();

  void _onInicioRouteSelectionChanged(bool isMenuVisible) {
    if (!mounted) return;
    setState(() {
      _selectedNavIndex = isMenuVisible ? 0 : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          Navigator(
            key: _inicioNavigatorKey,
            initialRoute: '/',
            onGenerateRoute: (RouteSettings settings) {
              if (settings.name == '/' || settings.name == null) {
                return MaterialPageRoute<void>(
                  builder: (context) => _NavSelectionNotifier(
                    routeObserver: _routeObserver,
                    onMenuVisible: () => _onInicioRouteSelectionChanged(true),
                    onMenuNotVisible: () => _onInicioRouteSelectionChanged(false),
                    child: const MenuScreen(),
                  ),
                  settings: settings,
                );
              }
              return null;
            },
            observers: [_routeObserver],
          ),
          const Center(
            child: Text(
              'Reportes — Próximamente',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ),
          const Center(
            child: Text(
              'Avisos — Próximamente',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ),
          const ConfigScreen(),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.grid_view_rounded, 'Inicio', enabled: true),
              _navItem(1, Icons.bar_chart_rounded, 'Reportes', enabled: false),
              _navItem(2, Icons.notifications_rounded, 'Avisos', enabled: false),
              _navItem(3, Icons.person_rounded, 'Perfil', enabled: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, {bool enabled = true}) {
    final isSelected = _selectedNavIndex == index;
    final iconColor = !enabled
        ? Colors.white30
        : (isSelected ? Colors.white : Colors.white70);
    final labelColor = !enabled
        ? Colors.white30
        : (isSelected ? AppTheme.primaryColor : Colors.white70);
    final bgColor = isSelected && enabled ? AppTheme.primaryColor : Colors.transparent;

    return InkWell(
      onTap: enabled
          ? () {
              setState(() {
                _currentTabIndex = index;
                _selectedNavIndex = (index == 0 || index == 3) ? index : null;
              });
              if (index == 0) {
                _inicioNavigatorKey.currentState?.popUntil((route) => route.isFirst);
              }
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: labelColor,
                fontWeight: isSelected && enabled ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Notifica al shell cuando la ruta del Menú es visible o está cubierta por otra pantalla.
class _NavSelectionNotifier extends StatefulWidget {
  final RouteObserver<ModalRoute<void>> routeObserver;
  final VoidCallback onMenuVisible;
  final VoidCallback onMenuNotVisible;
  final Widget child;

  const _NavSelectionNotifier({
    required this.routeObserver,
    required this.onMenuVisible,
    required this.onMenuNotVisible,
    required this.child,
  });

  @override
  State<_NavSelectionNotifier> createState() => _NavSelectionNotifierState();
}

class _NavSelectionNotifierState extends State<_NavSelectionNotifier> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      widget.routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    widget.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    widget.onMenuVisible();
  }

  @override
  void didPushNext() {
    widget.onMenuNotVisible();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
