import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Services/Cotizaciones_Service/cotizaciones_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Models/Cotizacion.dart';

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

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
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
                widget.isDarkMode ? Colors.grey.shade900 : Colors.grey.shade400,
                widget.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                widget.isDarkMode ? Colors.grey.shade900 : Colors.grey.shade400,
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

class _CotizacionesScreenState extends State<CotizacionesScreen> {
  // El servicio BROU siempre devuelve estas 4 monedas. No se necesitan filtros
  // por grupo, período, ni selección de monedas: la API REST no los acepta.
  static const List<String> _expectedCurrencies = ['USD', 'BRL', 'ARS', 'EUR'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadCotizaciones();
    });
  }

  Future<void> _loadCotizaciones() async {
    final hoy = DateTime.now();
    await context.read<BcuProvider>().loadCotizaciones(
          monedas: const [],
          desde: hoy,
          hasta: hoy,
          grupo: 0,
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

  Color _getCurrencyAccent(String? codigoIso) {
    switch (codigoIso?.toUpperCase()) {
      case 'USD':
        return Colors.green.shade700;
      case 'EUR':
        return Colors.indigo.shade600;
      case 'ARS':
        return Colors.lightBlue.shade700;
      case 'BRL':
        return Colors.amber.shade800;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getUpdateMessage(DateTime? lastFetchTime) {
    if (lastFetchTime == null) return '';
    final diff = DateTime.now().difference(lastFetchTime);
    if (diff.inMinutes < 1) return 'Actualizado hace menos de 1 min';
    if (diff.inMinutes == 1) return 'Actualizado hace 1 min';
    if (diff.inMinutes < 60) return 'Actualizado hace ${diff.inMinutes} min';
    if (diff.inHours == 1) return 'Actualizado hace 1 h';
    if (diff.inHours < 24) return 'Actualizado hace ${diff.inHours} h';
    return 'Actualizado hace ${diff.inDays} día${diff.inDays == 1 ? "" : "s"}';
  }

  /// Devuelve las 4 monedas esperadas completando con placeholders las faltantes.
  List<Cotizacion> _fillMissingCurrencies(List<Cotizacion> cotizaciones) {
    final byIso = <String, Cotizacion>{};
    for (final c in cotizaciones) {
      final iso = c.codigoIso?.toUpperCase().trim();
      if (iso != null && iso.isNotEmpty) byIso[iso] = c;
    }

    final hoy = DateTime.now();
    final fechaStr =
        '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';

    return _expectedCurrencies.map((iso) {
      return byIso[iso] ??
          Cotizacion(
            fecha: fechaStr,
            codigoIso: iso,
            nombre: _getCurrencyName(iso),
            tcc: null,
            tcv: null,
          );
    }).toList();
  }

  bool _isMissing(Cotizacion c) => c.tcc == null && c.tcv == null;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BcuProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Cotizaciones',
          style: AppTheme.appBarTitleStyle,
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: vm.isLoading ? null : _loadCotizaciones,
            icon: vm.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(isDark, vm.lastFetchTime, vm.items.length),
              const SizedBox(height: 12),
              Expanded(child: _buildBody(vm, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, DateTime? lastFetch, int count) {
    final updateMessage = _getUpdateMessage(lastFetch);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A1A1A), const Color(0xFF2A2A2A)]
              : [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.secondaryColor.withOpacity(0.3),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF404040)
              : AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.currency_exchange_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cotizaciones de monedas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  updateMessage.isNotEmpty
                      ? 'Banco República · $updateMessage'
                      : 'Banco República (BROU) · $count monedas',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BcuProvider vm, bool isDark) {
    if (vm.isLoading && vm.items.isEmpty) {
      return _buildSkeletonLoader(isDark);
    }
    if (vm.error != null && vm.items.isEmpty) {
      return _buildErrorState(vm.error!, isDark);
    }

    final items = _fillMissingCurrencies(vm.items);
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: _loadCotizaciones,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildCotizacionCard(items[i], isDark),
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No se pudieron cargar las cotizaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.red.shade300 : Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCotizaciones,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text(
                'Reintentar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMainButtons),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCotizacionCard(Cotizacion c, bool isDark) {
    final isCompact = AppTheme.isCompactVentasButton(context);
    final missing = _isMissing(c);
    final accent =
        missing ? Colors.grey.shade600 : _getCurrencyAccent(c.codigoIso);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 14 : 16),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(AppTheme.borderRadiusCards),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: isCompact ? 44 : 52,
                height: isCompact ? 44 : 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Opacity(
                  opacity: missing ? 0.4 : 1,
                  child: Text(
                    _getCurrencyFlag(c.codigoIso),
                    style: TextStyle(fontSize: isCompact ? 22 : 26),
                  ),
                ),
              ),
              SizedBox(width: isCompact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      c.nombre ?? _getCurrencyName(c.codigoIso ?? ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isCompact ? 15 : 16,
                        color: missing
                            ? (isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade600)
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    SizedBox(height: isCompact ? 2 : 4),
                    Row(
                      children: [
                        Icon(
                          Icons.currency_exchange_outlined,
                          size: isCompact ? 13 : 14,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            missing
                                ? '${c.codigoIso ?? "-"} · No disponible'
                                : '${c.codigoIso ?? "-"}${c.fecha != null ? " · ${c.fecha}" : ""}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isCompact ? 13 : 14,
                              fontStyle: missing
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: isCompact ? 8 : 12),
              _buildPreciosLateral(c, isDark, isCompact, missing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreciosLateral(
      Cotizacion c, bool isDark, bool isCompact, bool missing) {
    final labelStyle = TextStyle(
      fontSize: isCompact ? 10 : 11,
      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
      fontWeight: FontWeight.w500,
    );
    final valueFontSize = isCompact ? 14.0 : 15.0;
    final missingValue = Text(
      '—',
      style: TextStyle(
        fontSize: valueFontSize,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Compra', style: labelStyle),
            const SizedBox(width: 6),
            missing || c.tcc == null
                ? missingValue
                : Text(
                    '\$${c.tcc!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
          ],
        ),
        SizedBox(height: isCompact ? 2 : 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Venta', style: labelStyle),
            const SizedBox(width: 6),
            missing || c.tcv == null
                ? missingValue
                : Text(
                    '\$${c.tcv!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonLoader(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      itemCount: _expectedCurrencies.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusCards),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                SkeletonBox(
                  width: 52,
                  height: 52,
                  borderRadius: BorderRadius.circular(12),
                  isDarkMode: isDark,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(
                        width: 140,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                        isDarkMode: isDark,
                      ),
                      const SizedBox(height: 8),
                      SkeletonBox(
                        width: 100,
                        height: 12,
                        borderRadius: BorderRadius.circular(4),
                        isDarkMode: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SkeletonBox(
                      width: 90,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                      isDarkMode: isDark,
                    ),
                    const SizedBox(height: 6),
                    SkeletonBox(
                      width: 90,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                      isDarkMode: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
