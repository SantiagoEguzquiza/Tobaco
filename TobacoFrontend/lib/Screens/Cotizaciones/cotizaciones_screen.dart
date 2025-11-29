import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Services/Cotizaciones_Service/cotizaciones_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Models/Cotizacion.dart';

// Widget de Shimmer para efecto de carga
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final bool isDarkMode;

  const ShimmerEffect({
    super.key,
    required this.child,
    required this.isDarkMode,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + _controller.value * 2, 0.0),
              end: Alignment(1.0 + _controller.value * 2, 0.0),
              colors: [
                widget.isDarkMode 
                    ? Colors.grey.shade900 
                    : Colors.grey.shade400,
                widget.isDarkMode 
                    ? Colors.grey.shade700 
                    : Colors.grey.shade200,
                widget.isDarkMode 
                    ? Colors.grey.shade900 
                    : Colors.grey.shade400,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

// Widget helper para crear elementos skeleton con shimmer
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isDarkMode;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      isDarkMode: isDarkMode,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class CotizacionesScreen extends StatefulWidget {
  const CotizacionesScreen({super.key});

  @override
  State<CotizacionesScreen> createState() => _CotizacionesScreenState();
}

class _CotizacionesScreenState extends State<CotizacionesScreen> with SingleTickerProviderStateMixin {
  int _selectedGroup = 0; // 1 int, 2 locales, 3 tasas, 0 todos
  int _selectedDays = 7;
  final List<int> _selectedCurrencies = [2222, 2223, 2224, 2225]; // USD, EUR, ARS, BRL

  final Map<int, String> _groups = {
    0: 'Todas',
    1: 'Internacionales',
    2: 'Locales',
    3: 'Tasas',
  };

  Future<void> _loadCotizaciones(BuildContext context) async {
    final hoy = DateTime.now();
    final desde = hoy.subtract(Duration(days: _selectedDays));
    
    await context.read<BcuProvider>().loadCotizaciones(
      monedas: _selectedCurrencies,
      desde: desde,
      hasta: hoy,
      grupo: _selectedGroup,
    );
  }

  String _getCurrencyFlag(String? codigoIso) {
    if (codigoIso == null) return '🏳️';
    
    switch (codigoIso.toUpperCase()) {
      case 'USD':
        return '🇺🇸'; 
      case 'BRL':
        return '🇧🇷'; 
      case 'ARS':
        return '🇦🇷'; 
      case 'EUR':
        return '🇪🇺'; 
      default:
        return '🏳️'; 
    }
  }

  // Formatea el mensaje de actualización basado en el fetch local
  String _getUpdateMessage(DateTime? lastFetchTime) {
    if (lastFetchTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(lastFetchTime);
    
    if (difference.inMinutes < 1) {
      return 'Actualizado hace menos de 1 min';
    } else if (difference.inMinutes == 1) {
      return 'Actualizado hace 1 min';
    } else {
      return 'Actualizado hace ${difference.inMinutes} min';
    }
  }

  String _getCurrencyName(String codigoIso) {
    switch (codigoIso.toUpperCase()) {
      case 'USD':
        return 'Dólar Americano';
      case 'BRL':
        return 'Real Brasileño';
      case 'ARS':
        return 'Peso Argentino';
      case 'EUR':
        return 'Euro';
      default:
        return 'Moneda $codigoIso';
    }
  }

  // Monedas esperadas en orden: USD, BRL, ARS, EUR
  static const List<String> _expectedCurrencies = ['USD', 'BRL', 'ARS', 'EUR'];

  // Obtiene las monedas esperadas según el grupo seleccionado
  List<String> _getExpectedCurrenciesForGroup(int grupo) {
    switch (grupo) {
      case 1: // Internacionales
        return ['USD', 'BRL', 'EUR']; // Solo internacionales (Dólar, Real, Euro)
      case 2: // Locales
        return ['ARS']; // Solo locales (Peso Argentino)
      case 3: // Tasas
        return []; 
      case 0: // Todas
      default:
        return _expectedCurrencies; // Todas las monedas
    }
  }

  // Procesa las cotizaciones y agrega filas para monedas faltantes
  List<Cotizacion> _processCotizacionesWithMissing(List<Cotizacion> cotizaciones, int grupo) {
    // Obtener las monedas esperadas según el grupo
    final monedasEsperadas = _getExpectedCurrenciesForGroup(grupo);
    
    // Si la lista está vacía, crear tarjetas de "no disponible" para las monedas esperadas del grupo
    if (cotizaciones.isEmpty) {
      if (monedasEsperadas.isEmpty) return [];
      
      final hoy = DateTime.now();
      final fechaStr = '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
      
      return monedasEsperadas.map((iso) {
        return Cotizacion(
          fecha: fechaStr,
          codigoIso: iso,
          nombre: _getCurrencyName(iso),
          tcc: null,
          tcv: null,
        );
      }).toList();
    }

    // Agrupar por fecha
    final Map<String, Map<String, Cotizacion>> cotizacionesPorFecha = {};
    
    for (final cot in cotizaciones) {
      final fecha = cot.fecha ?? 'Sin fecha';
      final iso = cot.codigoIso?.toUpperCase().trim() ?? '';
      
      if (!cotizacionesPorFecha.containsKey(fecha)) {
        cotizacionesPorFecha[fecha] = {};
      }
      
      if (iso.isNotEmpty && monedasEsperadas.contains(iso)) {
        cotizacionesPorFecha[fecha]![iso] = cot;
      }
    }

    // Crear lista final con las monedas esperadas del grupo por fecha
    final List<Cotizacion> resultado = [];
    
    // Si no hay monedas esperadas para este grupo, retornar solo las que vinieron
    if (monedasEsperadas.isEmpty) {
      return cotizaciones;
    }
    
    // Ordenar fechas (más recientes primero)
    final fechas = cotizacionesPorFecha.keys.toList()
      ..sort((a, b) {
        try {
          return DateTime.parse(b).compareTo(DateTime.parse(a));
        } catch (e) {
          return b.compareTo(a);
        }
      });

    for (final fecha in fechas) {
      final cotizacionesFecha = cotizacionesPorFecha[fecha]!;
      
      // Para cada moneda esperada del grupo en orden
      for (final iso in monedasEsperadas) {
        if (cotizacionesFecha.containsKey(iso)) {
          // Moneda existe, agregarla
          resultado.add(cotizacionesFecha[iso]!);
        } else {
          // Moneda faltante, crear una cotizacion "vacía" (con tcc y tcv null para indicar que falta)
          resultado.add(Cotizacion(
            fecha: fecha,
            codigoIso: iso,
            nombre: _getCurrencyName(iso),
            tcc: null,
            tcv: null,
          ));
        }
      }
    }

    return resultado;
  }

  // Verifica si una cotización es de una moneda faltante
  bool _isMissingCurrency(Cotizacion cotizacion) {
    return cotizacion.codigoIso != null &&
           _expectedCurrencies.contains(cotizacion.codigoIso!.toUpperCase()) &&
           cotizacion.tcc == null &&
           cotizacion.tcv == null;
  }

  // Construye el widget de cotización (normal o faltante)
  Widget _buildCotizacionCard(Cotizacion c, BuildContext context, bool isDarkMode) {
    final isMissing = _isMissingCurrency(c);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: isMissing ? Border.all(
          color: isDarkMode 
              ? Colors.grey.shade700 
              : Colors.grey.shade300,
          width: 1,
          style: BorderStyle.solid,
        ) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Indicador lateral
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: isMissing 
                    ? Colors.grey.shade600 
                    : AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            
            // Información de la moneda
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                      children: [
                        Opacity(
                          opacity: isMissing ? 0.5 : 1.0,
                          child: Text(
                            _getCurrencyFlag(c.codigoIso),
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.nombre ?? 'Moneda ${c.moneda}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? (isMissing ? Colors.grey.shade500 : Colors.white)
                                : (isMissing ? Colors.grey.shade500 : AppTheme.textColor),
                          ),
                        ),
                      ),
                      if (isMissing)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 12,
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'No disponible',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (c.codigoIso != null)
                    Row(
                      children: [
                        Icon(
                          Icons.currency_exchange_outlined,
                          size: 16,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          c.codigoIso!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  if (c.fecha != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Fecha: ${c.fecha}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (isMissing)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            'Compra: —',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDarkMode
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else if (c.tcc != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            'Compra: \$${c.tcc!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if ((isMissing || c.tcc != null) && (isMissing || c.tcv != null))
                        const SizedBox(width: 8),
                      if (isMissing)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            'Venta: —',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDarkMode
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else if (c.tcv != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            'Venta: \$${c.tcv!.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6, // Mostrar 6 skeletons
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Indicador lateral skeleton
                SkeletonBox(
                  width: 4,
                  height: 60,
                  borderRadius: BorderRadius.circular(2),
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 16),
                // Información skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre de moneda skeleton
                      Row(
                        children: [
                          SkeletonBox(
                            width: 24,
                            height: 24,
                            borderRadius: BorderRadius.circular(4),
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(width: 8),
                          SkeletonBox(
                            width: 150,
                            height: 20,
                            borderRadius: BorderRadius.circular(4),
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Código ISO skeleton
                      SkeletonBox(
                        width: 60,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 6),
                      // Fecha skeleton
                      SkeletonBox(
                        width: 120,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 8),
                      // Precios skeleton
                      Row(
                        children: [
                          SkeletonBox(
                            width: 90,
                            height: 24,
                            borderRadius: BorderRadius.circular(8),
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(width: 8),
                          SkeletonBox(
                            width: 90,
                            height: 24,
                            borderRadius: BorderRadius.circular(8),
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Cargar cotizaciones automáticamente al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCotizaciones(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BcuProvider>();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Cotizaciones de Monedas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: null, // Usar el tema
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Panel de configuración
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: isDarkMode 
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuración de Consulta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Selector de grupo
                Row(
                  children: [
                    Text(
                      'Tipo: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.grey.shade300 : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<int>(
                        value: _selectedGroup,
                        isExpanded: true,
                        dropdownColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        items: _groups.entries.map((entry) {
                          return DropdownMenuItem<int>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGroup = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Selector de días
                Row(
                  children: [
                    Text(
                      'Período: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.grey.shade300 : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<int>(
                        value: _selectedDays,
                        isExpanded: true,
                        dropdownColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 1,
                            child: Text(
                              'Último día',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 7,
                            child: Text(
                              'Últimos 7 días',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 15,
                            child: Text(
                              'Últimos 15 días',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 30,
                            child: Text(
                              'Últimos 30 días',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedDays = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Botón de consulta
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: vm.isLoading ? null : () => _loadCotizaciones(context),
                    icon: vm.isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(vm.isLoading ? 'Consultando...' : 'Consultar Cotizaciones'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Información adicional
        if (vm.items.isNotEmpty)
          if (vm.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.green.shade900.withOpacity(0.3)
                    : Colors.green[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.green.shade700
                      : Colors.green[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: isDarkMode
                            ? Colors.green.shade400
                            : Colors.green[600],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mostrando ${vm.items.length} cotizaciones ${_groups[_selectedGroup]?.toLowerCase()} de la API del BCU',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Colors.green.shade300
                                : Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_getUpdateMessage(vm.lastFetchTime).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(
                        _getUpdateMessage(vm.lastFetchTime),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Resultados
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: vm.isLoading
                        ? _buildSkeletonLoader(isDarkMode)
                        : vm.error != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: Colors.red[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error al cargar cotizaciones',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.red.shade300 : Colors.red[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 32),
                                      child: Text(
                                        vm.error!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () => _loadCotizaciones(context),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Reintentar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : vm.items.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.inbox,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'No hay cotizaciones disponibles',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'La API del BCU no está devolviendo datos.\nIntenta cambiar el período o el tipo de monedas.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () => _loadCotizaciones(context),
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Reintentar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryColor,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Builder(
                                    builder: (context) {
                                      // Procesar las cotizaciones para incluir monedas faltantes según el grupo
                                      final processedItems = _processCotizacionesWithMissing(vm.items, _selectedGroup);
                                      
                                      return ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        itemCount: processedItems.length,
                                        controller: ScrollController(),
                                        itemBuilder: (_, i) {
                                          final c = processedItems[i];
                                          return _buildCotizacionCard(c, context, isDarkMode);
                                        },
                                      );
                                    },
                                  ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
