import 'package:flutter/material.dart';
import '../../Models/Cliente.dart';
import '../../Models/Producto.dart';
import '../../Models/PrecioEspecial.dart';
import '../../Services/PrecioEspecialService.dart';
import '../../Services/Productos_Service/productos_provider.dart';
import '../../Theme/app_theme.dart';
import '../../Theme/dialogs.dart';
import 'editarPreciosEspeciales_screen.dart';

class PreciosEspecialesScreen extends StatefulWidget {
  final Cliente cliente;

  const PreciosEspecialesScreen({Key? key, required this.cliente}) : super(key: key);

  @override
  State<PreciosEspecialesScreen> createState() => _PreciosEspecialesScreenState();
}

class _PreciosEspecialesScreenState extends State<PreciosEspecialesScreen> {
  List<PrecioEspecial> preciosEspeciales = [];
  List<Producto> productos = [];
  bool isLoading = true;
  String errorMessage = '';
  final ProductoProvider productoProvider = ProductoProvider();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final precios = await PrecioEspecialService.getPreciosEspecialesByCliente(widget.cliente.id!);
      final productosData = await productoProvider.obtenerProductos();
      
      setState(() {
        preciosEspeciales = precios;
        productos = productosData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      // Si es un error 401, el usuario necesita autenticarse
      if (e.toString().contains('401')) {
        _showAuthErrorDialog();
      } else {
        setState(() {
          errorMessage = 'Error al cargar los datos: $e';
        });
      }
    }
  }

  void _showAuthErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sesión Expirada'),
          content: const Text('Tu sesión ha expirado. Por favor, inicia sesión nuevamente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pop(); // Volver a la pantalla anterior
                // Aquí podrías navegar al login si tienes una ruta configurada
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _agregarPrecioEspecial() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarPreciosEspecialesScreen(cliente: widget.cliente),
      ),
    );
    _loadData(); // Recargar datos al volver
  }

  Future<void> _editarPrecioEspecial(PrecioEspecial precioEspecial) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarPreciosEspecialesScreen(
          cliente: widget.cliente,
          isIndividualEdit: true,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _eliminarPrecioEspecial(PrecioEspecial precioEspecial) async {
    final confirmed = await AppDialogs.showDeleteConfirmationDialog(
      context: context,
      title: 'Eliminar Precio Especial',
      message: '¿Estás seguro de que quieres eliminar el precio especial para ${precioEspecial.productoNombre}?',
    );

    if (confirmed == true) {
      try {
        await PrecioEspecialService.deletePrecioEspecial(precioEspecial.id!);
        AppTheme.showSnackBar(
          context,
          AppTheme.successSnackBar('Precio especial eliminado exitosamente'),
        );
        _loadData();
      } catch (e) {
        AppTheme.showSnackBar(
          context,
          AppTheme.errorSnackBar('Error al eliminar: $e'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.secondaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header moderno
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Botón de retroceso
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Volver',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.price_change,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Precios Especiales',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              'Cliente: ${widget.cliente.nombre}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Contenido principal
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                      ? _buildErrorState()
                      : preciosEspeciales.isEmpty
                          ? _buildEmptyState()
                          : _buildPreciosList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar datos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.price_change_outlined,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No hay precios especiales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Este cliente no tiene precios especiales configurados',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Usa el botón de gestión desde el detalle del cliente',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreciosList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: preciosEspeciales.length,
      itemBuilder: (context, index) {
        final precioEspecial = preciosEspeciales[index];
        return _buildPrecioCard(precioEspecial, index);
      },
    );
  }

  Widget _buildPrecioCard(PrecioEspecial precioEspecial, int index) {
    final tieneDescuento = precioEspecial.precioEstandar != null && 
                          precioEspecial.precio < precioEspecial.precioEstandar!;
    final porcentajeDescuento = precioEspecial.precioEstandar != null 
        ? ((precioEspecial.precioEstandar! - precioEspecial.precio) / precioEspecial.precioEstandar! * 100)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          children: [
            // Fila principal con información
            Row(
              children: [
                // Icono del producto
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tieneDescuento ? Colors.green.shade50 : AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: tieneDescuento ? Colors.green.shade200 : AppTheme.primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: tieneDescuento ? Colors.green.shade600 : AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Información del producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        precioEspecial.productoNombre ?? 'Producto desconocido',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Precio especial
                      Row(
                        children: [
                          Text(
                            '\$${precioEspecial.precio.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: tieneDescuento ? Colors.green.shade700 : AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tieneDescuento ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ESPECIAL',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Precio estándar y descuento
                      if (precioEspecial.precioEstandar != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Estándar: \$${precioEspecial.precioEstandar!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            if (tieneDescuento) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-${porcentajeDescuento.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            // Fila de acciones (debajo)
            const SizedBox(height: 12),
            Row(
              children: [
                // Indicador visual
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tieneDescuento ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: tieneDescuento ? Colors.green.shade200 : Colors.orange.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tieneDescuento ? Icons.trending_down : Icons.trending_up,
                        color: tieneDescuento ? Colors.green.shade600 : Colors.orange.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tieneDescuento ? 'Descuento' : 'Aumento',
                        style: TextStyle(
                          fontSize: 12,
                          color: tieneDescuento ? Colors.green.shade700 : Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Botones de acción
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón de editar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editarPrecioEspecial(precioEspecial),
                        tooltip: 'Editar precio especial',
                        iconSize: 18,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ),
                    const SizedBox(width: 4),
                    
                    // Botón de eliminar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarPrecioEspecial(precioEspecial),
                        tooltip: 'Eliminar precio especial',
                        iconSize: 18,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}