import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Models/Entrega.dart';
import 'package:tobaco/Models/EstadoEntrega.dart';
import 'package:tobaco/Services/Entregas_Service/entregas_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/map_styles.dart';
import 'package:tobaco/Theme/theme_provider.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Services/Maps/directions_service.dart';
import 'package:tobaco/Screens/Ventas/nuevaVenta_screen.dart';
import 'package:tobaco/Screens/Ventas/detalleVentas_screen.dart';
import 'package:tobaco/Services/Auth_Service/auth_provider.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';

class MapaEntregasScreen extends StatefulWidget {
  const MapaEntregasScreen({super.key});

  @override
  State<MapaEntregasScreen> createState() => _MapaEntregasScreenState();
}

class _MapaEntregasScreenState extends State<MapaEntregasScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _usandoRutaCalles = true; // Iniciar con ruta por calles activada por defecto
  bool _mostrarResumen = false;
  EntregasProvider? _provider;
  bool _yaRefrescado = false;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // Inicializar después de que el frame actual se haya construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarMapa();
      _configurarListener();
    });
  }

  void _configurarListener() {
    final provider = Provider.of<EntregasProvider>(context, listen: false);
    // Escuchar cambios en entregas y posición para actualizar marcadores
    provider.addListener(_onProviderChanged);
  }

  void _onProviderChanged() {
    if (mounted) {
      _actualizarMarcadoresYRutas();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Guardar referencia al provider de forma segura
    final newProvider = Provider.of<EntregasProvider>(context, listen: false);
    
    // Si cambió el provider, remover listener del anterior y agregar al nuevo
    if (_provider != newProvider) {
      _provider?.removeListener(_onProviderChanged);
      _provider = newProvider;
      _provider?.addListener(_onProviderChanged);
    }
  }

  Future<void> _inicializarMapa() async {
    if (!mounted) return;
    
    final provider = Provider.of<EntregasProvider>(context, listen: false);
    
    // Solo inicializar si no se ha hecho ya
    if (!_yaRefrescado) {
      _yaRefrescado = true;
      await provider.inicializar();
    }
    
    if (!mounted) return;
    
    provider.iniciarSeguimientoUbicacion();
    // _usandoRutaCalles ya es true por defecto, no necesitamos setState aquí
    
    // Esperar un frame antes de actualizar marcadores para que la ubicación esté lista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _actualizarMarcadoresYRutas();
      }
    });
  }

  @override
  void dispose() {
    // Cancelar timer pendiente
    _updateTimer?.cancel();
    // Remover listener del provider
    _provider?.removeListener(_onProviderChanged);
    // Detener el seguimiento PRIMERO antes de dispose del widget
    _provider?.detenerSeguimientoUbicacion();
    _mapController?.dispose();
    _yaRefrescado = false; // Resetear para que refresque la próxima vez
    super.dispose();
  }

  void _actualizarMarcadoresYRutas() {
    if (!mounted) return;
    
    // Debounce: cancelar actualización anterior si existe
    _updateTimer?.cancel();
    
    // Programar actualización después de un breve delay para evitar múltiples updates
    _updateTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      
      final provider = Provider.of<EntregasProvider>(context, listen: false);
      
      if (!mounted) return;
      
      setState(() {
        _markers.clear();
        _polylines.clear(); // Siempre limpiar primero para evitar mostrar línea recta

        // Marcador de ubicación actual - Verde (primaryColor)
        if (provider.posicionActual != null) {
          _markers.add(
            Marker(
              markerId: const MarkerId('ubicacion_actual'),
              position: LatLng(
                provider.posicionActual!.latitude,
                provider.posicionActual!.longitude,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), // Verde = primaryColor
              infoWindow: const InfoWindow(
                title: '📍 Tú estás aquí',
              ),
            ),
          );
        }

        // Marcadores de entregas (mostrar todas: pendientes, parciales y completadas)
        for (var entrega in provider.entregas) {
          if (entrega.tieneCoordenadasValidas) {
            _markers.add(_crearMarcadorEntrega(entrega));
          }
        }

        // Crear polylines (rutas)
        if (_usandoRutaCalles) {
          // Cargar ruta por calles de forma asíncrona (la polyline se agregará cuando esté lista)
          // No crear línea recta mientras tanto
          _cargarRutaPorCalles(provider);
        } else {
          _crearRutas(provider);
        }
      });
    });
  }

  Marker _crearMarcadorEntrega(Entrega entrega) {
    double hue;
    String emoji;

    switch (entrega.estado) {
      case EstadoEntrega.entregada:
        hue = BitmapDescriptor.hueGreen; // Verde (success)
        emoji = '✅';
        break;
      case EstadoEntrega.parcial:
        hue = BitmapDescriptor.hueOrange; // Naranja (warning)
        emoji = '⚠️';
        break;
      case EstadoEntrega.noEntregada:
      default:
        hue = BitmapDescriptor.hueAzure; // Azul claro (neutral/pendiente)
        emoji = '📦';
    }

    return Marker(
      markerId: MarkerId('entrega_${entrega.id}'),
      position: LatLng(entrega.latitud!, entrega.longitud!),
      icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      infoWindow: InfoWindow(
        title: '$emoji ${entrega.nombreCliente}',
        snippet: entrega.estado == EstadoEntrega.parcial
            ? '${entrega.direccion}\n⚠️ Parcial'
            : entrega.estado == EstadoEntrega.entregada
                ? '${entrega.direccion}\n✅ Entregada'
                : entrega.direccion,
      ),
      onTap: () => _mostrarDetalleEntrega(entrega),
    );
  }

  void _crearRutas(EntregasProvider provider) {
    if (provider.posicionActual == null) return;

    List<LatLng> puntos = [];
    
    // Punto inicial (ubicación actual)
    puntos.add(LatLng(
      provider.posicionActual!.latitude,
      provider.posicionActual!.longitude,
    ));

    // Agregar entregas pendientes y parciales en orden (no completadas)
    for (var entrega in provider.entregas) {
      if (entrega.tieneCoordenadasValidas && 
          entrega.estado != EstadoEntrega.entregada) {
        puntos.add(LatLng(entrega.latitud!, entrega.longitud!));
      }
    }

    if (puntos.length > 1) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('ruta_entregas'),
          points: puntos,
          color: AppTheme.primaryColor, // Verde = primaryColor ✅
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }
  }

  Future<void> _cargarRutaPorCalles(EntregasProvider provider) async {
    if (provider.posicionActual == null || !mounted) return;
    final origen = LatLng(provider.posicionActual!.latitude, provider.posicionActual!.longitude);

    final pendientes = provider.entregasPendientes.where((e) => e.tieneCoordenadasValidas).toList();
    if (pendientes.isEmpty || !mounted) return;

    final destino = LatLng(pendientes.last.latitud!, pendientes.last.longitud!);
    final waypoints = pendientes.length > 1
        ? pendientes.sublist(0, pendientes.length - 1)
            .map((e) => LatLng(e.latitud!, e.longitud!)).toList()
        : <LatLng>[];

    try {
      final puntos = await DirectionsService.fetchRoute(
        origin: origen,
        waypoints: waypoints,
        destination: destino,
        optimizeWaypoints: true,
        detailed: true,
      );
      if (mounted) {
        setState(() {
          // Limpiar polylines anteriores ANTES de agregar la nueva
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('ruta_calles'),
              points: puntos,
              color: AppTheme.primaryColor,
              width: 7,
            ),
          );
        });
      }
    } catch (e) {
      // Notificar error mínimo y fallback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('No se pudo calcular ruta por calles. Usando línea recta.'),
        );
        // Fallback a líneas rectas
        setState(() {
          _usandoRutaCalles = false;
          _polylines.clear();
        });
        _crearRutas(provider);
      }
    }
  }

  void _mostrarDetalleEntrega(Entrega entrega) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DetalleEntregaSheet(entrega: entrega),
    );
  }

  void _centrarEnUbicacionActual() {
    final provider = Provider.of<EntregasProvider>(context, listen: false);
    if (provider.posicionActual != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            provider.posicionActual!.latitude,
            provider.posicionActual!.longitude,
          ),
          15,
        ),
      );
    }
  }

  void _centrarEnSiguienteEntrega() {
    final provider = Provider.of<EntregasProvider>(context, listen: false);
    final siguiente = provider.siguienteEntrega;
    
    if (siguiente != null && 
        siguiente.tieneCoordenadasValidas && 
        _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(siguiente.latitud!, siguiente.longitud!),
          16,
        ),
      );
      
      // Mostrar detalles automáticamente
      Future.delayed(const Duration(milliseconds: 500), () {
        _mostrarDetalleEntrega(siguiente);
      });
    } else {
      AppTheme.showSnackBar(
        context,
        AppTheme.successSnackBar('No hay más entregas pendientes'),
      );
    }
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void _mostrarTodasLasEntregas() {
    if (!mounted) return;
    final provider = Provider.of<EntregasProvider>(context, listen: false);
    
    if (provider.entregas.isEmpty || _mapController == null || !mounted) return;

    // Calcular los límites del mapa
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    if (provider.posicionActual != null) {
      minLat = provider.posicionActual!.latitude;
      maxLat = provider.posicionActual!.latitude;
      minLng = provider.posicionActual!.longitude;
      maxLng = provider.posicionActual!.longitude;
    }

    for (var entrega in provider.entregas) {
      if (entrega.tieneCoordenadasValidas) {
        minLat = minLat < entrega.latitud! ? minLat : entrega.latitud!;
        maxLat = maxLat > entrega.latitud! ? maxLat : entrega.latitud!;
        minLng = minLng < entrega.longitud! ? minLng : entrega.longitud!;
        maxLng = maxLng > entrega.longitud! ? maxLng : entrega.longitud!;
      }
    }

    if (minLat != double.infinity) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          50, // Padding
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Mapa de Entregas', style: AppTheme.appBarTitleStyle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final provider = Provider.of<EntregasProvider>(
                context,
                listen: false,
              );
              await provider.refrescar();
              _actualizarMarcadoresYRutas();
            },
          ),
          IconButton(
            icon: const Icon(Icons.route),
            onPressed: () async {
              if (!mounted) return;
              final provider = Provider.of<EntregasProvider>(
                context,
                listen: false,
              );
              provider.calcularRutaOptima();
              if (mounted) {
                setState(() {
                  _usandoRutaCalles = true;
                  _polylines.clear();
                });
              }
              await _cargarRutaPorCalles(provider);
              if (mounted) {
                _mostrarTodasLasEntregas();
              }
            },
          ),
        ],
      ),
      body: Consumer<EntregasProvider>(
        builder: (context, provider, child) {
          // El listener ya actualiza los marcadores automáticamente
          // Solo renderizar el UI aquí
          
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.limpiarError();
                      _inicializarMapa();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // Mapa - Sigue el tema de la app (claro/oscuro)
              // Usar key para evitar recreaciones innecesarias
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  // Calcular el estilo del mapa FUERA del callback
                  final isDark = themeProvider.themeMode == ThemeMode.dark ||
                      (themeProvider.themeMode == ThemeMode.system &&
                          MediaQuery.of(context).platformBrightness == Brightness.dark);
                  final mapStyle = isDark ? MapStyles.darkMode : MapStyles.lightMode;
                  
                  return GoogleMap(
                    key: const ValueKey('mapa_entregas'), // Key fijo para evitar recreaciones
                    onMapCreated: (controller) {
                      _mapController = controller;
                      // Aplicar el estilo precalculado solo una vez
                      if (_mapController != null) {
                        _mapController!.setMapStyle(mapStyle);
                        _mostrarTodasLasEntregas();
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target: provider.posicionActual != null
                          ? LatLng(
                              provider.posicionActual!.latitude,
                              provider.posicionActual!.longitude,
                            )
                          : const LatLng(-25.2637, -57.5759), // Asunción por defecto
                      zoom: 13,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    // Evitar rebuilds innecesarios del mapa
                    onTap: (_) {},
                    onLongPress: (_) {},
                  );
                },
              ),

              // Panel superior con información
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _PanelInformacion(),
              ),

              // Botones flotantes - Adaptables al tema
              Positioned(
                right: 16,
                bottom: 100,
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    final isDark = themeProvider.themeMode == ThemeMode.dark ||
                        (themeProvider.themeMode == ThemeMode.system &&
                            MediaQuery.of(context).platformBrightness == Brightness.dark);
                    
                    return Column(
                      children: [
                        // Botón ubicación actual
                        FloatingActionButton(
                          heroTag: 'ubicacion',
                          mini: true,
                          backgroundColor: isDark ? Colors.black : Colors.white,
                          foregroundColor: AppTheme.primaryColor, // Verde
                          onPressed: _centrarEnUbicacionActual,
                          child: const Icon(Icons.my_location),
                        ),
                        const SizedBox(height: 8),
                        // Botón ver todas las entregas
                        FloatingActionButton(
                          heroTag: 'ver_todas',
                          mini: true,
                          backgroundColor: isDark ? Colors.black : Colors.white,
                          foregroundColor: AppTheme.primaryColor, // Verde
                          onPressed: _mostrarTodasLasEntregas,
                          child: const Icon(Icons.zoom_out_map),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          heroTag: 'zoom_in',
                          mini: true,
                          backgroundColor: isDark ? Colors.black : Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          onPressed: _zoomIn,
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          heroTag: 'zoom_out',
                          mini: true,
                          backgroundColor: isDark ? Colors.black : Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          onPressed: _zoomOut,
                          child: const Icon(Icons.remove),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Botón siguiente entrega
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child:               ElevatedButton.icon(
                  onPressed: _centrarEnSiguienteEntrega,
                  icon: const Icon(Icons.navigation),
                  label: Text(
                    provider.siguienteEntrega != null
                        ? 'Siguiente: ${provider.siguienteEntrega!.nombreCliente}'
                        : 'No hay entregas pendientes',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: AppTheme.primaryColor, // Verde = primaryColor
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              // Botón de resumen - Logo verde adaptable al tema
              Positioned(
                top: 16,
                right: 16,
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    final isDark = themeProvider.themeMode == ThemeMode.dark ||
                        (themeProvider.themeMode == ThemeMode.system &&
                            MediaQuery.of(context).platformBrightness == Brightness.dark);
                    
                    return FloatingActionButton(
                      heroTag: 'resumen',
                      mini: true,
                      backgroundColor: isDark ? Colors.black : Colors.white,
                      foregroundColor: AppTheme.primaryColor, // Verde siempre
                      onPressed: () {
                        setState(() {
                          _mostrarResumen = !_mostrarResumen;
                        });
                      },
                      child: const Icon(Icons.assessment),
                    );
                  },
                ),
              ),

              // Panel de resumen
              if (_mostrarResumen)
                Positioned(
                  top: 80,
                  right: 16,
                  child: _PanelResumen(),
                ),
            ],
          );
        },
      ),
    );
  }
}

// Widget para el panel de información superior
class _PanelInformacion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EntregasProvider>(
      builder: (context, provider, child) {
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoChip(
                  icon: Icons.pending_actions,
                  label: 'Pendientes',
                  value: provider.entregasPendientes.length.toString(),
                  color: Colors.amber, // Amarillo ⚠️
                ),
                _InfoChip(
                  icon: Icons.check_circle,
                  label: 'Completadas',
                  value: provider.entregasCompletadas.length.toString(),
                  color: AppTheme.primaryColor, // Verde = primaryColor (success)
                ),
                _InfoChip(
                  icon: Icons.route,
                  label: 'Distancia',
                  value: '${provider.distanciaTotal.toStringAsFixed(1)} km',
                  color: AppTheme.primaryColor, // Verde = primaryColor
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}

// Widget para el panel de resumen
class _PanelResumen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EntregasProvider>(
      builder: (context, provider, child) {
        return Card(
          elevation: 4,
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Resumen del Día',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _ResumenItem(
                  'Total entregas:',
                  provider.entregas.length.toString(),
                ),
                _ResumenItem(
                  'Completadas:',
                  provider.entregasCompletadas.length.toString(),
                  color: AppTheme.primaryColor, // Verde = primaryColor (success)
                ),
                _ResumenItem(
                  'Pendientes:',
                  provider.entregasPendientes.length.toString(),
                  color: Colors.amber, // Amarillo ⚠️
                ),
                _ResumenItem(
                  'Parciales:',
                  provider.entregasParciales.length.toString(),
                  color: Colors.orange, // Naranja (warning) - igual que dialogs
                ),
                const Divider(),
                _ResumenItem(
                  'Distancia total:',
                  '${provider.distanciaTotal.toStringAsFixed(1)} km',
                ),
                _ResumenItem(
                  'Tiempo estimado:',
                  _formatDuration(provider.tiempoEstimado),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    return '${duration.inMinutes}m';
  }
}

class _ResumenItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _ResumenItem(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Sheet de detalles de entrega
class _DetalleEntregaSheet extends StatefulWidget {
  final Entrega entrega;

  const _DetalleEntregaSheet({required this.entrega});

  @override
  State<_DetalleEntregaSheet> createState() => _DetalleEntregaSheetState();
}

class _DetalleEntregaSheetState extends State<_DetalleEntregaSheet> {
  final TextEditingController _notasController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notasController.text = widget.entrega.notas ?? '';
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EntregasProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final usuario = authProvider.currentUser;
    
    // Determinar permisos según rol
    // Admin tiene todos los permisos de Repartidor-Vendedor
    final esAdmin = usuario?.isAdmin == true;
    final puedeCrearVenta = esAdmin || usuario?.esVendedor == true || usuario?.esRepartidorVendedor == true;
    // Vendedor puede marcar recorridos programados como visitados (no puede marcar entregas normales)
    final puedeMarcarEntrega = esAdmin || usuario?.esRepartidor == true || usuario?.esRepartidorVendedor == true;
    final puedeMarcarRecorrido = esAdmin || usuario?.esVendedor == true || usuario?.esRepartidorVendedor == true;
    final esRecorridoProgramado = widget.entrega.ventaId == 0;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.entrega.estado == EstadoEntrega.entregada
                    ? Icons.check_circle
                    : widget.entrega.estado == EstadoEntrega.parcial
                        ? Icons.warning
                        : Icons.pending,
                color: widget.entrega.estado == EstadoEntrega.entregada
                    ? AppTheme.primaryColor // Verde = primaryColor (success)
                    : widget.entrega.estado == EstadoEntrega.parcial
                        ? Colors.orange // Naranja para parcial
                        : Colors.grey, // Gris para pendientes
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.entrega.nombreCliente,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (esRecorridoProgramado)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Recorrido Programado',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (!esRecorridoProgramado && widget.entrega.ventaId > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Venta Asignada',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetalleItem(
            icon: Icons.location_on,
            label: 'Dirección',
            value: widget.entrega.direccion,
          ),
          if (widget.entrega.distanciaDesdeUbicacionActual != null)
            _DetalleItem(
              icon: Icons.directions,
              label: 'Distancia',
              value: '${widget.entrega.distanciaDesdeUbicacionActual!.toStringAsFixed(2)} km',
            ),
          _DetalleItem(
            icon: widget.entrega.estado == EstadoEntrega.parcial 
                ? Icons.warning 
                : widget.entrega.estado == EstadoEntrega.entregada
                    ? Icons.check_circle
                    : Icons.info,
            label: 'Estado',
            value: widget.entrega.estado == EstadoEntrega.parcial
                ? 'Parcial (Pendiente)'
                : widget.entrega.estado.displayName,
          ),
          const SizedBox(height: 16),
          const Text(
            'Notas:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notasController,
            maxLines: 3,
            cursorColor: AppTheme.primaryColor,
            decoration: InputDecoration(
              hintText: 'Agregar notas sobre la entrega...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Botón para ver detalles de venta si es una entrega de venta
          if (!esRecorridoProgramado && widget.entrega.ventaId > 0)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    // Obtener la venta por ID
                    final ventasProvider = Provider.of<VentasProvider>(context, listen: false);
                    final venta = await ventasProvider.obtenerVentaPorId(widget.entrega.ventaId);
                    
                    if (mounted) {
                      Navigator.pop(context); // Cerrar el sheet del mapa primero
                      
                      // Navegar al detalle de venta y esperar a que regrese
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalleVentaScreen(venta: venta),
                        ),
                      );
                      
                      // Al volver, refrescar las entregas para actualizar el estado
                      if (mounted) {
                        final entregasProvider = Provider.of<EntregasProvider>(context, listen: false);
                        await entregasProvider.refrescar();
                      }
                    } else {
                      if (mounted) {
                        AppTheme.showSnackBar(
                          context,
                          AppTheme.errorSnackBar('No se pudo cargar la venta'),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      AppTheme.showSnackBar(
                        context,
                        AppTheme.errorSnackBar('Error al cargar la venta: $e'),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text('Ver Detalles de la Venta'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          // Mostrar botones solo si no está completamente entregada
          // Las entregas parciales pueden seguir siendo editadas
          if (widget.entrega.estado != EstadoEntrega.entregada) ...[
            // Espaciado si hay botón de ver detalles de venta
            if (!esRecorridoProgramado && widget.entrega.ventaId > 0)
              const SizedBox(height: 8),
            // Botón para crear venta desde recorrido (solo Vendedor y Repartidor-Vendedor)
            if (esRecorridoProgramado && puedeCrearVenta)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navegar a crear venta con el cliente pre-seleccionado
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NuevaVentaScreen(
                          clientePreSeleccionado: widget.entrega.cliente,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Crear Venta'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            // Botón para marcar como entregado/visitado
            // - Para entregas de venta: navegar al detalle de la venta (no marcar desde aquí)
            // - Para recorridos programados: marcar como visitado desde el mapa
            Builder(
              builder: (context) {
                // Si es una entrega de venta (no recorrido programado), no mostrar botón de marcar
                // porque debe ir al detalle de la venta
                if (!esRecorridoProgramado && widget.entrega.ventaId > 0) {
                  return const SizedBox.shrink(); // No mostrar botón, ya está el botón de ver detalles
                }
                
                // Solo para recorridos programados
                final puedeMarcarEstaEntrega = esRecorridoProgramado && puedeMarcarRecorrido;
                
                if (!puedeMarcarEstaEntrega) return const SizedBox.shrink();
                
                return Column(
                  children: [
                    if (esRecorridoProgramado && puedeCrearVenta) const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final confirmar = await AppDialogs.showConfirmationDialog(
                            context: context,
                            title: 'Confirmar Visita',
                            message: '¿Confirmar que ya visitaste esta sucursal?',
                            confirmText: 'Confirmar',
                            cancelText: 'Cancelar',
                            icon: Icons.check_circle,
                            iconColor: AppTheme.primaryColor,
                          );

                          if (confirmar == true && mounted) {
                            try {
                              final exito = await provider.marcarComoEntregada(
                                widget.entrega.id!,
                                notas: _notasController.text.isNotEmpty
                                    ? _notasController.text
                                    : null,
                              );

                              if (mounted) {
                                if (exito) {
                                  Navigator.pop(context);
                                  AppTheme.showSnackBar(
                                    context,
                                    AppTheme.successSnackBar(
                                      esRecorridoProgramado
                                          ? 'Visita registrada correctamente'
                                          : 'Entrega marcada como completada'
                                    ),
                                  );
                                } else {
                                  AppTheme.showSnackBar(
                                    context,
                                    AppTheme.errorSnackBar('Error al marcar como completada. Intenta nuevamente.'),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                AppTheme.showSnackBar(
                                  context,
                                  AppTheme.errorSnackBar('Error: $e'),
                                );
                              }
                            }
                          }
                        },
                        icon: Icon(esRecorridoProgramado ? Icons.place : Icons.check),
                        label: Text(esRecorridoProgramado 
                            ? 'Marcar como Visitado' 
                            : 'Marcar como Entregado'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          if (_notasController.text.isNotEmpty &&
              _notasController.text != widget.entrega.notas)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final exito = await provider.agregarNotas(
                    widget.entrega.id!,
                    _notasController.text,
                  );

                  if (exito && mounted) {
                    Navigator.pop(context);
                    AppTheme.showSnackBar(
                      context,
                      AppTheme.successSnackBar('Notas guardadas'),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar Notas'),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetalleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetalleItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

