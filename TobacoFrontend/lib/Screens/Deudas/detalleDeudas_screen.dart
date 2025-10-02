import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tobaco/Models/Cliente.dart';
import 'package:tobaco/Models/Ventas.dart';
import 'package:tobaco/Models/Abono.dart';
import 'package:tobaco/Services/Clientes_Service/clientes_provider.dart';
import 'package:tobaco/Services/Ventas_Service/ventas_provider.dart';
import 'package:tobaco/Services/Abonos_Service/abonos_provider.dart';
import 'package:tobaco/Theme/app_theme.dart';
import 'dart:developer';

class DetalleDeudaScreen extends StatefulWidget {
  final Cliente cliente;

  const DetalleDeudaScreen({super.key, required this.cliente});

  @override
  State<DetalleDeudaScreen> createState() => _DetalleDeudaScreenState();
}

class _DetalleDeudaScreenState extends State<DetalleDeudaScreen> 
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  bool isLoadingVentas = true;
  bool isLoadingAbonos = true;
  bool isLoadingDetalle = true;
  
  List<Ventas> ventasCC = [];
  List<Abono> abonos = [];
  Map<String, dynamic>? detalleDeuda;
  
  String? errorMessage;
  
  // Variables para paginación de ventas
  bool _isLoadingMoreVentas = false;
  bool _hasMoreVentas = true;
  int _currentPageVentas = 1;
  final int _pageSizeVentas = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadDetalleDeuda(),
      _loadVentasCC(),
      _loadAbonos(),
    ]);
  }

  Future<void> _loadDetalleDeuda() async {
    try {
      final clienteProvider = ClienteProvider();
      final detalle = await clienteProvider.obtenerDetalleDeuda(widget.cliente.id!);
      setState(() {
        detalleDeuda = detalle;
        isLoadingDetalle = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar detalle de deuda: $e';
        isLoadingDetalle = false;
      });
      log('Error al cargar detalle de deuda: $e', level: 1000);
    }
  }

  Future<void> _loadVentasCC() async {
    try {
      final ventasProvider = VentasProvider();
      final data = await ventasProvider.obtenerVentasCuentaCorrientePorClienteId(
        widget.cliente.id!, 
        _currentPageVentas, 
        _pageSizeVentas
      );
      
      setState(() {
        ventasCC = List<Ventas>.from(data['pedidos']);
        _hasMoreVentas = data['hasNextPage'];
        isLoadingVentas = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar ventas: $e';
        isLoadingVentas = false;
      });
      log('Error al cargar ventas: $e', level: 1000);
    }
  }

  Future<void> _loadAbonos() async {
    try {
      final abonosProvider = AbonosProvider();
      abonos = await abonosProvider.obtenerAbonosPorClienteId(widget.cliente.id!);
      setState(() {
        isLoadingAbonos = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error al cargar abonos: $e';
        isLoadingAbonos = false;
      });
      log('Error al cargar abonos: $e', level: 1000);
    }
  }

  Future<void> _cargarMasVentas() async {
    if (_isLoadingMoreVentas || !_hasMoreVentas) return;
    
    setState(() {
      _isLoadingMoreVentas = true;
    });

    try {
      final ventasProvider = VentasProvider();
      final data = await ventasProvider.obtenerVentasCuentaCorrientePorClienteId(
        widget.cliente.id!, 
        _currentPageVentas + 1, 
        _pageSizeVentas
      );
      
      setState(() {
        ventasCC.addAll(List<Ventas>.from(data['pedidos']));
        _currentPageVentas++;
        _hasMoreVentas = data['hasNextPage'];
        _isLoadingMoreVentas = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMoreVentas = false;
      });
      log('Error al cargar más ventas: $e', level: 1000);
    }
  }

  String _formatearPrecio(double precio) {
    return precio.toStringAsFixed(2);
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  double _parsearDeuda(String? deuda) {
    if (deuda == null || deuda.isEmpty) return 0.0;
    
    // El backend envía formatos como "1000,000", "2500,250", etc.
    // Vamos a tratar TODOS los casos como si la coma fuera decimal
    // y solo convertir a formato estándar con 2 decimales
    
    if (deuda.contains(',')) {
      List<String> partes = deuda.split(',');
      
      if (partes.length == 2) {
        String parteEntera = partes[0];
        String parteDecimal = partes[1];
        
        // Siempre convertir la coma a punto decimal
        // Si tiene más de 2 dígitos, tomar solo los primeros 2
        String decimalesFinales;
        if (parteDecimal.length >= 2) {
          decimalesFinales = parteDecimal.substring(0, 2);
        } else {
          // Si tiene menos de 2, rellenar con ceros
          decimalesFinales = parteDecimal.padRight(2, '0');
        }
        
        String numeroCorregido = '$parteEntera.$decimalesFinales';
        return double.tryParse(numeroCorregido) ?? 0.0;
      }
    }
    
    // Para otros formatos, usar la lógica normal
    String deudaLimpia = deuda.replaceAll(',', '');
    return double.tryParse(deudaLimpia) ?? 0.0;
  }

  void _mostrarModalSaldarDeuda() {
    final TextEditingController montoController = TextEditingController();
    final TextEditingController notaController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppTheme.minimalAlertDialog(
          title: 'Saldar Deuda',
          content: Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Información del cliente y deuda actual
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.cliente.nombre,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              'Deuda actual: \$${_formatearPrecio(_parsearDeuda(widget.cliente.deuda))}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Campo monto
                TextField(
                  controller: montoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Monto a abonar',
                    hintText: 'Ingrese el monto',
                    prefixText: '\$ ',
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primaryColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Campo nota
                TextField(
                  controller: notaController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Nota (opcional)',
                    hintText: 'Ingrese una nota...',
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primaryColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.grey, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final monto = double.tryParse(montoController.text);
                          final deudaActual = _parsearDeuda(widget.cliente.deuda);
                          
                          if (monto == null || monto <= 0) {
                            AppTheme.showSnackBar(
                              context,
                              AppTheme.warningSnackBar('Ingrese un monto válido'),
                            );
                            return;
                          }
                          
                          if (monto > deudaActual) {
                            AppTheme.showSnackBar(
                              context,
                              AppTheme.warningSnackBar('El monto no puede ser mayor a la deuda actual'),
                            );
                            return;
                          }
                          
                          Navigator.of(context).pop();
                          await _procesarAbono(monto, notaController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Abonar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
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

  Future<void> _procesarAbono(double monto, String nota) async {
    try {
      final abonosProvider = AbonosProvider();
      final abonoCreado = await abonosProvider.saldarDeuda(
        widget.cliente.id!, 
        monto, 
        DateTime.now(), 
        nota.isEmpty ? null : nota
      );
      
      if (abonoCreado != null) {
        // Actualizar la deuda del cliente localmente
        final nuevaDeuda = _parsearDeuda(widget.cliente.deuda) - monto;
        widget.cliente.deuda = nuevaDeuda.toStringAsFixed(2);
        
        // Recargar los datos
        await _loadData();
        
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Abono registrado exitosamente'),
        );
      }
    } catch (e) {
      AppTheme.showSnackBar(
        context,
        AppTheme.errorSnackBar('Error al procesar el abono: $e'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Detalle de Deuda',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      body: isLoadingDetalle
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando detalles...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header con información del cliente
                _buildHeaderSection(),
                
                // Tabs
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long, size: 18),
                            const SizedBox(width: 8),
                            Text('Ventas CC (${ventasCC.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.payment, size: 18),
                            const SizedBox(width: 8),
                            Text('Abonos (${abonos.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Contenido de los tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVentasTab(),
                      _buildAbonosTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarModalSaldarDeuda,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.payment, color: Colors.white),
        label: const Text(
          'Saldar Deuda',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.cliente.nombre,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      'Deuda actual: \$${_formatearPrecio(_parsearDeuda(widget.cliente.deuda))}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.cliente.telefono != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tel: ${widget.cliente.telefono}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Deuda',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVentasTab() {
    if (isLoadingVentas) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (ventasCC.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long,
        title: 'No hay ventas con cuenta corriente',
        subtitle: 'Este cliente no tiene ventas pendientes de pago',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ventasCC.length + (_isLoadingMoreVentas ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == ventasCC.length) {
          return _buildLoadingIndicator();
        }
        
        final venta = ventasCC[index];
        return _buildVentaCard(venta);
      },
    );
  }

  Widget _buildAbonosTab() {
    if (isLoadingAbonos) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (abonos.isEmpty) {
      return _buildEmptyState(
        icon: Icons.payment,
        title: 'No hay abonos registrados',
        subtitle: 'Este cliente aún no ha realizado ningún abono',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: abonos.length,
      itemBuilder: (context, index) {
        final abono = abonos[index];
        return _buildAbonoCard(abono);
      },
    );
  }

  Widget _buildVentaCard(Ventas venta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: Colors.orange.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Venta #${venta.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        _formatearFecha(venta.fecha),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${_formatearPrecio(venta.total)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbonoCard(Abono abono) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.payment,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Abono #${abono.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        _formatearFecha(abono.fecha),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (abono.nota.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          abono.nota,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${_formatearPrecio(_parsearDeuda(abono.monto))}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      ),
    );
  }
}
