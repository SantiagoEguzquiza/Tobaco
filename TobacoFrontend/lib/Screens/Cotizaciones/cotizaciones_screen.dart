import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tobaco/Services/Cotizaciones_Service/cotizaciones_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'package:tobaco/Theme/dialogs.dart';
import 'package:tobaco/Theme/headers.dart';
import 'package:tobaco/Helpers/api_handler.dart';

class CotizacionesScreen extends StatefulWidget {
  const CotizacionesScreen({super.key});

  @override
  State<CotizacionesScreen> createState() => _CotizacionesScreenState();
}

class _CotizacionesScreenState extends State<CotizacionesScreen> {
  int _selectedGroup = 2; // 1 int, 2 locales, 3 tasas, 0 todos
  int _selectedDays = 7;
  final List<int> _selectedCurrencies = [2222, 2223, 2224, 2225]; // USD, EUR, ARS, BRL

  final Map<int, String> _groups = {
    0: 'Todas',
    1: 'Internacionales',
    2: 'Locales',
    3: 'Tasas',
  };

  final Map<int, String> _currencies = {
    2222: 'USD - Dólar Americano',
    2223: 'EUR - Euro',
    2224: 'ARS - Peso Argentino',
    2225: 'BRL - Real Brasileño',
    2226: 'GBP - Libra Esterlina',
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
        return '🇺🇸'; // Estados Unidos
      case 'BRL':
        return '🇧🇷'; // Brasil
      case 'ARS':
        return '🇦🇷'; // Argentina
      case 'EUR':
        return '🇪🇺'; // Unión Europea
      default:
        return '🏳️'; // Bandera genérica
    }
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? (vm.items.length > 5 
                      ? Colors.green.shade900.withOpacity(0.3) 
                      : Colors.orange.shade900.withOpacity(0.3))
                  : (vm.items.length > 5 ? Colors.green[50] : Colors.orange[50]),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDarkMode
                    ? (vm.items.length > 5 
                        ? Colors.green.shade700 
                        : Colors.orange.shade700)
                    : (vm.items.length > 5 ? Colors.green[200]! : Colors.orange[200]!),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  vm.items.length > 5 ? Icons.check_circle : Icons.info,
                  color: isDarkMode
                      ? (vm.items.length > 5 ? Colors.green.shade400 : Colors.orange.shade400)
                      : (vm.items.length > 5 ? Colors.green[600] : Colors.orange[600]),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vm.items.length > 5 
                        ? 'Mostrando ${vm.items.length} cotizaciones ${_groups[_selectedGroup]?.toLowerCase()} de la API del BCU'
                        : 'Mostrando ${vm.items.length} cotizaciones ${_groups[_selectedGroup]?.toLowerCase()} (datos de ejemplo - API no disponible)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? (vm.items.length > 5 ? Colors.green.shade300 : Colors.orange.shade300)
                          : (vm.items.length > 5 ? Colors.green[700] : Colors.orange[700]),
                    ),
                  ),
                ),
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
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Consultando cotizaciones...',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey,
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
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: vm.items.length,
                                    // Asegurar que el fondo de la lista sea negro en modo oscuro
                                    controller: ScrollController(),
                                    itemBuilder: (_, i) {
                                      final c = vm.items[i];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? const Color(0xFF1A1A1A)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context).brightness == Brightness.dark
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
                                              // Indicador lateral
                                              Container(
                                                width: 4,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor,
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
                                                        Text(
                                                          _getCurrencyFlag(c.codigoIso),
                                                          style: const TextStyle(fontSize: 24),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            c.nombre ?? 'Moneda ${c.moneda}',
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                              color: Theme.of(context).brightness == Brightness.dark
                                                                  ? Colors.white
                                                                  : AppTheme.textColor,
                                                            ),
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
                                                            color: Theme.of(context).brightness == Brightness.dark
                                                                ? Colors.grey.shade400
                                                                : Colors.grey.shade600,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            c.codigoIso!,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Theme.of(context).brightness == Brightness.dark
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
                                                            color: Theme.of(context).brightness == Brightness.dark
                                                                ? Colors.grey.shade400
                                                                : Colors.grey.shade600,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            'Fecha: ${c.fecha}',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Theme.of(context).brightness == Brightness.dark
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
                                                        if (c.tcc != null)
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
                                                        if (c.tcc != null && c.tcv != null)
                                                          const SizedBox(width: 8),
                                                        if (c.tcv != null)
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
