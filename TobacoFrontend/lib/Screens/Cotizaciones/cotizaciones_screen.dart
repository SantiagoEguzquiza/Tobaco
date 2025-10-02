import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Services/Cotizaciones_Service/cotizaciones_provider.dart';
import 'package:tobaco/Models/Cotizacion.dart';
import 'package:tobaco/Theme/app_theme.dart';

class CotizacionesScreen extends StatefulWidget {
  const CotizacionesScreen({super.key});

  @override
  State<CotizacionesScreen> createState() => _CotizacionesScreenState();
}

class _CotizacionesScreenState extends State<CotizacionesScreen> {
  Future<void> _loadCotizaciones(BuildContext context) async {
    final hoy = DateTime.now();
    final desde = hoy.subtract(Duration(days: 7)); // Fixed 7 days

    // Load all currencies (group 0 = todas)
    await context.read<BcuProvider>().loadCotizaciones(
      monedas: [2222, 2223, 2224, 2225], // USD, EUR, ARS, BRL
      desde: desde,
      hasta: hoy,
      grupo: 0, // All groups
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
    final primary = AppTheme.primaryColor; // Use the green color directly
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Cotizaciones',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
              onPressed: vm.isLoading ? null : () => _loadCotizaciones(context),
              tooltip: 'Actualizar cotizaciones',
            ),
          ),
        ],
      ),
      body: vm.isLoading && vm.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando cotizaciones...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : vm.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar cotizaciones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          vm.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
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
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay cotizaciones disponibles',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'La API del BCU no está devolviendo datos.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
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
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: CotizacionesList(
                        allQuotes: vm.items,
                      ),
                    ),
    );
  }
}

class CotizacionesList extends StatelessWidget {
  final List<Cotizacion> allQuotes;
  const CotizacionesList({required this.allQuotes, Key? key}) : super(key: key);

  static const _allowedQuoteNames = <String>[
    'DOLAR USA',
    'EURO',
    'PESO ARGENTINO',
    'REAL'
  ];

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor; // Use the green color directly
    final textTheme = Theme.of(context).textTheme;

    // Filter quotes based on allowed names and take only the first occurrence of each
    final Map<String, Cotizacion> uniqueQuotes = {};

    for (var quote in allQuotes) {
      if (_allowedQuoteNames.contains(quote.nombre) &&
          !uniqueQuotes.containsKey(quote.nombre)) {
        uniqueQuotes[quote.nombre!] = quote;
      }
    }

    final visible = uniqueQuotes.values.toList();

    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron cotizaciones',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las cotizaciones seleccionadas no están disponibles',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => CotizacionCard(
        cotizacion: visible[i],
        primaryColor: primary,
        textTheme: textTheme,
        onTap: () {/* no tocar lógica */},
      ),
    );
  }
}

class CotizacionCard extends StatelessWidget {
  final Cotizacion cotizacion;
  final Color primaryColor;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const CotizacionCard({
    required this.cotizacion,
    required this.primaryColor,
    required this.textTheme,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono de moneda
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.attach_money,
                  color: primaryColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Información de la moneda
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cotizacion.nombre ?? 'Moneda ${cotizacion.moneda}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (cotizacion.codigoIso != null)
                      Text(
                        cotizacion.codigoIso!,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    if (cotizacion.fecha != null)
                      Text(
                        'Fecha: ${cotizacion.fecha}',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),

              // Valores de cotización
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (cotizacion.tcc != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: primaryColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Compra: \$${cotizacion.tcc!.toStringAsFixed(2)}',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  if (cotizacion.tcv != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: primaryColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Venta: \$${cotizacion.tcv!.toStringAsFixed(2)}',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
